namespace MyDent.Model.Requests
{
    public class NewsInsertRequest
    {
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public int? ImageAssetId { get; set; }
    }
}
