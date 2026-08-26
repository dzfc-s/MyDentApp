using System.Text.Json;
using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using MyDent.Model.Requests;
using MyDent.Services.Email;
using MyDent.Services.Messaging;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace MyDent.NotificationWorker;

// Consumes the queue MyDent.WebAPI's RabbitMqEmailEventPublisher publishes to and actually sends
// the email via SMTP — this is the "real async work" for password resets, same reasoning as
// NotificationConsumerService for in-app notifications.
public class PasswordResetEmailConsumerService : BackgroundService
{
    private readonly RabbitMqOptions _rabbitOptions;
    private readonly SmtpOptions _smtpOptions;
    private readonly ILogger<PasswordResetEmailConsumerService> _logger;

    private IConnection? _connection;
    private IChannel? _channel;

    public PasswordResetEmailConsumerService(RabbitMqOptions rabbitOptions, SmtpOptions smtpOptions, ILogger<PasswordResetEmailConsumerService> logger)
    {
        _rabbitOptions = rabbitOptions;
        _smtpOptions = smtpOptions;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _connection = await RabbitMqConnectionHelper.ConnectWithRetryAsync(_rabbitOptions, _logger, stoppingToken);
        _channel = await _connection.CreateChannelAsync(cancellationToken: stoppingToken);

        await _channel.QueueDeclareAsync(
            queue: _rabbitOptions.PasswordResetEmailQueueName,
            durable: true,
            exclusive: false,
            autoDelete: false,
            cancellationToken: stoppingToken);

        await _channel.BasicQosAsync(prefetchSize: 0, prefetchCount: 1, global: false, cancellationToken: stoppingToken);

        var consumer = new AsyncEventingBasicConsumer(_channel);
        consumer.ReceivedAsync += async (_, ea) =>
        {
            // Declared outside the try so the catch block below can still report which
            // recipient a failure belongs to, even if the failure happens after deserialization.
            PasswordResetEmailRequest? request = null;
            try
            {
                request = JsonSerializer.Deserialize<PasswordResetEmailRequest>(ea.Body.Span)
                    ?? throw new InvalidOperationException("Message body deserialized to null.");

                if (string.IsNullOrWhiteSpace(_smtpOptions.Host))
                {
                    // Not configured yet (see .env) — this will never succeed, so don't burn the
                    // retry/backoff cycle below on a guaranteed failure. Ack it anyway, otherwise a
                    // patient's reset request just gets silently redelivered forever.
                    _logger.LogWarning("Smtp:Host is not configured — dropping password reset email to {Email}.", request.ToEmail);
                    await _channel.BasicAckAsync(ea.DeliveryTag, multiple: false, cancellationToken: stoppingToken);
                    return;
                }

                await SendWithRetryAsync(request, stoppingToken);

                await _channel.BasicAckAsync(ea.DeliveryTag, multiple: false, cancellationToken: stoppingToken);
            }
            catch (Exception ex)
            {
                // Exhausted the retries below — drop rather than requeue, same reasoning as
                // NotificationConsumerService: a message that keeps failing would just poison-loop
                // and block everything behind it.
                _logger.LogError(ex, "Failed to send password reset email to {Email} after retries; dropping it.", request?.ToEmail);
                await _channel.BasicNackAsync(ea.DeliveryTag, multiple: false, requeue: false, cancellationToken: stoppingToken);
            }
        };

        await _channel.BasicConsumeAsync(_rabbitOptions.PasswordResetEmailQueueName, autoAck: false, consumer: consumer, cancellationToken: stoppingToken);

        await Task.Delay(Timeout.Infinite, stoppingToken).ContinueWith(_ => { }, TaskScheduler.Default);
    }

    // 1s -> 2s -> 4s -> 8s, per the course's documented retry-with-backoff expectation for
    // consumer processing failures — SMTP hiccups are usually transient (server busy, brief
    // network blip), worth retrying, unlike a malformed message that will just fail identically
    // every time.
    private async Task SendWithRetryAsync(PasswordResetEmailRequest request, CancellationToken cancellationToken)
    {
        var delay = TimeSpan.FromSeconds(1);
        const int maxAttempts = 4;

        for (var attempt = 1; attempt <= maxAttempts; attempt++)
        {
            try
            {
                await SendEmailAsync(request, cancellationToken);
                return;
            }
            catch (Exception ex) when (attempt < maxAttempts)
            {
                _logger.LogWarning(ex, "Failed to send password reset email to {Email} (attempt {Attempt}/{Max}), retrying in {DelaySeconds}s.",
                    request.ToEmail, attempt, maxAttempts, delay.TotalSeconds);
                await Task.Delay(delay, cancellationToken);
                delay += delay;
            }
        }

        // Final attempt — let a failure here propagate to the caller's catch block.
        await SendEmailAsync(request, cancellationToken);
    }

    private async Task SendEmailAsync(PasswordResetEmailRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(_smtpOptions.Host))
        {
            throw new InvalidOperationException("SMTP is not configured (Smtp:Host is empty).");
        }

        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(_smtpOptions.FromName, _smtpOptions.FromAddress));
        message.To.Add(MailboxAddress.Parse(request.ToEmail));
        message.Subject = "MyDent - kod za resetovanje lozinke";
        message.Body = new TextPart("plain")
        {
            Text = $"Zdravo {request.FirstName},\n\n" +
                   $"Vaš kod za resetovanje lozinke je: {request.Code}\n\n" +
                   "Kod vrijedi 15 minuta. Ako niste vi zatražili resetovanje lozinke, slobodno ignorišite ovaj email.\n\n" +
                   "MyDent"
        };

        using var client = new SmtpClient();
        var secureSocketOptions = _smtpOptions.UseSsl ? SecureSocketOptions.StartTls : SecureSocketOptions.None;
        await client.ConnectAsync(_smtpOptions.Host, _smtpOptions.Port, secureSocketOptions, cancellationToken);
        if (!string.IsNullOrEmpty(_smtpOptions.Username))
        {
            await client.AuthenticateAsync(_smtpOptions.Username, _smtpOptions.Password, cancellationToken);
        }
        await client.SendAsync(message, cancellationToken);
        await client.DisconnectAsync(true, cancellationToken);
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
