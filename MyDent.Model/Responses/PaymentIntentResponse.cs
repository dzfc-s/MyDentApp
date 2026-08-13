namespace MyDent.Model.Responses
{
    // Everything the flutter_stripe PaymentSheet needs client-side to collect card details and
    // confirm directly with Stripe — none of this is persisted, it's returned once at creation.
    public class PaymentIntentResponse
    {
        public int PaymentId { get; set; }
        public string ClientSecret { get; set; } = string.Empty;
        public string EphemeralKey { get; set; } = string.Empty;
        public string CustomerId { get; set; } = string.Empty;
    }
}
