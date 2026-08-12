using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services;

namespace MyDent.WebAPI.Controllers;

public class ServiceCategoriesController
    : BaseCRUDController<ServiceCategoryResponse, ServiceCategorySearch, ServiceCategoryInsertRequest, ServiceCategoryUpdateRequest, IServiceCategoryService>
{
    public ServiceCategoriesController(IServiceCategoryService service) : base(service)
    {
    }
}
