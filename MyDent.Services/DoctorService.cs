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
    public class DoctorService
        : BaseCRUDService<Doctor, DoctorResponse, DoctorSearch, DoctorInsertRequest, DoctorUpdateRequest>,
          IDoctorService
    {
        private readonly IAppointmentService _appointmentService;
        private readonly IAuthenticatedUserAccessor _userAccessor;

        public DoctorService(
            MyDentDbContext dbContext,
            MapsterMapper.IMapper mapper,
            FluentValidation.IValidator<DoctorInsertRequest> insertValidator,
            FluentValidation.IValidator<DoctorUpdateRequest> updateValidator,
            IAppointmentService appointmentService,
            IAuthenticatedUserAccessor userAccessor)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _appointmentService = appointmentService;
            _userAccessor = userAccessor;
        }

        // GetByIdAsync in the base class looks up by id only, with no ApplyFilters pass — so
        // without this, a patient who knows/guesses an inactive doctor's id could still fetch
        // (and book against) a doctor that's no longer offered, since the "hide inactive" rule
        // below only applies to list search.
        public override async Task<DoctorResponse> GetByIdAsync(int id)
        {
            var response = await base.GetByIdAsync(id);
            if (!response.IsActive && !_userAccessor.IsInRole("Admin"))
            {
                throw new KeyNotFoundException($"Doctor with id {id} not found.");
            }
            return response;
        }

        // Deactivating a doctor (soft-delete, see BaseCRUDService.DeleteAsync) shouldn't leave
        // patients with a future appointment nobody will show up for — cancel those first, each
        // through the normal CancelAsync flow so the existing audit trail + notification (+ paid
        // flag) all fire exactly as they would for a manual cancellation.
        public override async Task DeleteAsync(int id)
        {
            var now = DateTime.UtcNow;
            var affectedAppointmentIds = await _dbContext.Appointments
                .Where(a => a.DoctorId == id
                    && (a.Status == AppointmentStatus.Pending || a.Status == AppointmentStatus.Confirmed)
                    && a.ScheduledAt > now)
                .Select(a => a.Id)
                .ToListAsync();

            // One atomic unit: either every affected appointment gets cancelled AND the doctor
            // ends up deactivated, or none of it does — a crash partway through used to be able to
            // leave the doctor still active with some (but not all) future appointments cancelled.
            await using var transaction = await _dbContext.Database.BeginTransactionAsync();

            foreach (var appointmentId in affectedAppointmentIds)
            {
                await _appointmentService.CancelAsync(appointmentId, new AppointmentCancelRequest
                {
                    CancellationReason = "Doktor više nije dostupan. Molimo zakažite termin kod drugog doktora."
                });
            }

            await base.DeleteAsync(id);

            await transaction.CommitAsync();
        }

        protected override Task<IQueryable<Doctor>> IncludeRelatedEntitiesAsync(DoctorSearch? search, IQueryable<Doctor> query = null!)
        {
            if (search?.ServiceCategoryId.HasValue == true)
            {
                query = query.Include(d => d.DoctorSpecialties);
            }

            return base.IncludeRelatedEntitiesAsync(search, query);
        }

        protected override IQueryable<Doctor> ApplyFilters(IQueryable<Doctor> query, DoctorSearch? search)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    query = query.Where(d =>
                        EF.Functions.Like(d.FirstName, $"%{search.Name}%") ||
                        EF.Functions.Like(d.LastName, $"%{search.Name}%"));
                }

                if (search.IsActive.HasValue)
                {
                    query = query.Where(d => d.IsActive == search.IsActive.Value);
                }

                if (search.ServiceCategoryId.HasValue)
                {
                    query = query.Where(d => d.DoctorSpecialties.Any(ds => ds.ServiceCategoryId == search.ServiceCategoryId.Value));
                }
            }

            // Only Admin/Staff should ever see inactive/archived doctors in the public catalog —
            // a patient omitting IsActive (or explicitly passing IsActive=false) must not be able
            // to browse or book against a doctor who's no longer offered.
            if (!_userAccessor.IsInRole("Admin"))
            {
                query = query.Where(d => d.IsActive);
            }

            return query;
        }
    }
}
