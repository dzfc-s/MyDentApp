using Microsoft.EntityFrameworkCore;

namespace MyDent.Services.Database
{
    public partial class MyDentDbContext : DbContext
    {
        public MyDentDbContext(DbContextOptions<MyDentDbContext> options) : base(options)
        {
        }

        // DbSets for all entities
        public DbSet<User> Users { get; set; }
        public DbSet<Role> Roles { get; set; }
        public DbSet<UserRole> UserRoles { get; set; }
        public DbSet<Asset> Assets { get; set; }
        public DbSet<RefreshToken> RefreshTokens { get; set; }
        public DbSet<PasswordResetToken> PasswordResetTokens { get; set; }

        public DbSet<ServiceCategory> ServiceCategories { get; set; }
        public DbSet<Doctor> Doctors { get; set; }
        public DbSet<DoctorSpecialty> DoctorSpecialties { get; set; }
        public DbSet<DoctorWorkingHours> DoctorWorkingHours { get; set; }
        public DbSet<DoctorAbsence> DoctorAbsences { get; set; }
        public DbSet<DentalService> DentalServices { get; set; }
        public DbSet<Appointment> Appointments { get; set; }
        public DbSet<AppointmentStatusHistory> AppointmentStatusHistories { get; set; }
        public DbSet<Review> Reviews { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<News> News { get; set; }
        public DbSet<Payment> Payments { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            CreateConfiguration(modelBuilder);

            CreateSeed(modelBuilder);
            
        }

       
    }
}
