using MyDent.Model.Enums;
using Microsoft.EntityFrameworkCore;

namespace MyDent.Services.Database
{
    public partial class MyDentDbContext : DbContext
    {
        private void CreateSeed(ModelBuilder modelBuilder)
        {
            SeedRoles(modelBuilder);
            SeedUsers(modelBuilder);
            SeedUserRoles(modelBuilder);
            SeedServiceCategories(modelBuilder);
            SeedDentalServices(modelBuilder);
            SeedDoctors(modelBuilder);
            SeedDoctorSpecialties(modelBuilder);
            SeedDoctorWorkingHours(modelBuilder);
            SeedDoctorAbsences(modelBuilder);
            SeedAppointments(modelBuilder);
            SeedAppointmentStatusHistories(modelBuilder);
            SeedReviews(modelBuilder);
            SeedNotifications(modelBuilder);
            SeedNews(modelBuilder);
            SeedPayments(modelBuilder);
        }

        private void SeedRoles(ModelBuilder modelBuilder)
        {
            // Seed Roles - deterministic Ids: 1 = Admin, 2 = Patient
            modelBuilder.Entity<Role>().HasData(
                new
                {
                    Id = 1,
                    Name = "Admin",
                    Description = "Clinic administrator/staff role with full permissions",
                    IsActive = true,
                    CreatedAt = new DateTime(2026, 3, 9, 0, 0, 0, DateTimeKind.Utc)
                },
                new
                {
                    Id = 2,
                    Name = "Patient",
                    Description = "Default patient role",
                    IsActive = true,
                    CreatedAt = new DateTime(2026, 3, 9, 0, 0, 0, DateTimeKind.Utc)
                }
            );
        }

