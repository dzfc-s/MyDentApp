using System;
using MyDent.Model.Enums;

namespace MyDent.Model.Responses
{
    public class AppointmentResponse
    {
        public int Id { get; set; }
        public int PatientId { get; set; }
        public string PatientName { get; set; } = string.Empty;
        public int DoctorId { get; set; }
        public string DoctorName { get; set; } = string.Empty;
        public int DentalServiceId { get; set; }
        public string DentalServiceName { get; set; } = string.Empty;
        public DateTime ScheduledAt { get; set; }
        public int DurationMinutes { get; set; }
        public decimal Price { get; set; }
        public AppointmentStatus Status { get; set; }
        public string? CancellationReason { get; set; }
        public int? CancelledByUserId { get; set; }
        public DateTime? CancelledAt { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
