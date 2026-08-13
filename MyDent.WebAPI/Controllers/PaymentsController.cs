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
    public PaymentsController(IPaymentService service) : base(service)
    {
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
        try
        {
            return await _service.ConfirmAsync(id);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    // Staff-only: refunding is a clinic decision, not something a patient triggers themselves.
    [HttpPost("{id}/refund")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PaymentResponse>> Refund(int id)
    {
        try
        {
            return await _service.RefundAsync(id);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }
}