        private void SeedUsers(ModelBuilder modelBuilder)
        {
            // Seed Users - 3 admins (Ids 1-3), 8 patients (Ids 4-11)
            modelBuilder.Entity<User>().HasData(
                new
                {
                    Id = 1,
                    FirstName = "Alice",
                    LastName = "Admin",
                    Email = "admin1@gmail.com",
                    Username = "admin1",
                    PasswordHash = "5kRBQg4Ufcx4hAknG7P9zhfLPvY=", // Test123
                    PasswordSalt = "FmvmUwPsJyRRffhNRQvbrA==",
                    IsActive = true,
                    CreatedAt = new DateTime(2026, 3, 9, 0, 0, 0, DateTimeKind.Utc),
                    LastLoginAt = (DateTime?)null,
                    PhoneNumber = (string?)null,
                    EmailNotificationsEnabled = true,
                    PushNotificationsEnabled = true
                },
                new
                {
                    Id = 2,
                    FirstName = "Bob",
                    LastName = "Admin",
                    Email = "admin2@gmail.com",
                    Username = "admin2",
                    PasswordHash = "GBoyh1WP+OMgGjqRj6vK6L1+oGc=", // Test123
                    PasswordSalt = "0AXpKx6xRp9xM42jCf/PiA==",
                    IsActive = true,
                    CreatedAt = new DateTime(2026, 3, 9, 0, 0, 0, DateTimeKind.Utc),
                    LastLoginAt = (DateTime?)null,
                    PhoneNumber = (string?)null,
                    EmailNotificationsEnabled = true,
                    PushNotificationsEnabled = true
                },
                new
                {
                    Id = 3,
                    FirstName = "Carol",
                    LastName = "Admin",
                    Email = "admin3@gmail.com",
                    Username = "admin3",
                    PasswordHash = "x6JHKCTQywdAzTcZxGWFvrKPORM=", // Test123
                    PasswordSalt = "IwhTfKQNgyqWfOlTqCDXrg==",
                    IsActive = true,
                    CreatedAt = new DateTime(2026, 3, 9, 0, 0, 0, DateTimeKind.Utc),
                    LastLoginAt = (DateTime?)null,
                    PhoneNumber = (string?)null,
                    EmailNotificationsEnabled = true,
                    PushNotificationsEnabled = true
                },
                new
                {
                    Id = 4,
                    FirstName = "Dave",
                    LastName = "Patient",
                    Email = "patient1@gmail.com",
                    Username = "patient1",
                    PasswordHash = "E0fA2/f9GZvIRRt/cgqQemG/Cog=", // Test123
                    PasswordSalt = "TiJxWTJcd7sBSiWNbhK9Vw==",
                    IsActive = true,
                    CreatedAt = new DateTime(2026, 3, 9, 0, 0, 0, DateTimeKind.Utc),
                    LastLoginAt = (DateTime?)null,
                    PhoneNumber = (string?)null,
                    EmailNotificationsEnabled = true,
                    PushNotificationsEnabled = true
                },
                new
                {
                    Id = 5,
                    FirstName = "Eve",
                    LastName = "Patient",
                    Email = "patient2@gmail.com",
                    Username = "patient2",
                    PasswordHash = "Ov4LxpWKXXV9dwMYvBgqODdzIt0=", // Test123
                    PasswordSalt = "KtWF6g7SemBqs4nVWV4Ziw==",
                    IsActive = true,
                    CreatedAt = new DateTime(2026, 3, 9, 0, 0, 0, DateTimeKind.Utc),
                    LastLoginAt = (DateTime?)null,
                    PhoneNumber = (string?)null,
                    EmailNotificationsEnabled = true,
                    PushNotificationsEnabled = true
                },
                // Bosnian-named patients, all password Test123 (freshly generated salt/hash pairs).
                new
                {
                    Id = 6,
                    FirstName = "Amila",
                    LastName = "Hasić",
                    Email = "amila.hasic@gmail.com",
                    Username = "ahasic",
                    PasswordHash = "QltLi5GKYeCHaOehVfriIIhPfG0=",
                    PasswordSalt = "HjfA2PFxZSH9zSYIKufiUA==",
                    IsActive = true,
                    CreatedAt = new DateTime(2026, 3, 10, 0, 0, 0, DateTimeKind.Utc),
                    LastLoginAt = (DateTime?)null,
                    PhoneNumber = "061111222",
                    EmailNotificationsEnabled = true,
                    PushNotificationsEnabled = true
                },
                new
                {
                    Id = 7,
                    FirstName = "Faruk",
                    LastName = "Delić",
                    Email = "faruk.delic@gmail.com",
                    Username = "fdelic",
                    PasswordHash = "V21TmB3/VulNFWlmvlYckBYSSpQ=",
                    PasswordSalt = "WPc0zv025PwK+O/0+Pj3LA==",
                    IsActive = true,
                    CreatedAt = new DateTime(2026, 3, 10, 0, 0, 0, DateTimeKind.Utc),
                    LastLoginAt = (DateTime?)null,
                    PhoneNumber = "061222333",
                    EmailNotificationsEnabled = true,
                    PushNotificationsEnabled = true
                },
                new
                {
                    Id = 8,
                    FirstName = "Selma",
                    LastName = "Kovačević",
                    Email = "selma.kovacevic@gmail.com",
                    Username = "skovacevic",
                    PasswordHash = "uSUoCV2SnmYw7COgUfoADfl2CmQ=",
                    PasswordSalt = "EzJbcNnW0M0/H6fmm3r79A==",
                    IsActive = true,
                    CreatedAt = new DateTime(2026, 3, 10, 0, 0, 0, DateTimeKind.Utc),
                    LastLoginAt = (DateTime?)null,
                    PhoneNumber = "061333444",
                    EmailNotificationsEnabled = true,
                    PushNotificationsEnabled = true
                },
                new
                {
                    Id = 9,
                    FirstName = "Nedim",
                    LastName = "Zukić",
                    Email = "nedim.zukic@gmail.com",
                    Username = "nzukic",
                    PasswordHash = "Sxcx82eS5eyS6RQdOSqrblwKi+c=",
                    PasswordSalt = "UzF2pmAXcvHgrmgwwXfhQQ==",
                    IsActive = true,
                    CreatedAt = new DateTime(2026, 3, 10, 0, 0, 0, DateTimeKind.Utc),
                    LastLoginAt = (DateTime?)null,
                    PhoneNumber = "061444555",
                    EmailNotificationsEnabled = true,
                    PushNotificationsEnabled = true
                },
                new
                {
                    Id = 10,
                    FirstName = "Emina",
                    LastName = "Šabić",
                    Email = "emina.sabic@gmail.com",
                    Username = "esabic",
                    PasswordHash = "oFdWjtfrOcx4I1FtFkL5S14dtqY=",
                    PasswordSalt = "PJWyTaDYf+uNjdKNHciOuQ==",
                    IsActive = true,
                    CreatedAt = new DateTime(2026, 3, 10, 0, 0, 0, DateTimeKind.Utc),
                    LastLoginAt = (DateTime?)null,
                    PhoneNumber = "061555666",
                    EmailNotificationsEnabled = true,
                    PushNotificationsEnabled = true
                },
                new
                {
                    Id = 11,
                    FirstName = "Haris",
                    LastName = "Kurtović",
                    Email = "haris.kurtovic@gmail.com",
                    Username = "hkurtovic",
                    PasswordHash = "wRuW4ybXsRCRf9NF+6EgFOUCEBc=",
                    PasswordSalt = "mILDpEhLR9HlSIOzqraY/A==",
                    IsActive = true,
                    CreatedAt = new DateTime(2026, 3, 10, 0, 0, 0, DateTimeKind.Utc),
                    LastLoginAt = (DateTime?)null,
                    PhoneNumber = "061666777",
                    EmailNotificationsEnabled = true,
                    PushNotificationsEnabled = true
                }
            );
        }

        private void SeedUserRoles(ModelBuilder modelBuilder)
        {
            // Map users to roles (UserRole has its own Id PK)
            // Admin role = RoleId 1, Patient role = RoleId 2
            modelBuilder.Entity<UserRole>().HasData(
                new { Id = 1, UserId = 1, RoleId = 1, DateAssigned = new DateTime(2026, 3, 9, 0, 0, 0, DateTimeKind.Utc) },
                new { Id = 2, UserId = 2, RoleId = 1, DateAssigned = new DateTime(2026, 3, 9, 0, 0, 0, DateTimeKind.Utc) },
                new { Id = 3, UserId = 3, RoleId = 1, DateAssigned = new DateTime(2026, 3, 9, 0, 0, 0, DateTimeKind.Utc) },
                new { Id = 4, UserId = 4, RoleId = 2, DateAssigned = new DateTime(2026, 3, 9, 0, 0, 0, DateTimeKind.Utc) },
                new { Id = 5, UserId = 5, RoleId = 2, DateAssigned = new DateTime(2026, 3, 9, 0, 0, 0, DateTimeKind.Utc) },
                new { Id = 6, UserId = 6, RoleId = 2, DateAssigned = new DateTime(2026, 3, 10, 0, 0, 0, DateTimeKind.Utc) },
                new { Id = 7, UserId = 7, RoleId = 2, DateAssigned = new DateTime(2026, 3, 10, 0, 0, 0, DateTimeKind.Utc) },
                new { Id = 8, UserId = 8, RoleId = 2, DateAssigned = new DateTime(2026, 3, 10, 0, 0, 0, DateTimeKind.Utc) },
                new { Id = 9, UserId = 9, RoleId = 2, DateAssigned = new DateTime(2026, 3, 10, 0, 0, 0, DateTimeKind.Utc) },
                new { Id = 10, UserId = 10, RoleId = 2, DateAssigned = new DateTime(2026, 3, 10, 0, 0, 0, DateTimeKind.Utc) },
                new { Id = 11, UserId = 11, RoleId = 2, DateAssigned = new DateTime(2026, 3, 10, 0, 0, 0, DateTimeKind.Utc) }
            );
        }

