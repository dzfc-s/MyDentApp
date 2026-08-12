namespace MyDent.Model.Requests
{
    public class DoctorUpdateRequest
    {
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string? Bio { get; set; }
        public bool IsActive { get; set; }
        public int? PhotoAssetId { get; set; }
    }
}
