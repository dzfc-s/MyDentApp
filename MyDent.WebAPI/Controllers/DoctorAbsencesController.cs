using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services;

namespace MyDent.WebAPI.Controllers;

public class DoctorAbsencesController
    : BaseCRUDController<DoctorAbsenceResponse, DoctorAbsenceSearch, DoctorAbsenceInsertRequest, DoctorAbsenceUpdateRequest, IDoctorAbsenceService>
{
    public DoctorAbsencesController(IDoctorAbsenceService service) : base(service)
    {
    }
}
