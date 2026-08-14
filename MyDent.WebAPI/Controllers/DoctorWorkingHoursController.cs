using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services;

namespace MyDent.WebAPI.Controllers;

// Browsing stays public (needed to show patients when a doctor is available); managing
// working hours is Admin-only.
public class DoctorWorkingHoursController
    : BaseCRUDController<DoctorWorkingHoursResponse, DoctorWorkingHoursSearch, DoctorWorkingHoursInsertRequest, DoctorWorkingHoursUpdateRequest, IDoctorWorkingHoursService>
{
    public DoctorWorkingHoursController(IDoctorWorkingHoursService service) : base(service)
    {
    }

    [Authorize(Roles = "Admin")]
    public override Task<ActionResult<DoctorWorkingHoursResponse>> Create([FromBody] DoctorWorkingHoursInsertRequest request)
        => base.Create(request);

    [Authorize(Roles = "Admin")]
    public override Task<ActionResult<DoctorWorkingHoursResponse>> Update(int id, [FromBody] DoctorWorkingHoursUpdateRequest request)
        => base.Update(id, request);

    [Authorize(Roles = "Admin")]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
