using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Enums;
using MyDent.Model.Exceptions;
using MyDent.Model.Responses;
using MyDent.Services.Database;
using MyDent.Services.Policies;

namespace MyDent.Services
{
    // Hybrid recommender — see recommender-dokumentacija.md for the written explanation this
    // implementation must match.
    //
    // Three legs, applied in order:
    //  1. Content-based: other active services in categories the patient has already visited,
    //     that they haven't had yet.
    //  2. Time-based: categories the patient visited whose RecommendedRecallMonths has elapsed
    //     since their last visit there (routine checkup, orthodontic control, ...).
    //  3. Popularity: fallback for patients with no completed-appointment history at all, and
    //     also used to top up the list if legs 1+2 come back empty for a returning patient.
    public class RecommenderService : IRecommenderService
    {
        private const int MaxRecommendations = 10;

        private readonly MyDentDbContext _dbContext;
        private readonly IAuthenticatedUserAccessor _userAccessor;

        public RecommenderService(MyDentDbContext dbContext, IAuthenticatedUserAccessor userAccessor)
        {
            _dbContext = dbContext;
            _userAccessor = userAccessor;
        }

        public async Task<List<RecommendationResponse>> GetRecommendationsAsync(int? patientId)
        {
            var targetPatientId = ResolveTargetPatientId(patientId);

            var completedAppointments = await _dbContext.Appointments
                .Include(a => a.DentalService).ThenInclude(s => s.ServiceCategory)
                .Where(a => a.PatientId == targetPatientId && a.Status == AppointmentStatus.Completed)
                .ToListAsync();

            if (completedAppointments.Count == 0)
            {
                // New patient, nothing to base content/time recommendations on.
                return await GetPopularServicesAsync(excludeServiceIds: new HashSet<int>());
            }

            var visitedServiceIds = completedAppointments.Select(a => a.DentalServiceId).ToHashSet();
            var visitedCategoryIds = completedAppointments.Select(a => a.DentalService.ServiceCategoryId).ToHashSet();

            var recommendations = new List<RecommendationResponse>();
            recommendations.AddRange(await GetContentBasedAsync(visitedCategoryIds, visitedServiceIds));
            recommendations.AddRange(GetTimeBased(completedAppointments));

            if (recommendations.Count == 0)
            {
                // Returning patient, but nothing left to suggest from their own history — fall
                // back to what's popular clinic-wide among services they haven't had yet.
                recommendations.AddRange(await GetPopularServicesAsync(excludeServiceIds: visitedServiceIds));
            }

            return recommendations
                .GroupBy(r => r.DentalServiceId)
                .Select(g => g.First())
                .Take(MaxRecommendations)
                .ToList();
        }

        private int ResolveTargetPatientId(int? patientId)
        {
            if (_userAccessor.IsInRole("Admin") && patientId.HasValue)
            {
                return patientId.Value;
            }

            return _userAccessor.GetUserId()
                ?? throw new ClientException("Authenticated user could not be resolved.");
        }

        private async Task<List<RecommendationResponse>> GetContentBasedAsync(HashSet<int> visitedCategoryIds, HashSet<int> visitedServiceIds)
        {
            var candidates = await _dbContext.DentalServices
                .Include(s => s.ServiceCategory)
                .Where(s => s.IsActive && visitedCategoryIds.Contains(s.ServiceCategoryId) && !visitedServiceIds.Contains(s.Id))
                .ToListAsync();

            return candidates
                .Select(s => Map(s, RecommendationReason.ContentBased,
                    $"Na osnovu vaše prethodne posjete za \"{s.ServiceCategory.Name}\""))
                .ToList();
        }

        private List<RecommendationResponse> GetTimeBased(List<Appointment> completedAppointments)
        {
            var result = new List<RecommendationResponse>();

            var dueCategoryIds = completedAppointments
                .Where(a => a.DentalService.ServiceCategory.RecommendedRecallMonths.HasValue)
                .GroupBy(a => a.DentalService.ServiceCategoryId)
                .Select(g => new
                {
                    CategoryId = g.Key,
                    RecommendedRecallMonths = g.First().DentalService.ServiceCategory.RecommendedRecallMonths!.Value,
                    LastVisit = g.Max(a => a.ScheduledAt)
                })
                .Where(x => RecallPolicy.IsOverdue(x.LastVisit, x.RecommendedRecallMonths));

            foreach (var due in dueCategoryIds)
            {
                var service = completedAppointments
                    .First(a => a.DentalService.ServiceCategoryId == due.CategoryId)
                    .DentalService;

                if (!service.IsActive)
                {
                    continue;
                }

                result.Add(Map(service, RecommendationReason.TimeBased,
                    $"Vrijeme je za kontrolu — prošlo je {due.RecommendedRecallMonths}+ mjeseci od zadnje posjete za \"{service.ServiceCategory.Name}\""));
            }

            return result;
        }

        private async Task<List<RecommendationResponse>> GetPopularServicesAsync(HashSet<int> excludeServiceIds)
        {
            var popularityOrder = await _dbContext.Appointments
                .Where(a => a.Status != AppointmentStatus.Cancelled)
                .GroupBy(a => a.DentalServiceId)
                .Select(g => new { DentalServiceId = g.Key, BookingCount = g.Count() })
                .OrderByDescending(x => x.BookingCount)
                .ToListAsync();

            var orderedIds = popularityOrder
                .Select(x => x.DentalServiceId)
                .Where(id => !excludeServiceIds.Contains(id))
                .Take(MaxRecommendations)
                .ToList();

            var services = await _dbContext.DentalServices
                .Include(s => s.ServiceCategory)
                .Where(s => s.IsActive && orderedIds.Contains(s.Id))
                .ToListAsync();

            // Re-apply popularity order — the query above doesn't preserve it.
            return orderedIds
                .Select(id => services.FirstOrDefault(s => s.Id == id))
                .Where(s => s != null)
                .Select(s => Map(s!, RecommendationReason.Popularity, "Popularna usluga u klinici"))
                .ToList();
        }

        private static RecommendationResponse Map(DentalService service, RecommendationReason reason, string reasonDetail)
        {
            return new RecommendationResponse
            {
                DentalServiceId = service.Id,
                DentalServiceName = service.Name,
                Price = service.Price,
                DurationMinutes = service.DurationMinutes,
                ServiceCategoryId = service.ServiceCategoryId,
                ServiceCategoryName = service.ServiceCategory.Name,
                Reason = reason,
                ReasonDetail = reasonDetail
            };
        }
    }
}
