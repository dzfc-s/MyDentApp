using FluentValidation;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Enums;
using MyDent.Model.Requests;
using MyDent.Services.Database;

namespace MyDent.Services.Validators
{
    public class ReviewInsertValidator : AbstractValidator<ReviewInsertRequest>
    {
        public ReviewInsertValidator(MyDentDbContext dbContext, IAuthenticatedUserAccessor userAccessor)
        {
            RuleFor(x => x.Comment)
                .MaximumLength(1000).WithMessage("Comment cannot exceed 1000 characters.");

            RuleFor(x => x.Rating)
                .InclusiveBetween(1, 5).WithMessage("Rating must be between 1 and 5.");


            RuleFor(x => x.AppointmentId)
                .GreaterThan(0).WithMessage("AppointmentId is required.")
                .MustAsync(async (id, cancellation) => await dbContext.Appointments.AnyAsync(c => c.Id == id, cancellation))
                .WithMessage(x => $"Appointment with id {x.AppointmentId} does not exist.")
                .MustAsync(async (id, cancellation) => await dbContext.Appointments.AnyAsync(d => d.Id == id && d.Status == AppointmentStatus.Completed, cancellation))
                .WithMessage(x => $"Appointment with id {x.AppointmentId} is not completed.")
                 .MustAsync(async (id, cancellation) => await dbContext.Appointments.AnyAsync(d => d.Id == id && d.PatientId == userAccessor.GetUserId(), cancellation))
                 .WithMessage("You can only create a review for your own completed appointments.");

            RuleFor(x => x).CustomAsync(async (request, context, cancellation) =>
            {
                var existingReview = await dbContext.Reviews.AsNoTracking()
                    .FirstOrDefaultAsync(r => r.AppointmentId == request.AppointmentId, cancellation);
                if (existingReview != null)
                {
                    context.AddFailure("AppointmentId", $"A review for appointment id {request.AppointmentId} already exists.");
                }
            });
        }
    }
}
