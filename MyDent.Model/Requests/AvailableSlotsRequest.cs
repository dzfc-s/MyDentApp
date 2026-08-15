using System;

namespace MyDent.Model.Requests
{
    public class AvailableSlotsRequest
    {
        public int DoctorId { get; set; }
        public int DentalServiceId { get; set; }
        public DateOnly Date { get; set; }
    }
}
