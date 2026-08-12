using System;

namespace MyDent.Model.Requests
{
    public class DoctorAbsenceInsertRequest
    {
        public int DoctorId { get; set; }
        public DateOnly StartDate { get; set; }
        public DateOnly EndDate { get; set; }
        public string Reason { get; set; } = string.Empty;
    }
}
