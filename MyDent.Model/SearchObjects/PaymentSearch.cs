using MyDent.Model.Enums;

namespace MyDent.Model.SearchObjects
{
    public class PaymentSearch : BaseSearchObject
    {
        public int? AppointmentId { get; set; }
        public PaymentStatus? Status { get; set; }

        // Only meaningful for Admin callers — a non-Admin's results are always forced to their
        // own payments by PaymentService regardless of what's sent here.
        public int? PatientId { get; set; }
    }
}
