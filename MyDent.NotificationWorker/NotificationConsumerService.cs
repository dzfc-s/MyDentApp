using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Requests;
using MyDent.Services.Database;
using MyDent.Services.Messaging;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace MyDent.NotificationWorker;

// Consumes the queue MyDent.WebAPI's RabbitMqAppointmentEventPublisher publishes to (appointment
// confirmed/cancelled) and turns each message into a Notification row. This is the "real async
// work" side of the microservice split — the actual DB write happens here, off the API's
// request/response path, in a physically separate process/container.
public class NotificationConsumerService : BackgroundService
{
    private readonly RabbitMqOptions _options;
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<NotificationConsumerService> _logger;

    private IConnection? _connection;
    private IChannel? _channel;

    public NotificationConsumerService(RabbitMqOptions options, IServiceScopeFactory scopeFactory, ILogger<NotificationConsumerService> logger)
    {
        _options = options;
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // One connection/channel for the lifetime of the worker — set up once here, never
        // reopened per message.
        _connection = await RabbitMqConnectionHelper.ConnectWithRetryAsync(_options, _logger, stoppingToken);
        _channel = await _connection.CreateChannelAsync(cancellationToken: stoppingToken);

        await _channel.QueueDeclareAsync(
            queue: _options.NotificationsQueueName,
            durable: true,
            exclusive: false,
            autoDelete: false,
            cancellationToken: stoppingToken);

        // One message at a time — a slow/failing DB write shouldn't let a backlog of
        // unacknowledged deliveries pile up on this consumer.
        await _channel.BasicQosAsync(prefetchSize: 0, prefetchCount: 1, global: false, cancellationToken: stoppingToken);

        var consumer = new AsyncEventingBasicConsumer(_channel);
        consumer.ReceivedAsync += async (_, ea) =>
        {
            try
            {
                // Deserialize once, outside the retry loop below — a malformed payload fails
                // identically every attempt, so retrying it would just burn the whole backoff
                // cycle on a guaranteed failure.
                var notification = JsonSerializer.Deserialize<NotificationInsertRequest>(ea.Body.Span)
                    ?? throw new InvalidOperationException("Message body deserialized to null.");

                await PersistWithRetryAsync(notification, stoppingToken);

                await _channel.BasicAckAsync(ea.DeliveryTag, multiple: false, cancellationToken: stoppingToken);
            }
            catch (Exception ex)
            {
                // Don't requeue: a message that still fails after the retries below (e.g.
                // malformed payload) would just fail the same way forever and block every
                // message behind it. Log and drop rather than poison-loop the queue.
                _logger.LogError(ex, "Failed to process notification message; dropping it.");
                await _channel.BasicNackAsync(ea.DeliveryTag, multiple: false, requeue: false, cancellationToken: stoppingToken);
            }
        };

        await _channel.BasicConsumeAsync(_options.NotificationsQueueName, autoAck: false, consumer: consumer, cancellationToken: stoppingToken);

        // BasicConsumeAsync returns once the consumer is registered — keep the service alive
        // until shutdown is requested.
        await Task.Delay(Timeout.Infinite, stoppingToken).ContinueWith(_ => { }, TaskScheduler.Default);
    }

    // 1s -> 2s -> 4s -> 8s, same backoff as PasswordResetEmailConsumerService.SendWithRetryAsync
    // — a transient DB hiccup (brief connectivity blip, deadlock) is worth retrying instead of
    // dropping the notification on the first failure.
    private async Task PersistWithRetryAsync(NotificationInsertRequest notification, CancellationToken cancellationToken)
    {
        var delay = TimeSpan.FromSeconds(1);
        const int maxAttempts = 4;

        for (var attempt = 1; attempt <= maxAttempts; attempt++)
        {
            try
            {
                await PersistAsync(notification, cancellationToken);
                return;
            }
            catch (Exception ex) when (attempt < maxAttempts)
            {
                _logger.LogWarning(ex, "Failed to persist notification for user {UserId} (attempt {Attempt}/{Max}), retrying in {DelaySeconds}s.",
                    notification.UserId, attempt, maxAttempts, delay.TotalSeconds);
                await Task.Delay(delay, cancellationToken);
                delay += delay;
            }
        }

        // Final attempt — let a failure here propagate to the caller's catch block.
        await PersistAsync(notification, cancellationToken);
    }

    private async Task PersistAsync(NotificationInsertRequest notification, CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<MyDentDbContext>();

        // Message already went through validation on the API side before being published (an
        // internal event, not raw user input) — no need to re-run FluentValidation here, just
        // persist it.
        dbContext.Notifications.Add(new Notification
        {
            UserId = notification.UserId,
            Title = notification.Title,
            Message = notification.Message,
            Type = notification.Type,
            AppointmentId = notification.AppointmentId,
            ServiceCategoryId = notification.ServiceCategoryId,
            CreatedAt = DateTime.UtcNow
        });
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        if (_channel != null)
        {
            await _channel.CloseAsync(cancellationToken: cancellationToken);
        }

        if (_connection != null)
        {
            await _connection.CloseAsync(cancellationToken: cancellationToken);
        }

        await base.StopAsync(cancellationToken);
    }
}
