using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services;

namespace MyDent.WebAPI.Controllers;

// Catalog data: browsing (GetAll/GetById) stays public so patients can see the price list
// without logging in — only managing it (Create/Update/Delete) is an Admin action.
public class DentalServicesController
    : BaseCRUDController<DentalServiceResponse, DentalServiceSearch, DentalServiceInsertRequest, DentalServiceUpdateRequest, IDentalServiceService>
{
    public DentalServicesController(IDentalServiceService service) : base(service)
    {
    }

    [Authorize(Roles = "Admin")]
    public override Task<ActionResult<DentalServiceResponse>> Create([FromBody] DentalServiceInsertRequest request)
        => base.Create(request);

    [Authorize(Roles = "Admin")]
    public override Task<ActionResult<DentalServiceResponse>> Update(int id, [FromBody] DentalServiceUpdateRequest request)
        => base.Update(id, request);

    [Authorize(Roles = "Admin")]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
