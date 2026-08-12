using FluentValidation;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Requests;
using MyDent.Services.Database;

namespace MyDent.Services.Validators
{
    public class DoctorAbsenceInsertValidator : AbstractValidator<DoctorAbsenceInsertRequest>
    {
        public DoctorAbsenceInsertValidator(MyDentDbContext dbContext)
        {
            RuleFor(x => x.DoctorId)
                .GreaterThan(0).WithMessage("DoctorId is required.")
                .MustAsync(async (id, cancellation) => await dbContext.Doctors.AnyAsync(d => d.Id == id, cancellation))
                .WithMessage(x => $"Doctor with id {x.DoctorId} does not exist.");

            RuleFor(x => x.Reason)
                .NotEmpty().WithMessage("Reason is required.")
                .MaximumLength(300).WithMessage("Reason cannot exceed 300 characters.");

            RuleFor(x => x.EndDate)
                .GreaterThanOrEqualTo(x => x.StartDate)
                .WithMessage("EndDate must be on or after StartDate.");

            RuleFor(x => x).CustomAsync(async (request, context, cancellation) =>
            {
                var conflict = await dbContext.DoctorAbsences.AsNoTracking().FirstOrDefaultAsync(a =>
                    a.DoctorId == request.DoctorId &&
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
