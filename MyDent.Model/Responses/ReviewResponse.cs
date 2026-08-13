using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyDent.Model.Responses
{
    public class ReviewResponse
    {
        public int Id { get; set; }

        public int AppointmentId { get; set; }

        public string DoctorName { get; set; } = string.Empty;
        public string DentalServiceName { get; set; } = string.Empty;
        public string PatientName { get; set; } = string.Empty;

        public int Rating { get; set; }

        public string? Comment { get; set; }

        public bool IsApproved { get; set; } 

        public DateTime CreatedAt { get; set; }

    }
}
