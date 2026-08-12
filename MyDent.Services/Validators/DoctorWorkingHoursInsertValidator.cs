using System;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Requests;
using MyDent.Services.Database;

namespace MyDent.Services.Validators
{
    public class DoctorWorkingHoursInsertValidator : AbstractValidator<DoctorWorkingHoursInsertRequest>
    {
        public DoctorWorkingHoursInsertValidator(MyDentDbContext dbContext)
        {
            RuleFor(x => x.DoctorId)
                .GreaterThan(0).WithMessage("DoctorId is required.")
                .MustAsync(async (id, cancellation) => await dbContext.Doctors.AnyAsync(d => d.Id == id, cancellation))
                .WithMessage(x => $"Doctor with id {x.DoctorId} does not exist.");

            RuleFor(x => x.DayOfWeek)
                .IsInEnum().WithMessage("DayOfWeek must be a valid day of the week (0-6).")
                .NotEqual(DayOfWeek.Sunday).WithMessage("The clinic is closed on Sundays.");

            RuleFor(x => x.EndTime)
                .GreaterThan(x => x.StartTime)
                .WithMessage("EndTime must be after StartTime.");

            RuleFor(x => x).CustomAsync(async (request, context, cancellation) =>
            {
                var conflict = await dbContext.DoctorWorkingHours.AsNoTracking().FirstOrDefaultAsync(w =>
                    w.DoctorId == request.DoctorId &&
                    w.DayOfWeek == request.DayOfWeek &&
                    w.StartTime < request.EndTime &&
                    w.EndTime > request.StartTime,
                    cancellation);

                if (conflict != null)
                {
                    context.AddFailure("StartTime",
                        $"This time range overlaps with an existing working-hours entry (id {conflict.Id}: {conflict.StartTime}-{conflict.EndTime}).");
                }
            });
        }
    }
}
