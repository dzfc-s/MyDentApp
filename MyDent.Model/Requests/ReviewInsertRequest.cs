
namespace MyDent.Model.Requests
{
    public class ReviewInsertRequest
    {

        public int AppointmentId { get; set; }

        public int Rating { get; set; }

        public string? Comment { get; set; } 
    }
}
