using System.Collections.Generic;
using System.Threading.Tasks;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;

namespace MyDent.Services
{
    // Not IBaseCRUDService: appointments have no generic Update/Delete — status changes go
    // through explicit actions (Confirm/Cancel/Complete) so each one can be validated against
    // the state machine and logged to AppointmentStatusHistory.
    public interface IAppointmentService : IBaseReadService<AppointmentResponse, AppointmentSearch>
    {
        Task<List<AvailableSlotResponse>> GetAvailableSlotsAsync(AvailableSlotsRequest request);
        Task<AppointmentResponse> InsertAsync(AppointmentInsertRequest request);
        Task<AppointmentResponse> ConfirmAsync(int id);
        Task<AppointmentResponse> CancelAsync(int id, AppointmentCancelRequest request);
        Task<AppointmentResponse> CompleteAsync(int id);
        Task<List<AppointmentStatusHistoryResponse>> GetHistoryAsync(int id);
    }
}
