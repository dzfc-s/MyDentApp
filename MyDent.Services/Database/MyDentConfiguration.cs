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

            // ServiceCategory relationships
            modelBuilder.Entity<DentalService>()
                .HasOne(s => s.ServiceCategory)
                .WithMany(c => c.DentalServices)
                .HasForeignKey(s => s.ServiceCategoryId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<DentalService>()
                .HasOne(s => s.Image)
                .WithMany()
                .HasForeignKey(s => s.ImageAssetId)
                .OnDelete(DeleteBehavior.SetNull);

            // Doctor relationships
            modelBuilder.Entity<Doctor>()
                .HasOne(d => d.Photo)
                .WithMany()
                .HasForeignKey(d => d.PhotoAssetId)
                .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<DoctorSpecialty>()
                .HasOne(ds => ds.Doctor)
                .WithMany(d => d.DoctorSpecialties)
                .HasForeignKey(ds => ds.DoctorId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<DoctorSpecialty>()
                .HasOne(ds => ds.ServiceCategory)
                .WithMany(c => c.DoctorSpecialties)
                .HasForeignKey(ds => ds.ServiceCategoryId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<DoctorWorkingHours>()
                .HasOne(wh => wh.Doctor)
                .WithMany(d => d.WorkingHours)
                .HasForeignKey(wh => wh.DoctorId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<DoctorAbsence>()
                .HasOne(a => a.Doctor)
                .WithMany(d => d.Absences)
                .HasForeignKey(a => a.DoctorId)
                .OnDelete(DeleteBehavior.Cascade);

            // Appointment relationships — every FK into User/Doctor/DentalService is
            // Restrict, both to protect appointment history from disappearing via a
            // cascade, and because SQL Server rejects multiple cascade paths into User
            // (Notification is the only FK allowed to cascade from User below).
            modelBuilder.Entity<Appointment>()
                .HasOne(a => a.Patient)
                .WithMany()
                .HasForeignKey(a => a.PatientId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Appointment>()
                .HasOne(a => a.Doctor)
                .WithMany(d => d.Appointments)
                .HasForeignKey(a => a.DoctorId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Appointment>()
                .HasOne(a => a.DentalService)
                .WithMany(s => s.Appointments)
                .HasForeignKey(a => a.DentalServiceId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Appointment>()
                .HasOne(a => a.CancelledByUser)
                .WithMany()
                .HasForeignKey(a => a.CancelledByUserId)
                .OnDelete(DeleteBehavior.Restrict);

            // AppointmentStatusHistory — audit trail, belongs to its Appointment
            modelBuilder.Entity<AppointmentStatusHistory>()
                .HasOne(h => h.Appointment)
                .WithMany(a => a.StatusHistory)
                .HasForeignKey(h => h.AppointmentId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<AppointmentStatusHistory>()
                .HasOne(h => h.ChangedByUser)
                .WithMany()
                .HasForeignKey(h => h.ChangedByUserId)
                .OnDelete(DeleteBehavior.Restrict);

            // Review — one per appointment
            modelBuilder.Entity<Review>()
                .HasOne(r => r.Appointment)
                .WithOne(a => a.Review)
                .HasForeignKey<Review>(r => r.AppointmentId)
                .OnDelete(DeleteBehavior.Cascade);

            // Payment — one per appointment; a financial record, never cascade-deleted
            modelBuilder.Entity<Payment>()
                .HasOne(p => p.Appointment)
                .WithOne(a => a.Payment)
                .HasForeignKey<Payment>(p => p.AppointmentId)
                .OnDelete(DeleteBehavior.Restrict);

            // Notification
            modelBuilder.Entity<Notification>()
                .HasOne(n => n.User)
                .WithMany()
                .HasForeignKey(n => n.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Notification>()
                .HasOne(n => n.Appointment)
                .WithMany(a => a.Notifications)
                .HasForeignKey(n => n.AppointmentId)
                .OnDelete(DeleteBehavior.SetNull);

            // News
            modelBuilder.Entity<News>()
                .HasOne(n => n.Image)
                .WithMany()
                .HasForeignKey(n => n.ImageAssetId)
                .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<News>()
                .HasOne(n => n.CreatedByUser)
                .WithMany()
                .HasForeignKey(n => n.CreatedByUserId)
                .OnDelete(DeleteBehavior.Restrict);
        }
    }
}
