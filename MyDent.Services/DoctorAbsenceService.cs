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
    public class DoctorAbsenceService
        : BaseCRUDService<DoctorAbsence, DoctorAbsenceResponse, DoctorAbsenceSearch, DoctorAbsenceInsertRequest, DoctorAbsenceUpdateRequest>,
          IDoctorAbsenceService
    {
        private readonly IAppointmentService _appointmentService;

        public DoctorAbsenceService(
            MyDentDbContext dbContext,
            MapsterMapper.IMapper mapper,
            FluentValidation.IValidator<DoctorAbsenceInsertRequest> insertValidator,
            FluentValidation.IValidator<DoctorAbsenceUpdateRequest> updateValidator,
            IAppointmentService appointmentService)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _appointmentService = appointmentService;
        }

        // A doctor absence blocks bookings for the range going forward, but it doesn't retroactively
        // touch anything already booked in that range — without this, a doctor could be marked absent
        // over dates where patients still have a Pending/Confirmed appointment sitting on the calendar.
        public override async Task<DoctorAbsenceResponse> InsertAsync(DoctorAbsenceInsertRequest request)
        {
            var result = await base.InsertAsync(request);
            await CancelConflictingAppointmentsAsync(request.DoctorId, request.StartDate, request.EndDate);
            return result;
        }

        public override async Task<DoctorAbsenceResponse> UpdateAsync(int id, DoctorAbsenceUpdateRequest request)
        {
            var doctorId = await _dbContext.DoctorAbsences
                .Where(a => a.Id == id)
                .Select(a => a.DoctorId)
                .FirstAsync();

            var result = await base.UpdateAsync(id, request);
            await CancelConflictingAppointmentsAsync(doctorId, request.StartDate, request.EndDate);
            return result;
        }

        private async Task CancelConflictingAppointmentsAsync(int doctorId, DateOnly startDate, DateOnly endDate)
        {
            var rangeStart = startDate.ToDateTime(TimeOnly.MinValue);
            var rangeEnd = endDate.ToDateTime(TimeOnly.MaxValue);

            var affectedAppointmentIds = await _dbContext.Appointments
                .Where(a => a.DoctorId == doctorId
                    && (a.Status == AppointmentStatus.Pending || a.Status == AppointmentStatus.Confirmed)
                    && a.ScheduledAt >= rangeStart && a.ScheduledAt <= rangeEnd)
                .Select(a => a.Id)
                .ToListAsync();

            foreach (var appointmentId in affectedAppointmentIds)
            {
                await _appointmentService.CancelAsync(appointmentId, new AppointmentCancelRequest
                {
                    CancellationReason = "Doktor je odsutan u ovom terminu. Molimo zakažite drugi termin."
                });
            }
        }

        protected override Task<IQueryable<DoctorAbsence>> IncludeRelatedEntitiesAsync(DoctorAbsenceSearch? search, IQueryable<DoctorAbsence> query = null!)
        {
            query = query.Include(a => a.Doctor);
            return base.IncludeRelatedEntitiesAsync(search, query);
        }

        protected override IQueryable<DoctorAbsence> ApplyFilters(IQueryable<DoctorAbsence> query, DoctorAbsenceSearch? search)
        {
            if (search != null)
            {
                if (search.DoctorId.HasValue)
                {
                    query = query.Where(a => a.DoctorId == search.DoctorId.Value);
                }
            }

            return query;
        }
    }
}
