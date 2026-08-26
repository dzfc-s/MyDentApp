using System;

namespace MyDent.Model.SearchObjects
{
    public class DoctorAbsenceSearch : BaseSearchObject
    {
        public int? DoctorId { get; set; }

        // Overlap filter: any absence whose [StartDate, EndDate] window intersects
        // [DateFrom, DateTo] — e.g. "who's absent this week/month" for the admin calendar.
        public DateOnly? DateFrom { get; set; }
        public DateOnly? DateTo { get; set; }
    }
}
