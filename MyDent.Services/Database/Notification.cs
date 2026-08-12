using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyDent.Services.Database
{
    public enum NotificationType
    {
        General,
        AppointmentConfirmed,
        AppointmentCancelled,
        AppointmentReminder,
        RecurringServiceReminder
    }

    public class Notification
    {
        [Key]
        public int Id { get; set; }

        public int UserId { get; set; }

        [ForeignKey("UserId")]
        public User User { get; set; } = null!;

        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [MaxLength(1000)]
        public string Message { get; set; } = string.Empty;

        [Required]
        public NotificationType Type { get; set; } = NotificationType.General;

        public bool IsRead { get; set; } = false;

        public int? AppointmentId { get; set; }

        [ForeignKey("AppointmentId")]
        public Appointment? Appointment { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
