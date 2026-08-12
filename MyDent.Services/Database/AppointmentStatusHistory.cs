using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using MyDent.Model.Enums;

namespace MyDent.Services.Database
{
    // Audit trail: who changed an appointment's status, when, and why.
    public class AppointmentStatusHistory
    {
        [Key]
        public int Id { get; set; }

        public int AppointmentId { get; set; }

        [ForeignKey("AppointmentId")]
        public Appointment Appointment { get; set; } = null!;

        [Required]
        public AppointmentStatus FromStatus { get; set; }

        [Required]
        public AppointmentStatus ToStatus { get; set; }

        public int ChangedByUserId { get; set; }

        [ForeignKey("ChangedByUserId")]
        public User ChangedByUser { get; set; } = null!;

        [MaxLength(500)]
        public string? Reason { get; set; }

        public DateTime ChangedAt { get; set; } = DateTime.UtcNow;
    }
}
