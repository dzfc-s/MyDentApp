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

        public DoctorService(
            MyDentDbContext dbContext,
            MapsterMapper.IMapper mapper,
            FluentValidation.IValidator<DoctorInsertRequest> insertValidator,
            FluentValidation.IValidator<DoctorUpdateRequest> updateValidator,
            IAppointmentService appointmentService)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _appointmentService = appointmentService;
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

            foreach (var appointmentId in affectedAppointmentIds)
            {
                await _appointmentService.CancelAsync(appointmentId, new AppointmentCancelRequest
                {
                    CancellationReason = "Doktor više nije dostupan. Molimo zakažite termin kod drugog doktora."
                });
            }

            await base.DeleteAsync(id);
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

            return query;
        }
    }
}
