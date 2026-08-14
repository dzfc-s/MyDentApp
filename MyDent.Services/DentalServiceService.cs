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

        public DentalServiceService(
            MyDentDbContext dbContext,
            MapsterMapper.IMapper mapper,
            FluentValidation.IValidator<DentalServiceInsertRequest> insertValidator,
            FluentValidation.IValidator<DentalServiceUpdateRequest> updateValidator,
            IAppointmentService appointmentService)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _appointmentService = appointmentService;
        }

        // Same reasoning as DoctorService.DeleteAsync — deactivating a service shouldn't leave a
        // future appointment booked for something that's no longer offered.
        public override async Task DeleteAsync(int id)
        {
            var now = DateTime.UtcNow;
            var affectedAppointmentIds = await _dbContext.Appointments
                .Where(a => a.DentalServiceId == id
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

            await base.DeleteAsync(id);
        }

        protected override Task<IQueryable<DentalService>> IncludeRelatedEntitiesAsync(DentalServiceSearch? search, IQueryable<DentalService> query = null!)
        {
            query = query.Include(s => s.ServiceCategory);
            return base.IncludeRelatedEntitiesAsync(search, query);
        }

        protected override IEnumerable<DentalService> ApplyFilters(IEnumerable<DentalService> query, DentalServiceSearch? search)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    query = query.Where(s => s.Name.Contains(search.Name, StringComparison.OrdinalIgnoreCase));
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

            return query;
        }
    }
}
