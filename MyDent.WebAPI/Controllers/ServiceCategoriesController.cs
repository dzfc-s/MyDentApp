using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services;

namespace MyDent.WebAPI.Controllers;

// Catalog data: browsing (GetAll/GetById) stays public so patients can see service categories
// without logging in — only managing it (Create/Update/Delete) is an Admin action.
public class ServiceCategoriesController
    : BaseCRUDController<ServiceCategoryResponse, ServiceCategorySearch, ServiceCategoryInsertRequest, ServiceCategoryUpdateRequest, IServiceCategoryService>
{
    public ServiceCategoriesController(IServiceCategoryService service) : base(service)
    {
    }

    [Authorize(Roles = "Admin")]
    public override Task<ActionResult<ServiceCategoryResponse>> Create([FromBody] ServiceCategoryInsertRequest request)
        => base.Create(request);

    [Authorize(Roles = "Admin")]
    public override Task<ActionResult<ServiceCategoryResponse>> Update(int id, [FromBody] ServiceCategoryUpdateRequest request)
        => base.Update(id, request);

    [Authorize(Roles = "Admin")]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
