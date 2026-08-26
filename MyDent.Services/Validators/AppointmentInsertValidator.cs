using System;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Enums;
using MyDent.Model.Requests;
using MyDent.Services;
using MyDent.Services.Database;

namespace MyDent.Services.Validators
{
    public class AppointmentInsertValidator : AbstractValidator<AppointmentInsertRequest>
    {
        public AppointmentInsertValidator(MyDentDbContext dbContext, IAuthenticatedUserAccessor userAccessor)
        {
            RuleFor(x => x.PatientId)
                .GreaterThan(0).WithMessage("PatientId is required.")
                .MustAsync(async (id, cancellation) => await dbContext.Users.AnyAsync(u => u.Id == id, cancellation))
                .WithMessage(x => $"User with id {x.PatientId} does not exist.")
                // Admins/staff can book on behalf of any patient; a patient booking through
                // their own account can only book for themselves (prevents IDOR — booking an
                // appointment in someone else's name by guessing/incrementing their user id).
                .Must(id => userAccessor.IsInRole("Admin") || id == userAccessor.GetUserId())
                .WithMessage("You can only book appointments for yourself.");

            RuleFor(x => x.DoctorId)
                .GreaterThan(0).WithMessage("DoctorId is required.")
                .MustAsync(async (id, cancellation) => await dbContext.Doctors.AnyAsync(d => d.Id == id, cancellation))
                .WithMessage(x => $"Doctor with id {x.DoctorId} does not exist.")
                .MustAsync(async (id, cancellation) => await dbContext.Doctors.AnyAsync(d => d.Id == id && d.IsActive, cancellation))
                .WithMessage(x => $"Doctor with id {x.DoctorId} is not active.");

            RuleFor(x => x.DentalServiceId)
                .GreaterThan(0).WithMessage("DentalServiceId is required.")
                .MustAsync(async (id, cancellation) => await dbContext.DentalServices.AnyAsync(s => s.Id == id, cancellation))
                .WithMessage(x => $"DentalService with id {x.DentalServiceId} does not exist.")
                .MustAsync(async (id, cancellation) => await dbContext.DentalServices.AnyAsync(s => s.Id == id && s.IsActive, cancellation))
                .WithMessage(x => $"DentalService with id {x.DentalServiceId} is not active.");

            RuleFor(x => x.ScheduledAt)
                .GreaterThan(_ => ClinicClock.Now)
                .WithMessage("ScheduledAt must be in the future.");

            // Availability checks (working hours / absence / overlap) only make sense once the
            // doctor and service are confirmed valid+active by the rules above, so this re-fetches
            // them defensively and bails out silently on failure rather than duplicating an error.
            RuleFor(x => x).CustomAsync(async (request, context, cancellation) =>
            {
                var doctor = await dbContext.Doctors.AsNoTracking()
                    .FirstOrDefaultAsync(d => d.Id == request.DoctorId && d.IsActive, cancellation);
                var dentalService = await dbContext.DentalServices.AsNoTracking()
                    .FirstOrDefaultAsync(s => s.Id == request.DentalServiceId && s.IsActive, cancellation);

                if (doctor == null || dentalService == null)
                {
                    return;
                }

                var hasMatchingSpecialty = await dbContext.DoctorSpecialties.AnyAsync(ds =>
                    ds.DoctorId == request.DoctorId && ds.ServiceCategoryId == dentalService.ServiceCategoryId,
                    cancellation);

                if (!hasMatchingSpecialty)
                {
                    context.AddFailure("DoctorId", "The selected doctor is not specialized in this service's category.");
                    return;
                }

                var dayOfWeek = request.ScheduledAt.DayOfWeek;
                var startTime = request.ScheduledAt.TimeOfDay;
                var endTime = startTime + TimeSpan.FromMinutes(dentalService.DurationMinutes);

                var isWithinWorkingHours = await dbContext.DoctorWorkingHours.AnyAsync(w =>
                    w.DoctorId == request.DoctorId &&
                    w.DayOfWeek == dayOfWeek &&
                    w.StartTime <= startTime &&
                    w.EndTime >= endTime,
                    cancellation);

                if (!isWithinWorkingHours)
                {
                    context.AddFailure("ScheduledAt", "The doctor does not work at the requested day/time.");
                    return;
                }

                var scheduledDate = DateOnly.FromDateTime(request.ScheduledAt);
                var isOnAbsence = await dbContext.DoctorAbsences.AnyAsync(a =>
                    a.DoctorId == request.DoctorId &&
                    a.StartDate <= scheduledDate &&
                    a.EndDate >= scheduledDate,
                    cancellation);

                if (isOnAbsence)
                {
                    context.AddFailure("ScheduledAt", "The doctor is on absence on the requested date.");
                    return;
                }

                var newEnd = request.ScheduledAt.AddMinutes(dentalService.DurationMinutes);
                var doctorConflict = await dbContext.Appointments.AsNoTracking().FirstOrDefaultAsync(a =>
                    a.DoctorId == request.DoctorId &&
                    a.Status != AppointmentStatus.Cancelled &&
                    a.ScheduledAt < newEnd &&
                    a.ScheduledAt.AddMinutes(a.DurationMinutes) > request.ScheduledAt,
                    cancellation);

                if (doctorConflict != null)
                {
                    context.AddFailure("ScheduledAt",
                        $"This time overlaps with an existing appointment (id {doctorConflict.Id} at {doctorConflict.ScheduledAt}) for the same doctor.");
                    return;
                }

                // A patient can't be in two places at once, even with two different doctors —
                // this scopes the same overlap check by PatientId instead of DoctorId.
                var patientConflict = await dbContext.Appointments.AsNoTracking().FirstOrDefaultAsync(a =>
                    a.PatientId == request.PatientId &&
                    a.Status != AppointmentStatus.Cancelled &&
                    a.ScheduledAt < newEnd &&
                    a.ScheduledAt.AddMinutes(a.DurationMinutes) > request.ScheduledAt,
                    cancellation);

                if (patientConflict != null)
                {
                    context.AddFailure("ScheduledAt",
                        $"You already have an overlapping appointment (id {patientConflict.Id} at {patientConflict.ScheduledAt}) with a different doctor.");
                }
            });
        }
    }
}
