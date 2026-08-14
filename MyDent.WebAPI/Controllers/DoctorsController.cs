using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services;

namespace MyDent.WebAPI.Controllers;

// Catalog data: browsing (GetAll/GetById) stays public so patients can see the doctor list
// without logging in — only managing it (Create/Update/Delete) is an Admin action.
public class DoctorsController
    : BaseCRUDController<DoctorResponse, DoctorSearch, DoctorInsertRequest, DoctorUpdateRequest, IDoctorService>
{
    public DoctorsController(IDoctorService service) : base(service)
    {
    }

    [Authorize(Roles = "Admin")]
    public override Task<ActionResult<DoctorResponse>> Create([FromBody] DoctorInsertRequest request)
        => base.Create(request);

    [Authorize(Roles = "Admin")]
    public override Task<ActionResult<DoctorResponse>> Update(int id, [FromBody] DoctorUpdateRequest request)
        => base.Update(id, request);

    [Authorize(Roles = "Admin")]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
