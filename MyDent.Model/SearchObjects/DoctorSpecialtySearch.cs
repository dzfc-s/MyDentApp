namespace MyDent.Model.SearchObjects
{
    public class DoctorSpecialtySearch : BaseSearchObject
    {
        public int? DoctorId { get; set; }
        public int? ServiceCategoryId { get; set; }
    }
}
