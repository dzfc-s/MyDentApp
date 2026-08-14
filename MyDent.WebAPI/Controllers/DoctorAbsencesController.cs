using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services;

namespace MyDent.WebAPI.Controllers;

// Browsing stays public (needed to compute doctor availability); managing absences is Admin-only.
public class DoctorAbsencesController
    : BaseCRUDController<DoctorAbsenceResponse, DoctorAbsenceSearch, DoctorAbsenceInsertRequest, DoctorAbsenceUpdateRequest, IDoctorAbsenceService>
{
    public DoctorAbsencesController(IDoctorAbsenceService service) : base(service)
    {
    }

    [Authorize(Roles = "Admin")]
    public override Task<ActionResult<DoctorAbsenceResponse>> Create([FromBody] DoctorAbsenceInsertRequest request)
        => base.Create(request);

    [Authorize(Roles = "Admin")]
    public override Task<ActionResult<DoctorAbsenceResponse>> Update(int id, [FromBody] DoctorAbsenceUpdateRequest request)
        => base.Update(id, request);

    [Authorize(Roles = "Admin")]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
