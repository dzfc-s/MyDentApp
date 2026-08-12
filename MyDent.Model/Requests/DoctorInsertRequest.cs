namespace MyDent.Model.Requests
{
    public class DoctorInsertRequest
    {
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string? Bio { get; set; }
        public int? PhotoAssetId { get; set; }
    }
}
