

namespace MyDent.Model.SearchObjects
{
    public class ReviewSearch : BaseSearchObject
    {
        public int? AppointmentId { get; set; }
        public int? Rating { get; set; }
        public int? PatientId { get; set; }
        public int? DoctorId { get; set; }
    }
}
