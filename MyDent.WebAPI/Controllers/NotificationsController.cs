using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services;

namespace MyDent.WebAPI.Controllers;

// Everything here depends on knowing who's calling (private inbox + ownership checks), same
// reasoning as Appointments/Reviews.
[Authorize]
public class NotificationsController
    : BaseReadController<NotificationResponse, NotificationSearch, INotificationService>
{
    public NotificationsController(INotificationService service) : base(service)
    {
    }

    // Staff-only: notifications are authored by the system/clinic, not created by users
    // themselves — see INotificationService for the full reasoning.
    [HttpPost]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<NotificationResponse>> Create([FromBody] NotificationInsertRequest request)
    {
        var result = await _service.InsertAsync(request);
        return result;
    }

    [HttpPost("{id}/markAsRead")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<NotificationResponse>> MarkAsRead(int id)
    {
        try
        {
            return await _service.MarkAsReadAsync(id);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    [HttpDelete("{id}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int id)
    {
        try
        {
            await _service.DeleteAsync(id);
            return NoContent();
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }
}
