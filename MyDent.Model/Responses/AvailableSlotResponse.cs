using System;

namespace MyDent.Model.Responses
{
    public class AvailableSlotResponse
    {
        // StartTime doubles as the exact value the client sends back as ScheduledAt when booking
        // — no need for the client to recombine date+time itself.
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
    }
}
