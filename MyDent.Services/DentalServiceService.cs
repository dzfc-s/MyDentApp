using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Enums;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services.Database;

namespace MyDent.Services
{
    public class DentalServiceService
        : BaseCRUDService<DentalService, DentalServiceResponse, DentalServiceSearch, DentalServiceInsertRequest, DentalServiceUpdateRequest>,
          IDentalServiceService
    {
        private readonly IAppointmentService _appointmentService;
        private readonly IAuthenticatedUserAccessor _userAccessor;

        public DentalServiceService(
            MyDentDbContext dbContext,
            MapsterMapper.IMapper mapper,
            FluentValidation.IValidator<DentalServiceInsertRequest> insertValidator,
            FluentValidation.IValidator<DentalServiceUpdateRequest> updateValidator,
            IAppointmentService appointmentService,
            IAuthenticatedUserAccessor userAccessor)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _appointmentService = appointmentService;
            _userAccessor = userAccessor;
        }

        // GetByIdAsync in the base class looks up by id only, with no ApplyFilters pass — so
        // without this, a patient who knows/guesses an inactive service's id could still fetch
        // (and book) a service that's no longer offered, since the "hide inactive" rule below
        // only applies to list search.
        public override async Task<DentalServiceResponse> GetByIdAsync(int id)
        {
            var response = await base.GetByIdAsync(id);
            if (!response.IsActive && !_userAccessor.IsInRole("Admin"))
            {
                throw new KeyNotFoundException($"DentalService with id {id} not found.");
            }
            return response;
        }

        // Same reasoning as DoctorService.DeleteAsync — deactivating a service shouldn't leave a
        // future appointment booked for something that's no longer offered.
        public override async Task DeleteAsync(int id)
        {
            // Same reasoning as DoctorService.DeleteAsync: cancelling the affected appointments
            // and deactivating the service must land together, not partially.
            await using var transaction = await _dbContext.Database.BeginTransactionAsync();
            await CancelFutureAppointmentsAsync(id);
            await base.DeleteAsync(id);
            await transaction.CommitAsync();
        }

        // DeleteAsync (soft-delete via the "Obriši" action) already cancelled future appointments,
        // but a service can just as easily be deactivated by unchecking "Aktivna" on the edit form
        // and saving — that goes through UpdateAsync instead, which had no equivalent cleanup, so a
        // service could be turned inactive while patients still had upcoming bookings for it.
        public override async Task<DentalServiceResponse> UpdateAsync(int id, DentalServiceUpdateRequest request)
        {
            if (!request.IsActive)
            {
                await CancelFutureAppointmentsAsync(id);
            }

            return await base.UpdateAsync(id, request);
        }

        private async Task CancelFutureAppointmentsAsync(int dentalServiceId)
        {
            var now = DateTime.UtcNow;
            var affectedAppointmentIds = await _dbContext.Appointments
                .Where(a => a.DentalServiceId == dentalServiceId
                    && (a.Status == AppointmentStatus.Pending || a.Status == AppointmentStatus.Confirmed)
                    && a.ScheduledAt > now)
                .Select(a => a.Id)
                .ToListAsync();

            foreach (var appointmentId in affectedAppointmentIds)
            {
                await _appointmentService.CancelAsync(appointmentId, new AppointmentCancelRequest
                {
                    CancellationReason = "Usluga više nije dostupna. Molimo zakažite drugi termin."
                });
            }
        }

        protected override Task<IQueryable<DentalService>> IncludeRelatedEntitiesAsync(DentalServiceSearch? search, IQueryable<DentalService> query = null!)
        {
            query = query.Include(s => s.ServiceCategory);
            return base.IncludeRelatedEntitiesAsync(search, query);
        }

        protected override IQueryable<DentalService> ApplyFilters(IQueryable<DentalService> query, DentalServiceSearch? search)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    query = query.Where(s => EF.Functions.Like(s.Name, $"%{search.Name}%"));
                }

                if (search.ServiceCategoryId.HasValue)
                {
                    query = query.Where(s => s.ServiceCategoryId == search.ServiceCategoryId.Value);
                }

                if (search.IsActive.HasValue)
                {
                    query = query.Where(s => s.IsActive == search.IsActive.Value);
                }
            }

            // Only Admin/Staff should ever see inactive/archived services in the public catalog —
            // a patient omitting IsActive (or explicitly passing IsActive=false) must not be able
            // to browse or book against a service that's no longer offered.
            if (!_userAccessor.IsInRole("Admin"))
            {
                query = query.Where(s => s.IsActive);
            }

            return query;
        }
    }
}
