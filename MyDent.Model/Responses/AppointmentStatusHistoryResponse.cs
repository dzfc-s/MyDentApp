using System;
using MyDent.Model.Enums;

namespace MyDent.Model.Responses
{
    public class AppointmentStatusHistoryResponse
    {
        public int Id { get; set; }
        public int AppointmentId { get; set; }
        public AppointmentStatus FromStatus { get; set; }
        public AppointmentStatus ToStatus { get; set; }
        public int ChangedByUserId { get; set; }
        public string ChangedByUserName { get; set; } = string.Empty;
        public string? Reason { get; set; }
        public DateTime ChangedAt { get; set; }
    }
}
