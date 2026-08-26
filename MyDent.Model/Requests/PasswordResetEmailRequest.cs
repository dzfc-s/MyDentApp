namespace MyDent.Model.Requests
{
    // Published to RabbitMQ by the API, consumed by MyDent.NotificationWorker which actually
    // sends the email via SMTP — keeps the SMTP round-trip off the API's request/response path,
    // same reasoning as NotificationInsertRequest for in-app notifications.
    public class PasswordResetEmailRequest
    {
        public string ToEmail { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string Code { get; set; } = string.Empty;
    }
}
