using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services;

namespace MyDent.WebAPI.Controllers;

public class DoctorsController
    : BaseCRUDController<DoctorResponse, DoctorSearch, DoctorInsertRequest, DoctorUpdateRequest, IDoctorService>
{
    public DoctorsController(IDoctorService service) : base(service)
    {
    }
}
