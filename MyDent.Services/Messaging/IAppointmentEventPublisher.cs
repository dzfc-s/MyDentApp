using MyDent.Model.Requests;

namespace MyDent.Services.Messaging
{
    // Decouples "an appointment event happened" from "a notification got written" — AppointmentService
    // publishes here, MyDent.NotificationWorker (a separate process/container) consumes and does the
    // actual write. Keeps notification creation off the request/response path for Confirm/Cancel.
    public interface IAppointmentEventPublisher
    {
        Task PublishNotificationAsync(NotificationInsertRequest notification, CancellationToken cancellationToken = default);
    }
}
