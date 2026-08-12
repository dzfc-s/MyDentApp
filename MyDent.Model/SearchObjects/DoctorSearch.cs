namespace MyDent.Model.SearchObjects
{
    public class DoctorSearch : BaseSearchObject
    {
        public string? Name { get; set; }
        public bool? IsActive { get; set; }

        // Only doctors specialized in this category — used by the booking flow
        // ("service -> only specialists available for that category").
        public int? ServiceCategoryId { get; set; }
    }
}
