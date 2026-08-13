namespace MyDent.Model.Requests
{
    public class NewsUpdateRequest
    {
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public int? ImageAssetId { get; set; }
        public bool IsPublished { get; set; }
    }
}
