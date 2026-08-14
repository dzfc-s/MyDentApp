using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services;

namespace MyDent.WebAPI.Controllers;

// Pure join entity (Doctor <-> ServiceCategory) with no attributes of its own, so there's
// nothing meaningful to "edit" — only linking (Create) and unlinking (Delete) make sense.
// Reassigning either id is indistinguishable from deleting and recreating the link, so this
// intentionally doesn't inherit BaseCRUDController's PUT endpoint.
public class DoctorSpecialtiesController
    : BaseReadController<DoctorSpecialtyResponse, DoctorSpecialtySearch, IDoctorSpecialtyService>
{
    public DoctorSpecialtiesController(IDoctorSpecialtyService service) : base(service)
    {
    }

    [Authorize(Roles = "Admin")]
    [HttpPost]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<DoctorSpecialtyResponse>> Create([FromBody] DoctorSpecialtyInsertRequest request)
    {
        var result = await _service.InsertAsync(request);
        return result;
    }

    [Authorize(Roles = "Admin")]
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
