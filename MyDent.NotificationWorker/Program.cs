using DotNetEnv;
using Microsoft.EntityFrameworkCore;
using MyDent.NotificationWorker;
using MyDent.Services.Database;
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
    NotificationsQueueName = builder.Configuration["RabbitMQ:NotificationsQueueName"] ?? "appointment-notifications"
};
builder.Services.AddSingleton(rabbitMqOptions);

// Consumes appointment-confirmed/cancelled events published by the API over RabbitMQ.
builder.Services.AddHostedService<NotificationConsumerService>();
// Polls for due appointment reminders / recurring-checkup reminders — relocated here (instead
// of a BackgroundService inside MyDent.WebAPI) so it runs in this separate worker process.
builder.Services.AddHostedService<ReminderSchedulerService>();

var host = builder.Build();
host.Run();
