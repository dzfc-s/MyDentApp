using System;
using MyDent.Model.Enums;

namespace MyDent.Model.Responses
{
    public class NotificationResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string UserName { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public NotificationType Type { get; set; }
        public bool IsRead { get; set; }
        public int? AppointmentId { get; set; }
        public int? ServiceCategoryId { get; set; }
        public string ServiceCategoryName { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }
}
