using System;

namespace MyDent.Model.Requests
{
    public class RevenueReportRequest
    {
        // Nullable so the service can tell "not provided at all" apart from "provided as
        // 0001-01-01" (the non-nullable DateTime default) and reject the former with a clear
        // error, instead of silently generating a report for a one-day range in year 1.
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public int? DoctorId { get; set; }
    }
}
