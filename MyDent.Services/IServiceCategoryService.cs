using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;

namespace MyDent.Services
{
    public interface IServiceCategoryService
        : IBaseCRUDService<ServiceCategoryResponse, ServiceCategorySearch, ServiceCategoryInsertRequest, ServiceCategoryUpdateRequest>
    {
    }
}
