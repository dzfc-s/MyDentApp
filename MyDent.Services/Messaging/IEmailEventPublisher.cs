using MyDent.Model.Requests;

namespace MyDent.Services.Messaging
{
    // Same split as IAppointmentEventPublisher — the API publishes "send this email", a separate
    // worker process/container does the actual SMTP round-trip.
    public interface IEmailEventPublisher
    {
        Task PublishPasswordResetEmailAsync(PasswordResetEmailRequest request, CancellationToken cancellationToken = default);
    }
}
