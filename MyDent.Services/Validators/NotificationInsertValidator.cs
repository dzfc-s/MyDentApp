using FluentValidation;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Requests;
using MyDent.Services.Database;

namespace MyDent.Services.Validators
{
    public class NotificationInsertValidator : AbstractValidator<NotificationInsertRequest>
    {
        public NotificationInsertValidator(MyDentDbContext dbContext)
        {
            RuleFor(x => x.UserId)
                .GreaterThan(0).WithMessage("UserId is required.")
                .MustAsync(async (id, cancellation) => await dbContext.Users.AnyAsync(u => u.Id == id, cancellation))
                .WithMessage(x => $"User with id {x.UserId} does not exist.");

            RuleFor(x => x.Title)
                .NotEmpty().WithMessage("Title is required.")
                .MaximumLength(200).WithMessage("Title cannot exceed 200 characters.");

            RuleFor(x => x.Message)
                .NotEmpty().WithMessage("Message is required.")
                .MaximumLength(1000).WithMessage("Message cannot exceed 1000 characters.");

            RuleFor(x => x.Type)
                .IsInEnum().WithMessage("Type must be a valid notification type.");

            RuleFor(x => x.AppointmentId)
                .GreaterThan(0).WithMessage("AppointmentId must be greater than 0.")
                .When(x => x.AppointmentId.HasValue);

            RuleFor(x => x.ServiceCategoryId)
                .GreaterThan(0).WithMessage("ServiceCategoryId must be greater than 0.")
                .MustAsync(async (id, cancellation) => await dbContext.ServiceCategories.AnyAsync(c => c.Id == id, cancellation))
                .WithMessage(x => $"ServiceCategory with id {x.ServiceCategoryId} does not exist.")
                .When(x => x.ServiceCategoryId.HasValue);

            // If a notification references an appointment, it only makes sense that it's
            // addressed to that appointment's own patient — catches copy-paste mistakes like
            // notifying the wrong user about someone else's booking.
            RuleFor(x => x).CustomAsync(async (request, context, cancellation) =>
            {
                if (!request.AppointmentId.HasValue)
                {
                    return;
                }

                var appointment = await dbContext.Appointments.AsNoTracking()
                    .FirstOrDefaultAsync(a => a.Id == request.AppointmentId.Value, cancellation);

                if (appointment == null)
                {
                    context.AddFailure("AppointmentId", $"Appointment with id {request.AppointmentId} does not exist.");
                    return;
                }

                if (appointment.PatientId != request.UserId)
                {
                    context.AddFailure("AppointmentId", "This appointment does not belong to the given user.");
                }
            });
        }
    }
}