        private void SeedServiceCategories(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<ServiceCategory>().HasData(
                new { Id = 1, Name = "Opća stomatologija", Description = "Redovni pregledi, plombiranje i osnovna njega zuba.", IsActive = true, RecommendedRecallMonths = (int?)6 },
                new { Id = 2, Name = "Oralna hirurgija", Description = "Vađenje zuba i hirurški zahvati u usnoj šupljini.", IsActive = true, RecommendedRecallMonths = (int?)null },
                new { Id = 3, Name = "Ortodoncija", Description = "Aparatići i korekcija položaja zuba.", IsActive = true, RecommendedRecallMonths = (int?)2 },
                new { Id = 4, Name = "Protetika", Description = "Krunice, mostovi i nadomjesci zuba.", IsActive = true, RecommendedRecallMonths = (int?)12 },
                new { Id = 5, Name = "Estetska stomatologija", Description = "Bijeljenje zuba i estetski tretmani.", IsActive = true, RecommendedRecallMonths = (int?)null }
            );
        }

        private void SeedDentalServices(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<DentalService>().HasData(
                new { Id = 1, Name = "Pregled i konsultacije", Description = "Osnovni stomatološki pregled sa savjetovanjem.", Price = 40.00m, DurationMinutes = 30, IsActive = true, CreatedAt = new DateTime(2026, 3, 11, 0, 0, 0, DateTimeKind.Utc), ServiceCategoryId = 1, ImageAssetId = (int?)null },
                new { Id = 2, Name = "Plombiranje zuba", Description = "Sanacija karijesa kompozitnim ispunom.", Price = 80.00m, DurationMinutes = 45, IsActive = true, CreatedAt = new DateTime(2026, 3, 11, 0, 0, 0, DateTimeKind.Utc), ServiceCategoryId = 1, ImageAssetId = (int?)null },
                new { Id = 3, Name = "Vađenje zuba", Description = "Ekstrakcija zuba u lokalnoj anesteziji.", Price = 60.00m, DurationMinutes = 30, IsActive = true, CreatedAt = new DateTime(2026, 3, 11, 0, 0, 0, DateTimeKind.Utc), ServiceCategoryId = 2, ImageAssetId = (int?)null },
                new { Id = 4, Name = "Ugradnja implantata", Description = "Hirurška ugradnja zubnog implantata.", Price = 900.00m, DurationMinutes = 90, IsActive = true, CreatedAt = new DateTime(2026, 3, 11, 0, 0, 0, DateTimeKind.Utc), ServiceCategoryId = 2, ImageAssetId = (int?)null },
                new { Id = 5, Name = "Postavljanje aparatića", Description = "Ugradnja fiksnog ortodontskog aparatića.", Price = 1200.00m, DurationMinutes = 60, IsActive = true, CreatedAt = new DateTime(2026, 3, 11, 0, 0, 0, DateTimeKind.Utc), ServiceCategoryId = 3, ImageAssetId = (int?)null },
                new { Id = 6, Name = "Kontrola aparatića", Description = "Redovna kontrola i podešavanje aparatića.", Price = 50.00m, DurationMinutes = 20, IsActive = true, CreatedAt = new DateTime(2026, 3, 11, 0, 0, 0, DateTimeKind.Utc), ServiceCategoryId = 3, ImageAssetId = (int?)null },
                new { Id = 7, Name = "Izrada krunice", Description = "Izrada i postavljanje zubne krunice.", Price = 350.00m, DurationMinutes = 60, IsActive = true, CreatedAt = new DateTime(2026, 3, 11, 0, 0, 0, DateTimeKind.Utc), ServiceCategoryId = 4, ImageAssetId = (int?)null },
                new { Id = 8, Name = "Izrada mosta", Description = "Protetski most za nadomjeranje više zuba.", Price = 700.00m, DurationMinutes = 90, IsActive = true, CreatedAt = new DateTime(2026, 3, 11, 0, 0, 0, DateTimeKind.Utc), ServiceCategoryId = 4, ImageAssetId = (int?)null },
                new { Id = 9, Name = "Bijeljenje zuba", Description = "Profesionalno bijeljenje zuba u ordinaciji.", Price = 150.00m, DurationMinutes = 45, IsActive = true, CreatedAt = new DateTime(2026, 3, 11, 0, 0, 0, DateTimeKind.Utc), ServiceCategoryId = 5, ImageAssetId = (int?)null },
                new { Id = 10, Name = "Čišćenje kamenca", Description = "Uklanjanje zubnog kamenca i poliranje.", Price = 70.00m, DurationMinutes = 30, IsActive = true, CreatedAt = new DateTime(2026, 3, 11, 0, 0, 0, DateTimeKind.Utc), ServiceCategoryId = 5, ImageAssetId = (int?)null }
            );
        }

