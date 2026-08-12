namespace MyDent.Model.SearchObjects
{
    public class DentalServiceSearch : BaseSearchObject
    {
        public string? Name { get; set; }
        public int? ServiceCategoryId { get; set; }
        public bool? IsActive { get; set; }
    }
}
