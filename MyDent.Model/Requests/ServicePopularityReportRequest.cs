using System;

namespace MyDent.Model.Requests
{
    public class ServicePopularityReportRequest
    {
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
    }
}
