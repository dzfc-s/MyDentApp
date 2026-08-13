using MyDent.Model.Enums;

namespace MyDent.Model.Requests
{
    public class NotificationInsertRequest
    {
        public int UserId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public NotificationType Type { get; set; } = NotificationType.General;
        public int? AppointmentId { get; set; }
        public int? ServiceCategoryId { get; set; }
    }
}
