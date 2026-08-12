using FluentValidation;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Requests;
using MyDent.Services.Database;

namespace MyDent.Services.Validators
{
    public class DoctorAbsenceUpdateValidator : AbstractValidator<DoctorAbsenceUpdateRequest>
    {
        public DoctorAbsenceUpdateValidator(MyDentDbContext dbContext)
        {
            RuleFor(x => x.Reason)
                .NotEmpty().WithMessage("Reason is required.")
                .MaximumLength(300).WithMessage("Reason cannot exceed 300 characters.");

            RuleFor(x => x.EndDate)
                .GreaterThanOrEqualTo(x => x.StartDate)
                .WithMessage("EndDate must be on or after StartDate.");

            // DoctorId isn't editable (see DoctorAbsenceUpdateRequest), so the overlap check has
            // to look up the current row's doctor via the route id, which BaseCRUDService.UpdateAsync
            // passes through RootContextData.
            RuleFor(x => x).CustomAsync(async (request, context, cancellation) =>
            {
                var id = context.RootContextData.TryGetValue("Id", out var idObj) ? (int)idObj : 0;
                var current = await dbContext.DoctorAbsences.AsNoTracking().FirstOrDefaultAsync(a => a.Id == id, cancellation);
                if (current == null)
                {
                    return;
                }

                var conflict = await dbContext.DoctorAbsences.AsNoTracking().FirstOrDefaultAsync(a =>
                    a.Id != id &&
                    a.DoctorId == current.DoctorId &&
                    a.StartDate <= request.EndDate &&
                    a.EndDate >= request.StartDate,
                    cancellation);

                if (conflict != null)
                {
                    context.AddFailure("StartDate",
                        $"This date range overlaps with an existing absence (id {conflict.Id}: {conflict.StartDate:yyyy-MM-dd} to {conflict.EndDate:yyyy-MM-dd}, reason: \"{conflict.Reason}\").");
                }
            });
        }
    }
}
