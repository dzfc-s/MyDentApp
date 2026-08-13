using MyDent.Model.Enums;

namespace MyDent.Model.SearchObjects
{
    public class NotificationSearch : BaseSearchObject
    {
        // Only meaningful for Admin callers — a non-Admin's results are always forced to their
        // own UserId by NotificationService regardless of what's sent here.
        public int? UserId { get; set; }
        public NotificationType? Type { get; set; }
        public bool? IsRead { get; set; }
        public int? AppointmentId { get; set; }
    }
}
