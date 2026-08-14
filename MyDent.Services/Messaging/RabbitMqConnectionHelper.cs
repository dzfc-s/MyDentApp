using Microsoft.Extensions.Logging;
using RabbitMQ.Client;

namespace MyDent.Services.Messaging
{
    // Shared by the publisher (API) and the consumer (MyDent.NotificationWorker) — both need to
    // survive RabbitMQ not being reachable yet (e.g. container still starting) without crashing
    // or busy-looping, so both retry with the same capped exponential backoff.
    public static class RabbitMqConnectionHelper
    {
        // maxAttempts: null retries forever — appropriate for the worker's startup connection,
        // which has nothing else waiting on it. The API's publisher passes a small cap instead,
        // since a publish happens on a request thread (Confirm/Cancel) with no caller-supplied
        // cancellation token — an unbounded retry there would hang the HTTP request indefinitely
        // if RabbitMQ is down, rather than failing fast with a 5xx the caller can retry.
        public static async Task<IConnection> ConnectWithRetryAsync(RabbitMqOptions options, ILogger logger, CancellationToken cancellationToken, int? maxAttempts = null)
        {
            var factory = new ConnectionFactory
            {
                HostName = options.HostName,
                Port = options.Port,
                UserName = options.UserName,
                Password = options.Password
            };

            var delay = TimeSpan.FromSeconds(1);
            var maxDelay = TimeSpan.FromSeconds(30);
            var attempt = 0;

            while (true)
            {
                attempt++;
                try
                {
                    return await factory.CreateConnectionAsync(cancellationToken);
                }
                catch (Exception ex)
                {
                    if (maxAttempts.HasValue && attempt >= maxAttempts.Value)
                    {
                        logger.LogError(ex, "Failed to connect to RabbitMQ at {HostName}:{Port} after {Attempts} attempts, giving up.",
                            options.HostName, options.Port, attempt);
                        throw;
                    }

                    logger.LogWarning(ex, "Failed to connect to RabbitMQ at {HostName}:{Port}, retrying in {DelaySeconds}s.",
                        options.HostName, options.Port, delay.TotalSeconds);
                    await Task.Delay(delay, cancellationToken);
                    delay = delay + delay > maxDelay ? maxDelay : delay + delay;
                }
            }
        }
    }
}
