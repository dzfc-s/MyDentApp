using DotNetEnv;
using Microsoft.EntityFrameworkCore;
using MyDent.NotificationWorker;
using MyDent.Services.Database;
using MyDent.Services.Email;
using MyDent.Services.Messaging;

// Same .env loading approach as MyDent.WebAPI — works whether run via `dotnet run`, from the
// repo root, or (in the container) via env vars set directly by docker-compose.
Env.TraversePath().Load();

var builder = Host.CreateApplicationBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<MyDentDbContext>(options => options.UseSqlServer(connectionString));

var rabbitMqOptions = new RabbitMqOptions
{
    HostName = builder.Configuration["RabbitMQ:HostName"] ?? "localhost",
    Port = int.Parse(builder.Configuration["RabbitMQ:Port"] ?? "5672"),
    UserName = builder.Configuration["RabbitMQ:UserName"] ?? "guest",
    Password = builder.Configuration["RabbitMQ:Password"] ?? "guest",
    NotificationsQueueName = builder.Configuration["RabbitMQ:NotificationsQueueName"] ?? "appointment-notifications",
    PasswordResetEmailQueueName = builder.Configuration["RabbitMQ:PasswordResetEmailQueueName"] ?? "password-reset-emails"
};
builder.Services.AddSingleton(rabbitMqOptions);

var smtpOptions = new SmtpOptions
{
    Host = builder.Configuration["Smtp:Host"] ?? string.Empty,
    Port = int.Parse(builder.Configuration["Smtp:Port"] ?? "587"),
    Username = builder.Configuration["Smtp:Username"] ?? string.Empty,
    Password = builder.Configuration["Smtp:Password"] ?? string.Empty,
    UseSsl = bool.Parse(builder.Configuration["Smtp:UseSsl"] ?? "true"),
    FromAddress = builder.Configuration["Smtp:FromAddress"] ?? string.Empty,
    FromName = builder.Configuration["Smtp:FromName"] ?? "MyDent"
};
builder.Services.AddSingleton(smtpOptions);

// Consumes appointment-confirmed/cancelled events published by the API over RabbitMQ.
builder.Services.AddHostedService<NotificationConsumerService>();
// Polls for due appointment reminders / recurring-checkup reminders — relocated here (instead
// of a BackgroundService inside MyDent.WebAPI) so it runs in this separate worker process.
builder.Services.AddHostedService<ReminderSchedulerService>();
// Sends password-reset emails via SMTP.
builder.Services.AddHostedService<PasswordResetEmailConsumerService>();

var host = builder.Build();
host.Run();
