using System;

namespace MyDent.Model.SearchObjects
{
    public class DoctorWorkingHoursSearch : BaseSearchObject
    {
        public int? DoctorId { get; set; }
        public DayOfWeek? DayOfWeek { get; set; }
    }
}
