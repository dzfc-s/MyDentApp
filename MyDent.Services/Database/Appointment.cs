using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using MyDent.Model.Enums;

namespace MyDent.Services.Database
{
    public class Appointment
    {
        [Key]
        public int Id { get; set; }

        public int PatientId { get; set; }

        [ForeignKey("PatientId")]
        public User Patient { get; set; } = null!;

        public int DoctorId { get; set; }

        [ForeignKey("DoctorId")]
        public Doctor Doctor { get; set; } = null!;

        public int DentalServiceId { get; set; }

        [ForeignKey("DentalServiceId")]
        public DentalService DentalService { get; set; } = null!;

        [Required]
        public DateTime ScheduledAt { get; set; }

        // Snapshot from DentalService at booking time — price/duration must not
        // silently change if the service's price is edited later.
        [Required]
        public int DurationMinutes { get; set; }

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal Price { get; set; }

        [Required]
        public AppointmentStatus Status { get; set; } = AppointmentStatus.Pending;

        [MaxLength(500)]
        public string? CancellationReason { get; set; }

        public int? CancelledByUserId { get; set; }

        [ForeignKey("CancelledByUserId")]
        public User? CancelledByUser { get; set; }

        public DateTime? CancelledAt { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public ICollection<AppointmentStatusHistory> StatusHistory { get; set; } = new List<AppointmentStatusHistory>();
        public Review? Review { get; set; }
        public Payment? Payment { get; set; }
        public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
    }
}
