using System;

namespace MyDent.Model.Requests
{
    public class DoctorAbsenceUpdateRequest
    {
        public DateOnly StartDate { get; set; }
        public DateOnly EndDate { get; set; }
        public string Reason { get; set; } = string.Empty;
    }
}