        private void SeedDoctors(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Doctor>().HasData(
                new { Id = 1, FirstName = "Amina", LastName = "Hodžić", Bio = "Specijalista opće stomatologije sa 12 godina iskustva.", IsActive = true, CreatedAt = new DateTime(2026, 3, 12, 0, 0, 0, DateTimeKind.Utc), PhotoAssetId = (int?)null },
                new { Id = 2, FirstName = "Emir", LastName = "Karić", Bio = "Specijalista oralne hirurgije, fokus na implantologiju.", IsActive = true, CreatedAt = new DateTime(2026, 3, 12, 0, 0, 0, DateTimeKind.Utc), PhotoAssetId = (int?)null },
                new { Id = 3, FirstName = "Selma", LastName = "Begić", Bio = "Ortodontkinja, radi sa djecom i odraslima.", IsActive = true, CreatedAt = new DateTime(2026, 3, 12, 0, 0, 0, DateTimeKind.Utc), PhotoAssetId = (int?)null },
                new { Id = 4, FirstName = "Adnan", LastName = "Musić", Bio = "Specijalista protetike, izrada krunica i mostova.", IsActive = true, CreatedAt = new DateTime(2026, 3, 12, 0, 0, 0, DateTimeKind.Utc), PhotoAssetId = (int?)null },
                new { Id = 5, FirstName = "Lejla", LastName = "Softić", Bio = "Doktorica opće i estetske stomatologije.", IsActive = true, CreatedAt = new DateTime(2026, 3, 12, 0, 0, 0, DateTimeKind.Utc), PhotoAssetId = (int?)null }
            );
        }

        private void SeedDoctorSpecialties(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<DoctorSpecialty>().HasData(
                new { Id = 1, DoctorId = 1, ServiceCategoryId = 1 },
                new { Id = 2, DoctorId = 2, ServiceCategoryId = 2 },
                new { Id = 3, DoctorId = 3, ServiceCategoryId = 3 },
                new { Id = 4, DoctorId = 4, ServiceCategoryId = 4 },
                new { Id = 5, DoctorId = 5, ServiceCategoryId = 5 },
                new { Id = 6, DoctorId = 5, ServiceCategoryId = 1 }
            );
        }

        private void SeedDoctorWorkingHours(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<DoctorWorkingHours>().HasData(
                // Dr. Amina Hodžić — pon-pet 08:00-16:00
                new { Id = 1, DoctorId = 1, DayOfWeek = DayOfWeek.Monday, StartTime = new TimeSpan(8, 0, 0), EndTime = new TimeSpan(16, 0, 0) },
                new { Id = 2, DoctorId = 1, DayOfWeek = DayOfWeek.Tuesday, StartTime = new TimeSpan(8, 0, 0), EndTime = new TimeSpan(16, 0, 0) },
                new { Id = 3, DoctorId = 1, DayOfWeek = DayOfWeek.Wednesday, StartTime = new TimeSpan(8, 0, 0), EndTime = new TimeSpan(16, 0, 0) },
                new { Id = 4, DoctorId = 1, DayOfWeek = DayOfWeek.Thursday, StartTime = new TimeSpan(8, 0, 0), EndTime = new TimeSpan(16, 0, 0) },
                new { Id = 5, DoctorId = 1, DayOfWeek = DayOfWeek.Friday, StartTime = new TimeSpan(8, 0, 0), EndTime = new TimeSpan(16, 0, 0) },
                // Dr. Emir Karić — pon/sri/pet 09:00-15:00
                new { Id = 6, DoctorId = 2, DayOfWeek = DayOfWeek.Monday, StartTime = new TimeSpan(9, 0, 0), EndTime = new TimeSpan(15, 0, 0) },
                new { Id = 7, DoctorId = 2, DayOfWeek = DayOfWeek.Wednesday, StartTime = new TimeSpan(9, 0, 0), EndTime = new TimeSpan(15, 0, 0) },
                new { Id = 8, DoctorId = 2, DayOfWeek = DayOfWeek.Friday, StartTime = new TimeSpan(9, 0, 0), EndTime = new TimeSpan(15, 0, 0) },
                // Dr. Selma Begić — uto/čet 10:00-18:00
                new { Id = 9, DoctorId = 3, DayOfWeek = DayOfWeek.Tuesday, StartTime = new TimeSpan(10, 0, 0), EndTime = new TimeSpan(18, 0, 0) },
                new { Id = 10, DoctorId = 3, DayOfWeek = DayOfWeek.Thursday, StartTime = new TimeSpan(10, 0, 0), EndTime = new TimeSpan(18, 0, 0) },
                // Dr. Adnan Musić — pon-čet 08:00-14:00
                new { Id = 11, DoctorId = 4, DayOfWeek = DayOfWeek.Monday, StartTime = new TimeSpan(8, 0, 0), EndTime = new TimeSpan(14, 0, 0) },
                new { Id = 12, DoctorId = 4, DayOfWeek = DayOfWeek.Tuesday, StartTime = new TimeSpan(8, 0, 0), EndTime = new TimeSpan(14, 0, 0) },
                new { Id = 13, DoctorId = 4, DayOfWeek = DayOfWeek.Wednesday, StartTime = new TimeSpan(8, 0, 0), EndTime = new TimeSpan(14, 0, 0) },
                new { Id = 14, DoctorId = 4, DayOfWeek = DayOfWeek.Thursday, StartTime = new TimeSpan(8, 0, 0), EndTime = new TimeSpan(14, 0, 0) },
                // Dr. Lejla Softić — sri-sub 09:00-17:00
                new { Id = 15, DoctorId = 5, DayOfWeek = DayOfWeek.Wednesday, StartTime = new TimeSpan(9, 0, 0), EndTime = new TimeSpan(17, 0, 0) },
                new { Id = 16, DoctorId = 5, DayOfWeek = DayOfWeek.Thursday, StartTime = new TimeSpan(9, 0, 0), EndTime = new TimeSpan(17, 0, 0) },
                new { Id = 17, DoctorId = 5, DayOfWeek = DayOfWeek.Friday, StartTime = new TimeSpan(9, 0, 0), EndTime = new TimeSpan(17, 0, 0) },
                new { Id = 18, DoctorId = 5, DayOfWeek = DayOfWeek.Saturday, StartTime = new TimeSpan(9, 0, 0), EndTime = new TimeSpan(17, 0, 0) }
            );
        }

