using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyDent.Services.Database
{
    // Not linked to User/Role — doctors don't log in, they're managed by admin staff.
    public class Doctor
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string LastName { get; set; } = string.Empty;

        [MaxLength(1000)]
        public string? Bio { get; set; }

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public int? PhotoAssetId { get; set; }

        [ForeignKey("PhotoAssetId")]
        public Asset? Photo { get; set; }

        public ICollection<DoctorSpecialty> DoctorSpecialties { get; set; } = new List<DoctorSpecialty>();
        public ICollection<DoctorWorkingHours> WorkingHours { get; set; } = new List<DoctorWorkingHours>();
        public ICollection<DoctorAbsence> Absences { get; set; } = new List<DoctorAbsence>();
        public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
    }
}
