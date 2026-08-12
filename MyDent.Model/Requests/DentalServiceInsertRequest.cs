namespace MyDent.Model.Requests
{
    public class DentalServiceInsertRequest
    {
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public int DurationMinutes { get; set; }
        public int ServiceCategoryId { get; set; }
        public int? ImageAssetId { get; set; }
    }
}
