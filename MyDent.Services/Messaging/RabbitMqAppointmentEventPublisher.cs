using System.Text.Json;
using Microsoft.Extensions.Logging;
using MyDent.Model.Requests;
using RabbitMQ.Client;

namespace MyDent.Services.Messaging
{
    // Registered as a Singleton in Program.cs — one connection/channel for the whole app
    // lifetime, opened lazily on first publish rather than blocking API startup if RabbitMQ
    // isn't up yet, and reused (never reconnected) for every subsequent publish.
    public class RabbitMqAppointmentEventPublisher : IAppointmentEventPublisher, IAsyncDisposable
    {
        private readonly RabbitMqOptions _options;
        private readonly ILogger<RabbitMqAppointmentEventPublisher> _logger;
        private readonly SemaphoreSlim _connectLock = new(1, 1);
        private IConnection? _connection;
        private IChannel? _channel;

        public RabbitMqAppointmentEventPublisher(RabbitMqOptions options, ILogger<RabbitMqAppointmentEventPublisher> logger)
        {
            _options = options;
            _logger = logger;
        }

        public async Task PublishNotificationAsync(NotificationInsertRequest notification, CancellationToken cancellationToken = default)
        {
            var channel = await GetChannelAsync(cancellationToken);
            var body = JsonSerializer.SerializeToUtf8Bytes(notification);

            await channel.BasicPublishAsync(
                exchange: string.Empty,
                routingKey: _options.NotificationsQueueName,
                mandatory: true,
                basicProperties: new BasicProperties { Persistent = true },
                body: body,
                cancellationToken: cancellationToken);
        }

        private async Task<IChannel> GetChannelAsync(CancellationToken cancellationToken)
        {
            if (_channel is { IsOpen: true })
            {
                return _channel;
            }

            await _connectLock.WaitAsync(cancellationToken);
            try
            {
                if (_channel is { IsOpen: true })
                {
                    return _channel;
                }

                _connection = await RabbitMqConnectionHelper.ConnectWithRetryAsync(_options, _logger, cancellationToken, maxAttempts: 5);
                _channel = await _connection.CreateChannelAsync(cancellationToken: cancellationToken);
                await _channel.QueueDeclareAsync(
                    queue: _options.NotificationsQueueName,
                    durable: true,
                    exclusive: false,
                    autoDelete: false,
                    cancellationToken: cancellationToken);

                return _channel;
            }
            finally
            {
                _connectLock.Release();
            }
        }

        public async ValueTask DisposeAsync()
        {
            if (_channel != null)
            {
                await _channel.CloseAsync();
                _channel.Dispose();
            }

            if (_connection != null)
            {
                await _connection.CloseAsync();
                _connection.Dispose();
            }
        }
    }
}
