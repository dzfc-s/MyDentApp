using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyDent.Services.Database
{
    // Join entity: Doctor <-> ServiceCategory (a doctor can have more than one specialty).
    public class DoctorSpecialty
    {
        [Key]
        public int Id { get; set; }

        public int DoctorId { get; set; }

        [ForeignKey("DoctorId")]
        public Doctor Doctor { get; set; } = null!;

        public int ServiceCategoryId { get; set; }

        [ForeignKey("ServiceCategoryId")]
        public ServiceCategory ServiceCategory { get; set; } = null!;
    }
}
