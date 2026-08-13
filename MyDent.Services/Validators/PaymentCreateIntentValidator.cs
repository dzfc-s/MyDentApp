using FluentValidation;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Enums;
using MyDent.Model.Requests;
using MyDent.Services.Database;

namespace MyDent.Services.Validators
{
    public class PaymentCreateIntentValidator : AbstractValidator<PaymentCreateIntentRequest>
    {
        public PaymentCreateIntentValidator(MyDentDbContext dbContext, IAuthenticatedUserAccessor userAccessor)
        {
            RuleFor(x => x.AppointmentId)
                .GreaterThan(0).WithMessage("AppointmentId is required.")
                .MustAsync(async (id, cancellation) => await dbContext.Appointments.AnyAsync(a => a.Id == id, cancellation))
                .WithMessage(x => $"Appointment with id {x.AppointmentId} does not exist.")
                // Same ownership rule as booking/cancelling: a patient can only pay for their own
                // appointment, Admin can act on any of them (e.g. recording a desk payment).
                .MustAsync(async (id, cancellation) => userAccessor.IsInRole("Admin")
                    || await dbContext.Appointments.AnyAsync(a => a.Id == id && a.PatientId == userAccessor.GetUserId(), cancellation))
                .WithMessage("You can only pay for your own appointments.");

            RuleFor(x => x).CustomAsync(async (request, context, cancellation) =>
            {
                var appointment = await dbContext.Appointments.AsNoTracking()
                    .FirstOrDefaultAsync(a => a.Id == request.AppointmentId, cancellation);

                if (appointment == null)
                {
                    return;
                }

                if (appointment.Status == AppointmentStatus.Cancelled)
                {
                    context.AddFailure("AppointmentId", "Cannot pay for a cancelled appointment.");
                    return;
                }

                var existingPayment = await dbContext.Payments
                    .AnyAsync(p => p.AppointmentId == request.AppointmentId, cancellation);

                if (existingPayment)
                {
                    context.AddFailure("AppointmentId", $"A payment for appointment id {request.AppointmentId} already exists.");
                }
            });
        }
    }
}