        private void SeedDoctorAbsences(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<DoctorAbsence>().HasData(
                new { Id = 1, DoctorId = 2, StartDate = new DateOnly(2026, 9, 1), EndDate = new DateOnly(2026, 9, 10), Reason = "Godišnji odmor", CreatedAt = new DateTime(2026, 7, 1, 0, 0, 0, DateTimeKind.Utc) },
                new { Id = 2, DoctorId = 4, StartDate = new DateOnly(2026, 7, 1), EndDate = new DateOnly(2026, 7, 5), Reason = "Stručno usavršavanje", CreatedAt = new DateTime(2026, 6, 1, 0, 0, 0, DateTimeKind.Utc) }
            );
        }

        private void SeedAppointments(ModelBuilder modelBuilder)
        {
            // All in the past (before 2026-08-15) so they're safely Completed/Cancelled history —
            // no seeded Pending/Confirmed future appointments, since a hardcoded "future" date in a
            // migration would eventually become stale. Use POST /Appointments (or the
            // available-slots endpoint) to create fresh ones for testing the live booking flow.
            modelBuilder.Entity<Appointment>().HasData(
                new { Id = 1, PatientId = 4, DoctorId = 1, DentalServiceId = 1, ScheduledAt = new DateTime(2026, 1, 20, 10, 0, 0, DateTimeKind.Utc), DurationMinutes = 30, Price = 40.00m, Status = AppointmentStatus.Completed, CancellationReason = (string?)null, CancelledByUserId = (int?)null, CancelledAt = (DateTime?)null, CreatedAt = new DateTime(2026, 1, 15, 0, 0, 0, DateTimeKind.Utc), Reminder24hSentAt = (DateTime?)null, Reminder2hSentAt = (DateTime?)null },
                new { Id = 2, PatientId = 5, DoctorId = 1, DentalServiceId = 1, ScheduledAt = new DateTime(2026, 7, 10, 9, 0, 0, DateTimeKind.Utc), DurationMinutes = 30, Price = 40.00m, Status = AppointmentStatus.Completed, CancellationReason = (string?)null, CancelledByUserId = (int?)null, CancelledAt = (DateTime?)null, CreatedAt = new DateTime(2026, 7, 5, 0, 0, 0, DateTimeKind.Utc), Reminder24hSentAt = (DateTime?)null, Reminder2hSentAt = (DateTime?)null },
                new { Id = 3, PatientId = 5, DoctorId = 4, DentalServiceId = 7, ScheduledAt = new DateTime(2026, 6, 15, 11, 0, 0, DateTimeKind.Utc), DurationMinutes = 60, Price = 350.00m, Status = AppointmentStatus.Completed, CancellationReason = (string?)null, CancelledByUserId = (int?)null, CancelledAt = (DateTime?)null, CreatedAt = new DateTime(2026, 6, 10, 0, 0, 0, DateTimeKind.Utc), Reminder24hSentAt = (DateTime?)null, Reminder2hSentAt = (DateTime?)null },
                new { Id = 4, PatientId = 7, DoctorId = 5, DentalServiceId = 9, ScheduledAt = new DateTime(2026, 7, 5, 13, 0, 0, DateTimeKind.Utc), DurationMinutes = 45, Price = 150.00m, Status = AppointmentStatus.Completed, CancellationReason = (string?)null, CancelledByUserId = (int?)null, CancelledAt = (DateTime?)null, CreatedAt = new DateTime(2026, 6, 28, 0, 0, 0, DateTimeKind.Utc), Reminder24hSentAt = (DateTime?)null, Reminder2hSentAt = (DateTime?)null },
                new { Id = 5, PatientId = 7, DoctorId = 5, DentalServiceId = 10, ScheduledAt = new DateTime(2026, 7, 12, 13, 0, 0, DateTimeKind.Utc), DurationMinutes = 30, Price = 70.00m, Status = AppointmentStatus.Completed, CancellationReason = (string?)null, CancelledByUserId = (int?)null, CancelledAt = (DateTime?)null, CreatedAt = new DateTime(2026, 7, 6, 0, 0, 0, DateTimeKind.Utc), Reminder24hSentAt = (DateTime?)null, Reminder2hSentAt = (DateTime?)null },
                new { Id = 6, PatientId = 8, DoctorId = 3, DentalServiceId = 5, ScheduledAt = new DateTime(2026, 5, 10, 10, 0, 0, DateTimeKind.Utc), DurationMinutes = 60, Price = 1200.00m, Status = AppointmentStatus.Completed, CancellationReason = (string?)null, CancelledByUserId = (int?)null, CancelledAt = (DateTime?)null, CreatedAt = new DateTime(2026, 5, 1, 0, 0, 0, DateTimeKind.Utc), Reminder24hSentAt = (DateTime?)null, Reminder2hSentAt = (DateTime?)null },
                new { Id = 7, PatientId = 9, DoctorId = 2, DentalServiceId = 3, ScheduledAt = new DateTime(2026, 3, 22, 14, 0, 0, DateTimeKind.Utc), DurationMinutes = 30, Price = 60.00m, Status = AppointmentStatus.Completed, CancellationReason = (string?)null, CancelledByUserId = (int?)null, CancelledAt = (DateTime?)null, CreatedAt = new DateTime(2026, 3, 18, 0, 0, 0, DateTimeKind.Utc), Reminder24hSentAt = (DateTime?)null, Reminder2hSentAt = (DateTime?)null },
                new { Id = 8, PatientId = 9, DoctorId = 1, DentalServiceId = 2, ScheduledAt = new DateTime(2026, 4, 18, 9, 30, 0, DateTimeKind.Utc), DurationMinutes = 45, Price = 80.00m, Status = AppointmentStatus.Completed, CancellationReason = (string?)null, CancelledByUserId = (int?)null, CancelledAt = (DateTime?)null, CreatedAt = new DateTime(2026, 4, 14, 0, 0, 0, DateTimeKind.Utc), Reminder24hSentAt = (DateTime?)null, Reminder2hSentAt = (DateTime?)null },
                new { Id = 9, PatientId = 10, DoctorId = 2, DentalServiceId = 3, ScheduledAt = new DateTime(2026, 4, 1, 10, 0, 0, DateTimeKind.Utc), DurationMinutes = 30, Price = 60.00m, Status = AppointmentStatus.Cancelled, CancellationReason = "Pacijent otkazao termin.", CancelledByUserId = (int?)10, CancelledAt = new DateTime(2026, 3, 30, 18, 0, 0, DateTimeKind.Utc), CreatedAt = new DateTime(2026, 3, 25, 0, 0, 0, DateTimeKind.Utc), Reminder24hSentAt = (DateTime?)null, Reminder2hSentAt = (DateTime?)null },
                new { Id = 10, PatientId = 4, DoctorId = 4, DentalServiceId = 8, ScheduledAt = new DateTime(2026, 2, 14, 15, 0, 0, DateTimeKind.Utc), DurationMinutes = 90, Price = 700.00m, Status = AppointmentStatus.Completed, CancellationReason = (string?)null, CancelledByUserId = (int?)null, CancelledAt = (DateTime?)null, CreatedAt = new DateTime(2026, 2, 8, 0, 0, 0, DateTimeKind.Utc), Reminder24hSentAt = (DateTime?)null, Reminder2hSentAt = (DateTime?)null },
                new { Id = 11, PatientId = 11, DoctorId = 1, DentalServiceId = 1, ScheduledAt = new DateTime(2026, 7, 25, 11, 0, 0, DateTimeKind.Utc), DurationMinutes = 30, Price = 40.00m, Status = AppointmentStatus.Completed, CancellationReason = (string?)null, CancelledByUserId = (int?)null, CancelledAt = (DateTime?)null, CreatedAt = new DateTime(2026, 7, 20, 0, 0, 0, DateTimeKind.Utc), Reminder24hSentAt = (DateTime?)null, Reminder2hSentAt = (DateTime?)null }
            );
        }

