using FluentValidation;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Requests;
using MyDent.Services.Database;

namespace MyDent.Services.Validators
{
    public class DoctorWorkingHoursUpdateValidator : AbstractValidator<DoctorWorkingHoursUpdateRequest>
    {
        public DoctorWorkingHoursUpdateValidator(MyDentDbContext dbContext)
        {
            RuleFor(x => x.EndTime)
                .GreaterThan(x => x.StartTime)
                .WithMessage("EndTime must be after StartTime.");

            // DoctorId/DayOfWeek aren't editable (see DoctorWorkingHoursUpdateRequest), so the
            // overlap check has to look up the current row's doctor/day via the route id, which
            // BaseCRUDService.UpdateAsync passes through RootContextData.
            RuleFor(x => x).CustomAsync(async (request, context, cancellation) =>
            {
                var id = context.RootContextData.TryGetValue("Id", out var idObj) ? (int)idObj : 0;
                var current = await dbContext.DoctorWorkingHours.AsNoTracking().FirstOrDefaultAsync(w => w.Id == id, cancellation);
                if (current == null)
                {
                    return;
                }

                var conflict = await dbContext.DoctorWorkingHours.AsNoTracking().FirstOrDefaultAsync(w =>
                    w.Id != id &&
                    w.DoctorId == current.DoctorId &&
                    w.DayOfWeek == current.DayOfWeek &&
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
