using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services;

namespace MyDent.WebAPI.Controllers;

// Requires a valid JWT — the business rules we already wrote (a patient can only book/cancel
// their own appointments) only mean anything if we actually know who's calling. Test by
// calling the login endpoint first and pasting the token into Swagger's Authorize button.
[Authorize]
public class AppointmentsController
    : BaseReadController<AppointmentResponse, AppointmentSearch, IAppointmentService>
{
    public AppointmentsController(IAppointmentService service) : base(service)
    {
    }

    // Public, like DoctorWorkingHours/DoctorAbsences it's derived from — a visitor browsing
    // before registering should be able to see what times are open, not just logged-in patients.
    [AllowAnonymous]
    [HttpGet("available-slots")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<List<AvailableSlotResponse>>> GetAvailableSlots([FromQuery] AvailableSlotsRequest request)
    {
        return await _service.GetAvailableSlotsAsync(request);
    }

    [HttpPost]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<AppointmentResponse>> Create([FromBody] AppointmentInsertRequest request)
    {
        var result = await _service.InsertAsync(request);
        return result;
    }

    // Staff-only: a patient shouldn't be able to self-confirm their own booking.
    [HttpPost("{id}/confirm")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<AppointmentResponse>> Confirm(int id)
    {
        // KeyNotFoundException -> 404 is now handled centrally by ExceptionFilter.
        return await _service.ConfirmAsync(id);
    }

    // Open to any authenticated user — AppointmentService.CancelAsync enforces that a
    // non-Admin caller can only cancel their own appointment.
    [HttpPost("{id}/cancel")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<AppointmentResponse>> Cancel(int id, [FromBody] AppointmentCancelRequest request)
    {
        return await _service.CancelAsync(id, request);
    }

    // Staff-only: completing a visit is a clinic-side fact, not something a patient reports.
    [HttpPost("{id}/complete")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<AppointmentResponse>> Complete(int id)
    {
        return await _service.CompleteAsync(id);
    }

    // Staff-only: re-assigning doctor/service/time on an existing appointment (not the patient —
    // see AppointmentRescheduleRequest for why that's deliberately excluded).
    [HttpPost("{id}/reschedule")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<AppointmentResponse>> Reschedule(int id, [FromBody] AppointmentRescheduleRequest request)
    {
        return await _service.RescheduleAsync(id, request);
    }

    [HttpGet("{id}/history")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<List<AppointmentStatusHistoryResponse>>> History(int id)
    {
        return await _service.GetHistoryAsync(id);
    }
}