        private void SeedAppointmentStatusHistories(ModelBuilder modelBuilder)
        {
            // One row per seeded appointment covering its final transition — Admin (Alice, Id 1)
            // performed all Confirm/Complete actions, the patient herself cancelled Id 9.
            modelBuilder.Entity<AppointmentStatusHistory>().HasData(
                new { Id = 1, AppointmentId = 1, FromStatus = AppointmentStatus.Confirmed, ToStatus = AppointmentStatus.Completed, ChangedByUserId = 1, Reason = (string?)null, ChangedAt = new DateTime(2026, 1, 20, 10, 30, 0, DateTimeKind.Utc) },
                new { Id = 2, AppointmentId = 2, FromStatus = AppointmentStatus.Confirmed, ToStatus = AppointmentStatus.Completed, ChangedByUserId = 1, Reason = (string?)null, ChangedAt = new DateTime(2026, 7, 10, 9, 30, 0, DateTimeKind.Utc) },
                new { Id = 3, AppointmentId = 3, FromStatus = AppointmentStatus.Confirmed, ToStatus = AppointmentStatus.Completed, ChangedByUserId = 1, Reason = (string?)null, ChangedAt = new DateTime(2026, 6, 15, 12, 0, 0, DateTimeKind.Utc) },
                new { Id = 4, AppointmentId = 4, FromStatus = AppointmentStatus.Confirmed, ToStatus = AppointmentStatus.Completed, ChangedByUserId = 1, Reason = (string?)null, ChangedAt = new DateTime(2026, 7, 5, 13, 45, 0, DateTimeKind.Utc) },
                new { Id = 5, AppointmentId = 5, FromStatus = AppointmentStatus.Confirmed, ToStatus = AppointmentStatus.Completed, ChangedByUserId = 1, Reason = (string?)null, ChangedAt = new DateTime(2026, 7, 12, 13, 30, 0, DateTimeKind.Utc) },
                new { Id = 6, AppointmentId = 6, FromStatus = AppointmentStatus.Confirmed, ToStatus = AppointmentStatus.Completed, ChangedByUserId = 1, Reason = (string?)null, ChangedAt = new DateTime(2026, 5, 10, 11, 0, 0, DateTimeKind.Utc) },
                new { Id = 7, AppointmentId = 7, FromStatus = AppointmentStatus.Confirmed, ToStatus = AppointmentStatus.Completed, ChangedByUserId = 1, Reason = (string?)null, ChangedAt = new DateTime(2026, 3, 22, 14, 30, 0, DateTimeKind.Utc) },
                new { Id = 8, AppointmentId = 8, FromStatus = AppointmentStatus.Confirmed, ToStatus = AppointmentStatus.Completed, ChangedByUserId = 1, Reason = (string?)null, ChangedAt = new DateTime(2026, 4, 18, 10, 15, 0, DateTimeKind.Utc) },
                new { Id = 9, AppointmentId = 9, FromStatus = AppointmentStatus.Pending, ToStatus = AppointmentStatus.Cancelled, ChangedByUserId = 10, Reason = "Pacijent otkazao termin.", ChangedAt = new DateTime(2026, 3, 30, 18, 0, 0, DateTimeKind.Utc) },
                new { Id = 10, AppointmentId = 10, FromStatus = AppointmentStatus.Confirmed, ToStatus = AppointmentStatus.Completed, ChangedByUserId = 1, Reason = (string?)null, ChangedAt = new DateTime(2026, 2, 14, 16, 30, 0, DateTimeKind.Utc) },
                new { Id = 11, AppointmentId = 11, FromStatus = AppointmentStatus.Confirmed, ToStatus = AppointmentStatus.Completed, ChangedByUserId = 1, Reason = (string?)null, ChangedAt = new DateTime(2026, 7, 25, 11, 30, 0, DateTimeKind.Utc) }
            );
        }

