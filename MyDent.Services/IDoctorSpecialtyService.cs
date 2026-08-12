using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;

namespace MyDent.Services
{
    public interface IDoctorSpecialtyService
        : IBaseCRUDService<DoctorSpecialtyResponse, DoctorSpecialtySearch, DoctorSpecialtyInsertRequest, DoctorSpecialtyUpdateRequest>
    {
    }
}
