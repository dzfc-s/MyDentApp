using Microsoft.EntityFrameworkCore;

namespace MyDent.Services.Database
{
    public partial class MyDentDbContext : DbContext
    {

        private void CreateConfiguration(ModelBuilder modelBuilder)
        {
            // Configure UserRole relationships
            modelBuilder.Entity<UserRole>()
                .HasOne(ur => ur.User)
                .WithMany(ur => ur.UserRoles)
                .HasForeignKey(ur => ur.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<UserRole>()
                .HasOne(ur => ur.Role)
                .WithMany(ur => ur.UserRoles)
                .HasForeignKey(ur => ur.RoleId)
                .OnDelete(DeleteBehavior.Cascade);

            // A user's profile picture is an Asset row, referenced by Id (not stored inline on User).
            // SetNull: deleting the Asset just clears the reference, it must not delete the User.
            modelBuilder.Entity<User>()
                .HasOne(u => u.ProfileImage)
                .WithMany()
                .HasForeignKey(u => u.ProfileImageAssetId)
                .OnDelete(DeleteBehavior.SetNull);

            // Add dental-domain model configurations here (Doctor, Patient, Service, Appointment, ...)
        }
    }
}
