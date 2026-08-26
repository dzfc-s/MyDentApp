namespace MyDent.Services.Messaging
{
    // Bound from the "RabbitMQ" configuration section, which ultimately comes from .env
    // (RabbitMQ__HostName etc.) — never hardcoded.
    public class RabbitMqOptions
    {
        public string HostName { get; set; } = "localhost";
        public int Port { get; set; } = 5672;
        public string UserName { get; set; } = "guest";
        public string Password { get; set; } = "guest";
        public string NotificationsQueueName { get; set; } = "appointment-notifications";
        public string PasswordResetEmailQueueName { get; set; } = "password-reset-emails";
    }
}