        private void SeedReviews(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Review>().HasData(
                new { Id = 1, AppointmentId = 1, Rating = 5, Comment = "Odličan pregled, doktorica je bila vrlo profesionalna.", IsApproved = true, CreatedAt = new DateTime(2026, 1, 21, 0, 0, 0, DateTimeKind.Utc) },
                new { Id = 2, AppointmentId = 4, Rating = 4, Comment = "Zadovoljan sam rezultatom bijeljenja.", IsApproved = true, CreatedAt = new DateTime(2026, 7, 6, 0, 0, 0, DateTimeKind.Utc) },
                new { Id = 3, AppointmentId = 5, Rating = 3, Comment = "Uredu, mogla je usluga biti malo brža.", IsApproved = false, CreatedAt = new DateTime(2026, 7, 13, 0, 0, 0, DateTimeKind.Utc) },
                new { Id = 4, AppointmentId = 6, Rating = 5, Comment = "Vrlo zadovoljna, doktorica Selma je fantastična sa pacijentima.", IsApproved = true, CreatedAt = new DateTime(2026, 5, 11, 0, 0, 0, DateTimeKind.Utc) }
            );
        }

        private void SeedNotifications(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Notification>().HasData(
                new { Id = 1, UserId = 4, Title = "Termin potvrđen", Message = "Vaš termin zakazan za 20.01.2026. u 10:00 je potvrđen.", Type = NotificationType.AppointmentConfirmed, IsRead = true, AppointmentId = (int?)1, ServiceCategoryId = (int?)null, CreatedAt = new DateTime(2026, 1, 18, 0, 0, 0, DateTimeKind.Utc) },
                new { Id = 2, UserId = 4, Title = "Vrijeme je za kontrolu", Message = "Preporučujemo da zakažete termin za \"Opća stomatologija\" — prošlo je 6 mjeseci od zadnje posjete.", Type = NotificationType.RecurringServiceReminder, IsRead = false, AppointmentId = (int?)null, ServiceCategoryId = (int?)1, CreatedAt = new DateTime(2026, 7, 25, 0, 0, 0, DateTimeKind.Utc) },
                new { Id = 3, UserId = 10, Title = "Termin otkazan", Message = "Vaš termin zakazan za 01.04.2026. u 10:00 je otkazan. Razlog: Pacijent otkazao termin.", Type = NotificationType.AppointmentCancelled, IsRead = true, AppointmentId = (int?)9, ServiceCategoryId = (int?)null, CreatedAt = new DateTime(2026, 3, 30, 18, 5, 0, DateTimeKind.Utc) },
                new { Id = 4, UserId = 8, Title = "Vrijeme je za kontrolu", Message = "Preporučujemo da zakažete termin za \"Ortodoncija\" — prošlo je 2 mjeseca od zadnje posjete.", Type = NotificationType.RecurringServiceReminder, IsRead = false, AppointmentId = (int?)null, ServiceCategoryId = (int?)3, CreatedAt = new DateTime(2026, 7, 12, 0, 0, 0, DateTimeKind.Utc) },
                new { Id = 5, UserId = 5, Title = "Termin potvrđen", Message = "Vaš termin zakazan za 10.07.2026. u 09:00 je potvrđen.", Type = NotificationType.AppointmentConfirmed, IsRead = true, AppointmentId = (int?)2, ServiceCategoryId = (int?)null, CreatedAt = new DateTime(2026, 7, 8, 0, 0, 0, DateTimeKind.Utc) },
                new { Id = 6, UserId = 7, Title = "Termin potvrđen", Message = "Vaš termin zakazan za 05.07.2026. u 13:00 je potvrđen.", Type = NotificationType.AppointmentConfirmed, IsRead = false, AppointmentId = (int?)4, ServiceCategoryId = (int?)null, CreatedAt = new DateTime(2026, 7, 2, 0, 0, 0, DateTimeKind.Utc) }
            );
        }

