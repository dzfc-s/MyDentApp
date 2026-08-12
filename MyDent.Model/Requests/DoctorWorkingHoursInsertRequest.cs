using System;

namespace MyDent.Model.Requests
{
    public class DoctorWorkingHoursInsertRequest
    {
        public int DoctorId { get; set; }
        public DayOfWeek DayOfWeek { get; set; }
        public TimeSpan StartTime { get; set; }
        public TimeSpan EndTime { get; set; }
    }
}
