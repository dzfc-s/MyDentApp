using MyDent.Model.Enums;

namespace MyDent.Model.Responses
{
    public class RecommendationResponse
    {
        public int DentalServiceId { get; set; }
        public string DentalServiceName { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public int DurationMinutes { get; set; }
        public int ServiceCategoryId { get; set; }
        public string ServiceCategoryName { get; set; } = string.Empty;
        public RecommendationReason Reason { get; set; }
        public string ReasonDetail { get; set; } = string.Empty;
    }
}
