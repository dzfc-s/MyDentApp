using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;

namespace MyDent.Services
{
    public interface IDoctorWorkingHoursService
        : IBaseCRUDService<DoctorWorkingHoursResponse, DoctorWorkingHoursSearch, DoctorWorkingHoursInsertRequest, DoctorWorkingHoursUpdateRequest>
    {
    }
}
