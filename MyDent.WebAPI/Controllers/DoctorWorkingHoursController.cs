using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services;

namespace MyDent.WebAPI.Controllers;

public class DoctorWorkingHoursController
    : BaseCRUDController<DoctorWorkingHoursResponse, DoctorWorkingHoursSearch, DoctorWorkingHoursInsertRequest, DoctorWorkingHoursUpdateRequest, IDoctorWorkingHoursService>
{
    public DoctorWorkingHoursController(IDoctorWorkingHoursService service) : base(service)
    {
    }
}
