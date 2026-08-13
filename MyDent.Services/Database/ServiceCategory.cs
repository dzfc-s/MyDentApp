using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MyDent.Services.Database
{
    // Reference/lookup table. Doubles as the "specialty" a Doctor is assigned to
    // via DoctorSpecialty, and as the category a DentalService belongs to.
    public class ServiceCategory
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(500)]
        public string Description { get; set; } = string.Empty;

        public bool IsActive { get; set; } = true;

        // Null = no recurring-checkup reminder generated for this category.
        public int? RecommendedRecallMonths { get; set; }

        public ICollection<DentalService> DentalServices { get; set; } = new List<DentalService>();
        public ICollection<DoctorSpecialty> DoctorSpecialties { get; set; } = new List<DoctorSpecialty>();
    }
}
