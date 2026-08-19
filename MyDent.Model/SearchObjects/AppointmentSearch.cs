using System;
using MyDent.Model.Enums;

namespace MyDent.Model.SearchObjects
{
    public class AppointmentSearch : BaseSearchObject
    {
        public int? PatientId { get; set; }
        public int? DoctorId { get; set; }
        public string? PatientName { get; set; }
        public string? DoctorName { get; set; }
        public int? DentalServiceId { get; set; }
        public AppointmentStatus? Status { get; set; }
        public DateTime? DateFrom { get; set; }
        public DateTime? DateTo { get; set; }
    }
}
