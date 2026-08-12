using System;

namespace MyDent.Model.Requests
{
    public class AppointmentInsertRequest
    {
        public int PatientId { get; set; }
        public int DoctorId { get; set; }
        public int DentalServiceId { get; set; }
        public DateTime ScheduledAt { get; set; }
    }
}
