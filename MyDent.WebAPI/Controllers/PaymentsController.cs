using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services;

namespace MyDent.WebAPI.Controllers;

// Financial data — everything here depends on knowing who's calling, same reasoning as
// Appointments/Reviews/Notifications.
[Authorize]
public class PaymentsController
    : BaseReadController<PaymentResponse, PaymentSearch, IPaymentService>
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<PaymentsController> _logger;

    public PaymentsController(IPaymentService service, IConfiguration configuration, ILogger<PaymentsController> logger) : base(service)
    {
        _configuration = configuration;
        _logger = logger;
    }

    // Stripe calls this directly — no JWT, so it needs its own AllowAnonymous to override the
    // controller-level [Authorize]. Authorization here is the Stripe-Signature header check inside
    // HandleWebhookAsync, not a user session. Configure this URL as the endpoint in the Stripe
    // Dashboard (or via `stripe listen --forward-to <api>/Payments/webhook` for local testing) and
    // put its signing secret in Stripe__WebhookSecret.
    [AllowAnonymous]
    [HttpPost("webhook")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Webhook()
    {
        using var reader = new StreamReader(Request.Body);
        var json = await reader.ReadToEndAsync();
        var signature = Request.Headers["Stripe-Signature"].ToString();
        var webhookSecret = _configuration["Stripe:WebhookSecret"] ?? string.Empty;

        try
        {
            await _service.HandleWebhookAsync(json, signature, webhookSecret);
            return Ok();
        }
        catch (Stripe.StripeException ex)
        {
            // Previously swallowed with zero logging — a bad/forged signature or a malformed
            // event from Stripe left no trace at all. StripeEvent (ex.StripeError?.Type) is safe
            // to log; the raw json/signature aren't, since a forged request could contain
            // attacker-controlled content.
            _logger.LogError(ex, "Stripe webhook rejected: {ErrorType}.", ex.StripeError?.Type ?? "unknown");
            return BadRequest();
        }
    }

    [HttpPost("create-intent")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<PaymentIntentResponse>> CreateIntent([FromBody] PaymentCreateIntentRequest request)
    {
        var result = await _service.CreateIntentAsync(request);
        return result;
    }

    [HttpPost("{id}/confirm")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PaymentResponse>> Confirm(int id)
    {
        // KeyNotFoundException -> 404 is now handled centrally by ExceptionFilter.
        return await _service.ConfirmAsync(id);
    }

    [HttpPost("{id}/cancel")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PaymentResponse>> Cancel(int id)
    {
        return await _service.CancelAsync(id);
    }

    // Staff-only: refunding is a clinic decision, not something a patient triggers themselves.
    [HttpPost("{id}/refund")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PaymentResponse>> Refund(int id)
    {
        return await _service.RefundAsync(id);
    }
}
