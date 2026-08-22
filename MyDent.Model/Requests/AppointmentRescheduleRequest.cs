using System;

namespace MyDent.Model.Requests
{
    // Deliberately narrower than AppointmentInsertRequest: no PatientId. Re-assigning an
    // existing appointment to a *different* patient is a much riskier operation (wrong patient's
    // history, notifications, payment) than an admin fixing the doctor/service/time — if that's
    // ever needed the right move is cancel + rebook under the correct patient, not this endpoint.
    public class AppointmentRescheduleRequest
    {
        public int DoctorId { get; set; }
        public int DentalServiceId { get; set; }
        public DateTime ScheduledAt { get; set; }
    }
}