        private void SeedNews(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<News>().HasData(
                new { Id = 1, Title = "Nova ordinacija otvorena u centru grada", Content = "Sa zadovoljstvom najavljujemo otvaranje naše nove, moderno opremljene ordinacije u centru grada. Dobrodošli!", ImageAssetId = (int?)null, IsPublished = true, PublishedAt = new DateTime(2026, 4, 1, 9, 0, 0, DateTimeKind.Utc), CreatedAt = new DateTime(2026, 4, 1, 9, 0, 0, DateTimeKind.Utc), CreatedByUserId = 1 },
                new { Id = 2, Title = "Akcija: besplatan pregled za nove pacijente", Content = "Tokom mjeseca maja, svi novi pacijenti imaju pravo na besplatan prvi pregled i konsultaciju.", ImageAssetId = (int?)null, IsPublished = true, PublishedAt = new DateTime(2026, 5, 2, 9, 0, 0, DateTimeKind.Utc), CreatedAt = new DateTime(2026, 5, 2, 9, 0, 0, DateTimeKind.Utc), CreatedByUserId = 1 },
                new { Id = 3, Title = "Radno vrijeme tokom praznika", Content = "Obavještavamo pacijente da ordinacija za vrijeme predstojećih praznika radi po skraćenom radnom vremenu.", ImageAssetId = (int?)null, IsPublished = true, PublishedAt = new DateTime(2026, 6, 20, 9, 0, 0, DateTimeKind.Utc), CreatedAt = new DateTime(2026, 6, 20, 9, 0, 0, DateTimeKind.Utc), CreatedByUserId = 2 },
                new { Id = 4, Title = "Uvodimo online zakazivanje termina", Content = "Od sada možete zakazati svoj termin direktno putem mobilne aplikacije, bez potrebe za pozivom.", ImageAssetId = (int?)null, IsPublished = true, PublishedAt = new DateTime(2026, 7, 15, 9, 0, 0, DateTimeKind.Utc), CreatedAt = new DateTime(2026, 7, 15, 9, 0, 0, DateTimeKind.Utc), CreatedByUserId = 1 },
                // Draft, not yet published — for testing that GetAll hides unpublished News from non-admins.
                new { Id = 5, Title = "Najava novog seminara o njezi zuba", Content = "Priprema se javni seminar o pravilnoj njezi zubi za djecu — detalji uskoro.", ImageAssetId = (int?)null, IsPublished = false, PublishedAt = new DateTime(2026, 8, 10, 9, 0, 0, DateTimeKind.Utc), CreatedAt = new DateTime(2026, 8, 10, 9, 0, 0, DateTimeKind.Utc), CreatedByUserId = 3 }
            );
        }

        private void SeedPayments(ModelBuilder modelBuilder)
        {
            // ProviderTransactionId values here are placeholders, not real Stripe PaymentIntent
            // ids — fine for exercising GetAll/GetById/filtering, but calling the real
            // /Payments/{id}/refund action against one of these will fail against Stripe's API
            // since it doesn't recognize a "pi_seed_..." id.
            modelBuilder.Entity<Payment>().HasData(
                new { Id = 1, AppointmentId = 1, Amount = 40.00m, Status = PaymentStatus.Paid, ProviderTransactionId = "pi_seed_0001", PaidAt = (DateTime?)new DateTime(2026, 1, 20, 10, 5, 0, DateTimeKind.Utc), RefundedAmount = (decimal?)null, RefundedAt = (DateTime?)null, CreatedAt = new DateTime(2026, 1, 20, 10, 0, 0, DateTimeKind.Utc) },
                new { Id = 2, AppointmentId = 6, Amount = 1200.00m, Status = PaymentStatus.Paid, ProviderTransactionId = "pi_seed_0002", PaidAt = (DateTime?)new DateTime(2026, 5, 10, 10, 5, 0, DateTimeKind.Utc), RefundedAmount = (decimal?)null, RefundedAt = (DateTime?)null, CreatedAt = new DateTime(2026, 5, 10, 10, 0, 0, DateTimeKind.Utc) },
                new { Id = 3, AppointmentId = 3, Amount = 350.00m, Status = PaymentStatus.Paid, ProviderTransactionId = "pi_seed_0003", PaidAt = (DateTime?)new DateTime(2026, 6, 15, 11, 5, 0, DateTimeKind.Utc), RefundedAmount = (decimal?)null, RefundedAt = (DateTime?)null, CreatedAt = new DateTime(2026, 6, 15, 11, 0, 0, DateTimeKind.Utc) }
            );
        }
    }
}
