using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services;

namespace MyDent.WebAPI.Controllers;

public class DentalServicesController
    : BaseCRUDController<DentalServiceResponse, DentalServiceSearch, DentalServiceInsertRequest, DentalServiceUpdateRequest, IDentalServiceService>
{
    public DentalServicesController(IDentalServiceService service) : base(service)
    {
    }
}
