using System;

namespace MyDent.Model.Requests
{
    public class DoctorWorkingHoursUpdateRequest
    {
        public TimeSpan StartTime { get; set; }
        public TimeSpan EndTime { get; set; }
    }
}
