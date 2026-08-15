using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace MyDent.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddComprehensiveSeedData : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "Doctors",
                columns: new[] { "Id", "Bio", "CreatedAt", "FirstName", "IsActive", "LastName", "PhotoAssetId" },
                values: new object[,]
                {
                    { 1, "Specijalista opće stomatologije sa 12 godina iskustva.", new DateTime(2026, 3, 12, 0, 0, 0, 0, DateTimeKind.Utc), "Amina", true, "Hodžić", null },
                    { 2, "Specijalista oralne hirurgije, fokus na implantologiju.", new DateTime(2026, 3, 12, 0, 0, 0, 0, DateTimeKind.Utc), "Emir", true, "Karić", null },
                    { 3, "Ortodontkinja, radi sa djecom i odraslima.", new DateTime(2026, 3, 12, 0, 0, 0, 0, DateTimeKind.Utc), "Selma", true, "Begić", null },
                    { 4, "Specijalista protetike, izrada krunica i mostova.", new DateTime(2026, 3, 12, 0, 0, 0, 0, DateTimeKind.Utc), "Adnan", true, "Musić", null },
                    { 5, "Doktorica opće i estetske stomatologije.", new DateTime(2026, 3, 12, 0, 0, 0, 0, DateTimeKind.Utc), "Lejla", true, "Softić", null }
                });

            migrationBuilder.InsertData(
                table: "News",
                columns: new[] { "Id", "Content", "CreatedAt", "CreatedByUserId", "ImageAssetId", "IsPublished", "PublishedAt", "Title" },
                values: new object[,]
                {
                    { 1, "Sa zadovoljstvom najavljujemo otvaranje naše nove, moderno opremljene ordinacije u centru grada. Dobrodošli!", new DateTime(2026, 4, 1, 9, 0, 0, 0, DateTimeKind.Utc), 1, null, true, new DateTime(2026, 4, 1, 9, 0, 0, 0, DateTimeKind.Utc), "Nova ordinacija otvorena u centru grada" },
                    { 2, "Tokom mjeseca maja, svi novi pacijenti imaju pravo na besplatan prvi pregled i konsultaciju.", new DateTime(2026, 5, 2, 9, 0, 0, 0, DateTimeKind.Utc), 1, null, true, new DateTime(2026, 5, 2, 9, 0, 0, 0, DateTimeKind.Utc), "Akcija: besplatan pregled za nove pacijente" },
                    { 3, "Obavještavamo pacijente da ordinacija za vrijeme predstojećih praznika radi po skraćenom radnom vremenu.", new DateTime(2026, 6, 20, 9, 0, 0, 0, DateTimeKind.Utc), 2, null, true, new DateTime(2026, 6, 20, 9, 0, 0, 0, DateTimeKind.Utc), "Radno vrijeme tokom praznika" },
                    { 4, "Od sada možete zakazati svoj termin direktno putem mobilne aplikacije, bez potrebe za pozivom.", new DateTime(2026, 7, 15, 9, 0, 0, 0, DateTimeKind.Utc), 1, null, true, new DateTime(2026, 7, 15, 9, 0, 0, 0, DateTimeKind.Utc), "Uvodimo online zakazivanje termina" },
                    { 5, "Priprema se javni seminar o pravilnoj njezi zubi za djecu — detalji uskoro.", new DateTime(2026, 8, 10, 9, 0, 0, 0, DateTimeKind.Utc), 3, null, false, new DateTime(2026, 8, 10, 9, 0, 0, 0, DateTimeKind.Utc), "Najava novog seminara o njezi zuba" }
                });

            migrationBuilder.InsertData(
                table: "ServiceCategories",
                columns: new[] { "Id", "Description", "IsActive", "Name", "RecommendedRecallMonths" },
                values: new object[,]
                {
                    { 1, "Redovni pregledi, plombiranje i osnovna njega zuba.", true, "Opća stomatologija", 6 },
                    { 2, "Vađenje zuba i hirurški zahvati u usnoj šupljini.", true, "Oralna hirurgija", null },
                    { 3, "Aparatići i korekcija položaja zuba.", true, "Ortodoncija", 2 },
                    { 4, "Krunice, mostovi i nadomjesci zuba.", true, "Protetika", 12 },
                    { 5, "Bijeljenje zuba i estetski tretmani.", true, "Estetska stomatologija", null }
                });

            migrationBuilder.InsertData(
                table: "Users",
                columns: new[] { "Id", "CreatedAt", "Email", "EmailNotificationsEnabled", "FirstName", "IsActive", "LastLoginAt", "LastName", "PasswordHash", "PasswordSalt", "PhoneNumber", "ProfileImageAssetId", "PushNotificationsEnabled", "Username" },
                values: new object[,]
                {
                    { 6, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), "amila.hasic@gmail.com", true, "Amila", true, null, "Hasić", "QltLi5GKYeCHaOehVfriIIhPfG0=", "HjfA2PFxZSH9zSYIKufiUA==", "061111222", null, true, "ahasic" },
                    { 7, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), "faruk.delic@gmail.com", true, "Faruk", true, null, "Delić", "V21TmB3/VulNFWlmvlYckBYSSpQ=", "WPc0zv025PwK+O/0+Pj3LA==", "061222333", null, true, "fdelic" },
                    { 8, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), "selma.kovacevic@gmail.com", true, "Selma", true, null, "Kovačević", "uSUoCV2SnmYw7COgUfoADfl2CmQ=", "EzJbcNnW0M0/H6fmm3r79A==", "061333444", null, true, "skovacevic" },
                    { 9, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), "nedim.zukic@gmail.com", true, "Nedim", true, null, "Zukić", "Sxcx82eS5eyS6RQdOSqrblwKi+c=", "UzF2pmAXcvHgrmgwwXfhQQ==", "061444555", null, true, "nzukic" },
                    { 10, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), "emina.sabic@gmail.com", true, "Emina", true, null, "Šabić", "oFdWjtfrOcx4I1FtFkL5S14dtqY=", "PJWyTaDYf+uNjdKNHciOuQ==", "061555666", null, true, "esabic" },
                    { 11, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), "haris.kurtovic@gmail.com", true, "Haris", true, null, "Kurtović", "wRuW4ybXsRCRf9NF+6EgFOUCEBc=", "mILDpEhLR9HlSIOzqraY/A==", "061666777", null, true, "hkurtovic" }
                });

            migrationBuilder.InsertData(
                table: "DentalServices",
                columns: new[] { "Id", "CreatedAt", "Description", "DurationMinutes", "ImageAssetId", "IsActive", "Name", "Price", "ServiceCategoryId" },
                values: new object[,]
                {
                    { 1, new DateTime(2026, 3, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Osnovni stomatološki pregled sa savjetovanjem.", 30, null, true, "Pregled i konsultacije", 40.00m, 1 },
                    { 2, new DateTime(2026, 3, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Sanacija karijesa kompozitnim ispunom.", 45, null, true, "Plombiranje zuba", 80.00m, 1 },
                    { 3, new DateTime(2026, 3, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Ekstrakcija zuba u lokalnoj anesteziji.", 30, null, true, "Vađenje zuba", 60.00m, 2 },
                    { 4, new DateTime(2026, 3, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Hirurška ugradnja zubnog implantata.", 90, null, true, "Ugradnja implantata", 900.00m, 2 },
                    { 5, new DateTime(2026, 3, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Ugradnja fiksnog ortodontskog aparatića.", 60, null, true, "Postavljanje aparatića", 1200.00m, 3 },
                    { 6, new DateTime(2026, 3, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Redovna kontrola i podešavanje aparatića.", 20, null, true, "Kontrola aparatića", 50.00m, 3 },
                    { 7, new DateTime(2026, 3, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Izrada i postavljanje zubne krunice.", 60, null, true, "Izrada krunice", 350.00m, 4 },
                    { 8, new DateTime(2026, 3, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Protetski most za nadomjeranje više zuba.", 90, null, true, "Izrada mosta", 700.00m, 4 },
                    { 9, new DateTime(2026, 3, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Profesionalno bijeljenje zuba u ordinaciji.", 45, null, true, "Bijeljenje zuba", 150.00m, 5 },
                    { 10, new DateTime(2026, 3, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Uklanjanje zubnog kamenca i poliranje.", 30, null, true, "Čišćenje kamenca", 70.00m, 5 }
                });

            migrationBuilder.InsertData(
                table: "DoctorAbsences",
                columns: new[] { "Id", "CreatedAt", "DoctorId", "EndDate", "Reason", "StartDate" },
                values: new object[,]
                {
                    { 1, new DateTime(2026, 7, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2, new DateOnly(2026, 9, 10), "Godišnji odmor", new DateOnly(2026, 9, 1) },
                    { 2, new DateTime(2026, 6, 1, 0, 0, 0, 0, DateTimeKind.Utc), 4, new DateOnly(2026, 7, 5), "Stručno usavršavanje", new DateOnly(2026, 7, 1) }
                });

            migrationBuilder.InsertData(
                table: "DoctorSpecialties",
                columns: new[] { "Id", "DoctorId", "ServiceCategoryId" },
                values: new object[,]
                {
                    { 1, 1, 1 },
                    { 2, 2, 2 },
                    { 3, 3, 3 },
                    { 4, 4, 4 },
                    { 5, 5, 5 },
                    { 6, 5, 1 }
                });

            migrationBuilder.InsertData(
                table: "DoctorWorkingHours",
                columns: new[] { "Id", "DayOfWeek", "DoctorId", "EndTime", "StartTime" },
                values: new object[,]
                {
                    { 1, 1, 1, new TimeSpan(0, 16, 0, 0, 0), new TimeSpan(0, 8, 0, 0, 0) },
                    { 2, 2, 1, new TimeSpan(0, 16, 0, 0, 0), new TimeSpan(0, 8, 0, 0, 0) },
                    { 3, 3, 1, new TimeSpan(0, 16, 0, 0, 0), new TimeSpan(0, 8, 0, 0, 0) },
                    { 4, 4, 1, new TimeSpan(0, 16, 0, 0, 0), new TimeSpan(0, 8, 0, 0, 0) },
                    { 5, 5, 1, new TimeSpan(0, 16, 0, 0, 0), new TimeSpan(0, 8, 0, 0, 0) },
                    { 6, 1, 2, new TimeSpan(0, 15, 0, 0, 0), new TimeSpan(0, 9, 0, 0, 0) },
                    { 7, 3, 2, new TimeSpan(0, 15, 0, 0, 0), new TimeSpan(0, 9, 0, 0, 0) },
                    { 8, 5, 2, new TimeSpan(0, 15, 0, 0, 0), new TimeSpan(0, 9, 0, 0, 0) },
                    { 9, 2, 3, new TimeSpan(0, 18, 0, 0, 0), new TimeSpan(0, 10, 0, 0, 0) },
                    { 10, 4, 3, new TimeSpan(0, 18, 0, 0, 0), new TimeSpan(0, 10, 0, 0, 0) },
                    { 11, 1, 4, new TimeSpan(0, 14, 0, 0, 0), new TimeSpan(0, 8, 0, 0, 0) },
                    { 12, 2, 4, new TimeSpan(0, 14, 0, 0, 0), new TimeSpan(0, 8, 0, 0, 0) },
                    { 13, 3, 4, new TimeSpan(0, 14, 0, 0, 0), new TimeSpan(0, 8, 0, 0, 0) },
                    { 14, 4, 4, new TimeSpan(0, 14, 0, 0, 0), new TimeSpan(0, 8, 0, 0, 0) },
                    { 15, 3, 5, new TimeSpan(0, 17, 0, 0, 0), new TimeSpan(0, 9, 0, 0, 0) },
                    { 16, 4, 5, new TimeSpan(0, 17, 0, 0, 0), new TimeSpan(0, 9, 0, 0, 0) },
                    { 17, 5, 5, new TimeSpan(0, 17, 0, 0, 0), new TimeSpan(0, 9, 0, 0, 0) },
                    { 18, 6, 5, new TimeSpan(0, 17, 0, 0, 0), new TimeSpan(0, 9, 0, 0, 0) }
                });

            migrationBuilder.InsertData(
                table: "Notifications",
                columns: new[] { "Id", "AppointmentId", "CreatedAt", "IsRead", "Message", "ServiceCategoryId", "Title", "Type", "UserId" },
                values: new object[,]
                {
                    { 2, null, new DateTime(2026, 7, 25, 0, 0, 0, 0, DateTimeKind.Utc), false, "Preporučujemo da zakažete termin za \"Opća stomatologija\" — prošlo je 6 mjeseci od zadnje posjete.", 1, "Vrijeme je za kontrolu", 4, 4 },
                    { 4, null, new DateTime(2026, 7, 12, 0, 0, 0, 0, DateTimeKind.Utc), false, "Preporučujemo da zakažete termin za \"Ortodoncija\" — prošlo je 2 mjeseca od zadnje posjete.", 3, "Vrijeme je za kontrolu", 4, 8 }
                });

            migrationBuilder.InsertData(
                table: "UserRoles",
                columns: new[] { "Id", "DateAssigned", "RoleId", "UserId" },
                values: new object[,]
                {
                    { 6, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), 2, 6 },
                    { 7, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), 2, 7 },
                    { 8, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), 2, 8 },
                    { 9, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), 2, 9 },
                    { 10, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), 2, 10 },
                    { 11, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), 2, 11 }
                });

            migrationBuilder.InsertData(
                table: "Appointments",
                columns: new[] { "Id", "CancellationReason", "CancelledAt", "CancelledByUserId", "CreatedAt", "DentalServiceId", "DoctorId", "DurationMinutes", "PatientId", "Price", "Reminder24hSentAt", "Reminder2hSentAt", "ScheduledAt", "Status" },
                values: new object[,]
                {
                    { 1, null, null, null, new DateTime(2026, 1, 15, 0, 0, 0, 0, DateTimeKind.Utc), 1, 1, 30, 4, 40.00m, null, null, new DateTime(2026, 1, 20, 10, 0, 0, 0, DateTimeKind.Utc), 3 },
                    { 2, null, null, null, new DateTime(2026, 7, 5, 0, 0, 0, 0, DateTimeKind.Utc), 1, 1, 30, 5, 40.00m, null, null, new DateTime(2026, 7, 10, 9, 0, 0, 0, DateTimeKind.Utc), 3 },
                    { 3, null, null, null, new DateTime(2026, 6, 10, 0, 0, 0, 0, DateTimeKind.Utc), 7, 4, 60, 5, 350.00m, null, null, new DateTime(2026, 6, 15, 11, 0, 0, 0, DateTimeKind.Utc), 3 },
                    { 4, null, null, null, new DateTime(2026, 6, 28, 0, 0, 0, 0, DateTimeKind.Utc), 9, 5, 45, 7, 150.00m, null, null, new DateTime(2026, 7, 5, 13, 0, 0, 0, DateTimeKind.Utc), 3 },
                    { 5, null, null, null, new DateTime(2026, 7, 6, 0, 0, 0, 0, DateTimeKind.Utc), 10, 5, 30, 7, 70.00m, null, null, new DateTime(2026, 7, 12, 13, 0, 0, 0, DateTimeKind.Utc), 3 },
                    { 6, null, null, null, new DateTime(2026, 5, 1, 0, 0, 0, 0, DateTimeKind.Utc), 5, 3, 60, 8, 1200.00m, null, null, new DateTime(2026, 5, 10, 10, 0, 0, 0, DateTimeKind.Utc), 3 },
                    { 7, null, null, null, new DateTime(2026, 3, 18, 0, 0, 0, 0, DateTimeKind.Utc), 3, 2, 30, 9, 60.00m, null, null, new DateTime(2026, 3, 22, 14, 0, 0, 0, DateTimeKind.Utc), 3 },
                    { 8, null, null, null, new DateTime(2026, 4, 14, 0, 0, 0, 0, DateTimeKind.Utc), 2, 1, 45, 9, 80.00m, null, null, new DateTime(2026, 4, 18, 9, 30, 0, 0, DateTimeKind.Utc), 3 },
                    { 9, "Pacijent otkazao termin.", new DateTime(2026, 3, 30, 18, 0, 0, 0, DateTimeKind.Utc), 10, new DateTime(2026, 3, 25, 0, 0, 0, 0, DateTimeKind.Utc), 3, 2, 30, 10, 60.00m, null, null, new DateTime(2026, 4, 1, 10, 0, 0, 0, DateTimeKind.Utc), 2 },
                    { 10, null, null, null, new DateTime(2026, 2, 8, 0, 0, 0, 0, DateTimeKind.Utc), 8, 4, 90, 4, 700.00m, null, null, new DateTime(2026, 2, 14, 15, 0, 0, 0, DateTimeKind.Utc), 3 },
                    { 11, null, null, null, new DateTime(2026, 7, 20, 0, 0, 0, 0, DateTimeKind.Utc), 1, 1, 30, 11, 40.00m, null, null, new DateTime(2026, 7, 25, 11, 0, 0, 0, DateTimeKind.Utc), 3 }
                });

            migrationBuilder.InsertData(
                table: "AppointmentStatusHistories",
                columns: new[] { "Id", "AppointmentId", "ChangedAt", "ChangedByUserId", "FromStatus", "Reason", "ToStatus" },
                values: new object[,]
                {
                    { 1, 1, new DateTime(2026, 1, 20, 10, 30, 0, 0, DateTimeKind.Utc), 1, 1, null, 3 },
                    { 2, 2, new DateTime(2026, 7, 10, 9, 30, 0, 0, DateTimeKind.Utc), 1, 1, null, 3 },
                    { 3, 3, new DateTime(2026, 6, 15, 12, 0, 0, 0, DateTimeKind.Utc), 1, 1, null, 3 },
                    { 4, 4, new DateTime(2026, 7, 5, 13, 45, 0, 0, DateTimeKind.Utc), 1, 1, null, 3 },
                    { 5, 5, new DateTime(2026, 7, 12, 13, 30, 0, 0, DateTimeKind.Utc), 1, 1, null, 3 },
                    { 6, 6, new DateTime(2026, 5, 10, 11, 0, 0, 0, DateTimeKind.Utc), 1, 1, null, 3 },
                    { 7, 7, new DateTime(2026, 3, 22, 14, 30, 0, 0, DateTimeKind.Utc), 1, 1, null, 3 },
                    { 8, 8, new DateTime(2026, 4, 18, 10, 15, 0, 0, DateTimeKind.Utc), 1, 1, null, 3 },
                    { 9, 9, new DateTime(2026, 3, 30, 18, 0, 0, 0, DateTimeKind.Utc), 10, 0, "Pacijent otkazao termin.", 2 },
                    { 10, 10, new DateTime(2026, 2, 14, 16, 30, 0, 0, DateTimeKind.Utc), 1, 1, null, 3 },
                    { 11, 11, new DateTime(2026, 7, 25, 11, 30, 0, 0, DateTimeKind.Utc), 1, 1, null, 3 }
                });

            migrationBuilder.InsertData(
                table: "Notifications",
                columns: new[] { "Id", "AppointmentId", "CreatedAt", "IsRead", "Message", "ServiceCategoryId", "Title", "Type", "UserId" },
                values: new object[,]
                {
                    { 1, 1, new DateTime(2026, 1, 18, 0, 0, 0, 0, DateTimeKind.Utc), true, "Vaš termin zakazan za 20.01.2026. u 10:00 je potvrđen.", null, "Termin potvrđen", 1, 4 },
                    { 3, 9, new DateTime(2026, 3, 30, 18, 5, 0, 0, DateTimeKind.Utc), true, "Vaš termin zakazan za 01.04.2026. u 10:00 je otkazan. Razlog: Pacijent otkazao termin.", null, "Termin otkazan", 2, 10 },
                    { 5, 2, new DateTime(2026, 7, 8, 0, 0, 0, 0, DateTimeKind.Utc), true, "Vaš termin zakazan za 10.07.2026. u 09:00 je potvrđen.", null, "Termin potvrđen", 1, 5 },
                    { 6, 4, new DateTime(2026, 7, 2, 0, 0, 0, 0, DateTimeKind.Utc), false, "Vaš termin zakazan za 05.07.2026. u 13:00 je potvrđen.", null, "Termin potvrđen", 1, 7 }
                });

            migrationBuilder.InsertData(
                table: "Payments",
                columns: new[] { "Id", "Amount", "AppointmentId", "CreatedAt", "PaidAt", "ProviderTransactionId", "RefundedAmount", "RefundedAt", "Status" },
                values: new object[,]
                {
                    { 1, 40.00m, 1, new DateTime(2026, 1, 20, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 1, 20, 10, 5, 0, 0, DateTimeKind.Utc), "pi_seed_0001", null, null, 1 },
                    { 2, 1200.00m, 6, new DateTime(2026, 5, 10, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 10, 10, 5, 0, 0, DateTimeKind.Utc), "pi_seed_0002", null, null, 1 },
                    { 3, 350.00m, 3, new DateTime(2026, 6, 15, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 15, 11, 5, 0, 0, DateTimeKind.Utc), "pi_seed_0003", null, null, 1 }
                });

            migrationBuilder.InsertData(
                table: "Reviews",
                columns: new[] { "Id", "AppointmentId", "Comment", "CreatedAt", "IsApproved", "Rating" },
                values: new object[,]
                {
                    { 1, 1, "Odličan pregled, doktorica je bila vrlo profesionalna.", new DateTime(2026, 1, 21, 0, 0, 0, 0, DateTimeKind.Utc), true, 5 },
                    { 2, 4, "Zadovoljan sam rezultatom bijeljenja.", new DateTime(2026, 7, 6, 0, 0, 0, 0, DateTimeKind.Utc), true, 4 },
                    { 3, 5, "Uredu, mogla je usluga biti malo brža.", new DateTime(2026, 7, 13, 0, 0, 0, 0, DateTimeKind.Utc), false, 3 },
                    { 4, 6, "Vrlo zadovoljna, doktorica Selma je fantastična sa pacijentima.", new DateTime(2026, 5, 11, 0, 0, 0, 0, DateTimeKind.Utc), true, 5 }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.DeleteData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 7);

            migrationBuilder.DeleteData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 8);

            migrationBuilder.DeleteData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 9);

            migrationBuilder.DeleteData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 10);

            migrationBuilder.DeleteData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 11);

            migrationBuilder.DeleteData(
                table: "DentalServices",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "DentalServices",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.DeleteData(
                table: "DoctorAbsences",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "DoctorAbsences",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "DoctorSpecialties",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "DoctorSpecialties",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "DoctorSpecialties",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "DoctorSpecialties",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "DoctorSpecialties",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "DoctorSpecialties",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.DeleteData(
                table: "DoctorWorkingHours",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "DoctorWorkingHours",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "DoctorWorkingHours",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "DoctorWorkingHours",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "DoctorWorkingHours",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "DoctorWorkingHours",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.DeleteData(
                table: "DoctorWorkingHours",
                keyColumn: "Id",
                keyValue: 7);

            migrationBuilder.DeleteData(
                table: "DoctorWorkingHours",
                keyColumn: "Id",
                keyValue: 8);

            migrationBuilder.DeleteData(
                table: "DoctorWorkingHours",
                keyColumn: "Id",
                keyValue: 9);

            migrationBuilder.DeleteData(
                table: "DoctorWorkingHours",
                keyColumn: "Id",
                keyValue: 10);

            migrationBuilder.DeleteData(
                table: "DoctorWorkingHours",
                keyColumn: "Id",
                keyValue: 11);

            migrationBuilder.DeleteData(
                table: "DoctorWorkingHours",
                keyColumn: "Id",
                keyValue: 12);

            migrationBuilder.DeleteData(
                table: "DoctorWorkingHours",
                keyColumn: "Id",
                keyValue: 13);

            migrationBuilder.DeleteData(
                table: "DoctorWorkingHours",
                keyColumn: "Id",
                keyValue: 14);

            migrationBuilder.DeleteData(
                table: "DoctorWorkingHours",
                keyColumn: "Id",
                keyValue: 15);

            migrationBuilder.DeleteData(
                table: "DoctorWorkingHours",
                keyColumn: "Id",
                keyValue: 16);

            migrationBuilder.DeleteData(
                table: "DoctorWorkingHours",
                keyColumn: "Id",
                keyValue: 17);

            migrationBuilder.DeleteData(
                table: "DoctorWorkingHours",
                keyColumn: "Id",
                keyValue: 18);

            migrationBuilder.DeleteData(
                table: "News",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "News",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "News",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "News",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "News",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Reviews",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Reviews",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Reviews",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Reviews",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "UserRoles",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.DeleteData(
                table: "UserRoles",
                keyColumn: "Id",
                keyValue: 7);

            migrationBuilder.DeleteData(
                table: "UserRoles",
                keyColumn: "Id",
                keyValue: 8);

            migrationBuilder.DeleteData(
                table: "UserRoles",
                keyColumn: "Id",
                keyValue: 9);

            migrationBuilder.DeleteData(
                table: "UserRoles",
                keyColumn: "Id",
                keyValue: 10);

            migrationBuilder.DeleteData(
                table: "UserRoles",
                keyColumn: "Id",
                keyValue: 11);

            migrationBuilder.DeleteData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.DeleteData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 7);

            migrationBuilder.DeleteData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 8);

            migrationBuilder.DeleteData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 9);

            migrationBuilder.DeleteData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 10);

            migrationBuilder.DeleteData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 11);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.DeleteData(
                table: "DentalServices",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "DentalServices",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "DentalServices",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "DentalServices",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "DentalServices",
                keyColumn: "Id",
                keyValue: 7);

            migrationBuilder.DeleteData(
                table: "DentalServices",
                keyColumn: "Id",
                keyValue: 8);

            migrationBuilder.DeleteData(
                table: "DentalServices",
                keyColumn: "Id",
                keyValue: 9);

            migrationBuilder.DeleteData(
                table: "DentalServices",
                keyColumn: "Id",
                keyValue: 10);

            migrationBuilder.DeleteData(
                table: "Doctors",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Doctors",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Doctors",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Doctors",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "Doctors",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 7);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 8);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 9);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 10);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 11);

            migrationBuilder.DeleteData(
                table: "ServiceCategories",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "ServiceCategories",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "ServiceCategories",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "ServiceCategories",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "ServiceCategories",
                keyColumn: "Id",
                keyValue: 5);
        }
    }
}
