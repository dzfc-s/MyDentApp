namespace MyDent.Model.SearchObjects
{
    public class NewsSearch : BaseSearchObject
    {
        public string? Title { get; set; }

        // Only meaningful for Admin callers — a non-Admin's results are always forced to
        // IsPublished=true by NewsService regardless of what's sent here.
        public bool? IsPublished { get; set; }
    }
}
