using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyDent.Services.Database
{
    // Reset codes are short (6-digit, emailed) rather than a clickable link — avoids needing
    // mobile deep-link handling (initial-link vs resumed-app scenarios) for a feature this small.
    // Only the hash is stored, never the raw code, per the "reset kodovi se ne smiju čuvati u
    // plain text formatu" requirement.
    public class PasswordResetToken
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(200)]
        public string CodeHash { get; set; } = string.Empty;

        public DateTime ExpiresAt { get; set; }

        public DateTime? UsedAt { get; set; }

        public DateTime CreatedAt { get; set; }

        public int UserId { get; set; }

        [ForeignKey("UserId")]
        public User User { get; set; } = null!;
    }
}
