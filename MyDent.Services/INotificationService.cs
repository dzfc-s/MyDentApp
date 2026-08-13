using System.Threading.Tasks;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;

namespace MyDent.Services
{
    // Not IBaseCRUDService: notifications are system/staff-authored content, not something a
    // user edits — the only thing a user can change about their own notification is IsRead,
    // via the dedicated MarkAsReadAsync action.
    public interface INotificationService : IBaseReadService<NotificationResponse, NotificationSearch>
    {
        Task<NotificationResponse> InsertAsync(NotificationInsertRequest request);
        Task<NotificationResponse> MarkAsReadAsync(int id);
        Task DeleteAsync(int id);
    }
}
