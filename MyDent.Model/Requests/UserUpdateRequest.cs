using System.ComponentModel.DataAnnotations;

namespace MyDent.Model.Requests
{
    public class UserUpdateRequest
    {
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Email { get; set; }
        public string? Username { get; set; }
        public string? PhoneNumber { get; set; }
        public bool IsActive { get; set; }
        public int? ProfileImageAssetId { get; set; }
        public string? Allergies { get; set; }
        public string? BloodType { get; set; }
        public string? MedicalNotes { get; set; }
    }
}
