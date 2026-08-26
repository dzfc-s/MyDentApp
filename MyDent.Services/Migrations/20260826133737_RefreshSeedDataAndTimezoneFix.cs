using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace MyDent.Services.Migrations
{
    /// <inheritdoc />
    public partial class RefreshSeedDataAndTimezoneFix : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Moved to the very start of Up() (hand-edited after `dotnet ef migrations add`
            // generated this later in the file) — several UpdateData calls below set FK columns
            // (e.g. AppointmentStatusHistories.ChangedByUserId) to these new user ids, so the rows
            // must exist before those updates run.
            migrationBuilder.InsertData(
                table: "Users",
                columns: new[] { "Id", "Allergies", "BloodType", "CreatedAt", "Email", "EmailNotificationsEnabled", "FirstName", "IsActive", "LastLoginAt", "LastName", "MedicalNotes", "PasswordHash", "PasswordSalt", "PhoneNumber", "ProfileImageAssetId", "PushNotificationsEnabled", "Username" },
                values: new object[,]
                {
                    { 14, null, null, new DateTime(2026, 8, 10, 0, 0, 0, 0, DateTimeKind.Utc), "amar.suljic@gmail.com", true, "Amar", true, null, "Suljić", null, "97CVsdb/RriIbmq6bSLnkSnk2iY=", "4Ia0/2SixvL552HJpHjlgg==", "062111222", null, true, "asuljic" },
                    { 15, null, null, new DateTime(2026, 8, 11, 0, 0, 0, 0, DateTimeKind.Utc), "ilma.becirovic@gmail.com", true, "Ilma", true, null, "Bećirović", null, "cf3yE2GIp3+cXoY7rxCtZ0wQ3T0=", "GUOSx+2UVWR8r6putOWSFQ==", "062222333", null, true, "ibecirovic" },
                    { 16, null, null, new DateTime(2026, 8, 12, 0, 0, 0, 0, DateTimeKind.Utc), "tarik.osmic@gmail.com", true, "Tarik", true, null, "Osmić", null, "/ueyOZg03JjVC4PhcfggPVwSopo=", "lnUGNEkE0VBne8/BxJW3Dg==", "062333444", null, true, "tosmic" },
                    { 17, null, null, new DateTime(2026, 8, 13, 0, 0, 0, 0, DateTimeKind.Utc), "merima.halilovic@gmail.com", true, "Merima", true, null, "Halilović", null, "XGjZ4G5uhNA9ysjR7puJ4sCO6qc=", "4gJcUoPg8r1Cmhs+S0OzUQ==", "062444555", null, true, "mhalilovic" },
                    { 18, null, null, new DateTime(2026, 8, 14, 0, 0, 0, 0, DateTimeKind.Utc), "denis.jasarevic@gmail.com", true, "Denis", true, null, "Jašarević", null, "U6zyYv8whKf1pxsYgNBFwim3Tj0=", "KUSI2gGKGZ6GIf3b+heKMQ==", "062555666", null, true, "djasarevic" }
                });

            // Moved to the start of Up() alongside the Users insert above, for the same reason —
            // AppointmentStatusHistories rows below get repointed at these new appointment ids via
            // UpdateData, so the rows must exist first.
            migrationBuilder.InsertData(
                table: "Appointments",
                columns: new[] { "Id", "CancellationReason", "CancelledAt", "CancelledByUserId", "CreatedAt", "DentalServiceId", "DoctorId", "DurationMinutes", "PatientId", "Price", "Reminder24hSentAt", "Reminder2hSentAt", "ScheduledAt", "Status" },
                values: new object[,]
                {
                    { 12, null, null, null, new DateTime(2026, 8, 25, 11, 30, 0, 0, DateTimeKind.Utc), 5, 3, 60, 18, 1200.00m, null, null, new DateTime(2026, 9, 3, 10, 0, 0, 0, DateTimeKind.Utc), 1 },
                    { 14, null, null, null, new DateTime(2026, 8, 26, 8, 0, 0, 0, DateTimeKind.Utc), 2, 1, 45, 14, 80.00m, null, null, new DateTime(2026, 9, 2, 8, 0, 0, 0, DateTimeKind.Utc), 0 },
                    { 15, null, null, null, new DateTime(2026, 8, 24, 11, 30, 0, 0, DateTimeKind.Utc), 6, 3, 20, 15, 50.00m, null, null, new DateTime(2026, 9, 1, 10, 0, 0, 0, DateTimeKind.Utc), 1 },
                    { 16, "Promjena planova, pacijent otkazao termin.", new DateTime(2026, 8, 26, 9, 0, 0, 0, DateTimeKind.Utc), 16, new DateTime(2026, 8, 20, 9, 0, 0, 0, DateTimeKind.Utc), 9, 5, 45, 16, 150.00m, null, null, new DateTime(2026, 9, 4, 9, 0, 0, 0, DateTimeKind.Utc), 2 },
                    { 17, null, null, null, new DateTime(2026, 8, 26, 14, 0, 0, 0, DateTimeKind.Utc), 1, 1, 30, 17, 40.00m, null, null, new DateTime(2026, 9, 4, 8, 0, 0, 0, DateTimeKind.Utc), 1 },
                    { 18, null, null, null, new DateTime(2026, 8, 26, 7, 45, 0, 0, DateTimeKind.Utc), 10, 5, 30, 18, 70.00m, null, null, new DateTime(2026, 9, 5, 9, 0, 0, 0, DateTimeKind.Utc), 0 },
                    { 13, null, null, null, new DateTime(2026, 8, 25, 12, 30, 0, 0, DateTimeKind.Utc), 9, 5, 45, 13, 150.00m, null, null, new DateTime(2026, 9, 2, 9, 0, 0, 0, DateTimeKind.Utc), 1 },
                    { 19, null, null, null, new DateTime(2026, 8, 19, 8, 30, 0, 0, DateTimeKind.Utc), 3, 2, 30, 13, 60.00m, null, null, new DateTime(2026, 8, 24, 9, 0, 0, 0, DateTimeKind.Utc), 3 }
                });

            migrationBuilder.UpdateData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "ChangedAt", "ChangedByUserId" },
                values: new object[] { new DateTime(2026, 8, 20, 9, 35, 0, 0, DateTimeKind.Utc), 12 });

            migrationBuilder.UpdateData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "ChangedAt", "ChangedByUserId" },
                values: new object[] { new DateTime(2026, 8, 22, 10, 50, 0, 0, DateTimeKind.Utc), 12 });

            migrationBuilder.UpdateData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "ChangedAt", "ChangedByUserId" },
                values: new object[] { new DateTime(2026, 8, 25, 11, 5, 0, 0, DateTimeKind.Utc), 12 });

            migrationBuilder.UpdateData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 4,
                columns: new[] { "ChangedAt", "ChangedByUserId", "FromStatus", "Reason", "ToStatus" },
                values: new object[] { new DateTime(2026, 8, 19, 20, 0, 0, 0, DateTimeKind.Utc), 14, 0, "Pacijent otkazao termin zbog bolesti.", 2 });

            migrationBuilder.UpdateData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "ChangedAt", "ChangedByUserId" },
                values: new object[] { new DateTime(2026, 8, 21, 8, 50, 0, 0, DateTimeKind.Utc), 12 });

            migrationBuilder.UpdateData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 6,
                columns: new[] { "ChangedAt", "ChangedByUserId", "FromStatus", "Reason", "ToStatus" },
                values: new object[] { new DateTime(2026, 8, 20, 15, 0, 0, 0, DateTimeKind.Utc), 12, 0, "Ordinacija otkazala termin – doktor odsutan zbog bolesti.", 2 });

            migrationBuilder.UpdateData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 7,
                columns: new[] { "ChangedAt", "ChangedByUserId", "FromStatus", "ToStatus" },
                values: new object[] { new DateTime(2026, 8, 23, 10, 0, 0, 0, DateTimeKind.Utc), 12, 0, 1 });

            migrationBuilder.UpdateData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 8,
                columns: new[] { "ChangedAt", "ChangedByUserId" },
                values: new object[] { new DateTime(2026, 8, 24, 9, 35, 0, 0, DateTimeKind.Utc), 12 });

            migrationBuilder.UpdateData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 9,
                columns: new[] { "ChangedAt", "ChangedByUserId", "Reason", "ToStatus" },
                values: new object[] { new DateTime(2026, 8, 24, 9, 0, 0, 0, DateTimeKind.Utc), 12, null, 1 });

            migrationBuilder.UpdateData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 10,
                columns: new[] { "AppointmentId", "ChangedAt", "ChangedByUserId", "FromStatus", "ToStatus" },
                values: new object[] { 12, new DateTime(2026, 8, 25, 12, 0, 0, 0, DateTimeKind.Utc), 12, 0, 1 });

            migrationBuilder.UpdateData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 11,
                columns: new[] { "AppointmentId", "ChangedAt", "ChangedByUserId", "FromStatus", "ToStatus" },
                values: new object[] { 13, new DateTime(2026, 8, 25, 13, 0, 0, 0, DateTimeKind.Utc), 12, 0, 1 });

            migrationBuilder.UpdateData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "CreatedAt", "PatientId", "ScheduledAt" },
                values: new object[] { new DateTime(2026, 8, 15, 9, 0, 0, 0, DateTimeKind.Utc), 13, new DateTime(2026, 8, 20, 9, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "CreatedAt", "DentalServiceId", "DoctorId", "DurationMinutes", "PatientId", "Price", "ScheduledAt" },
                values: new object[] { new DateTime(2026, 8, 17, 9, 0, 0, 0, DateTimeKind.Utc), 9, 5, 45, 13, 150.00m, new DateTime(2026, 8, 22, 10, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "CreatedAt", "DentalServiceId", "DoctorId", "PatientId", "Price", "ScheduledAt" },
                values: new object[] { new DateTime(2026, 8, 18, 9, 0, 0, 0, DateTimeKind.Utc), 5, 3, 14, 1200.00m, new DateTime(2026, 8, 25, 10, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 4,
                columns: new[] { "CancellationReason", "CancelledAt", "CancelledByUserId", "CreatedAt", "DentalServiceId", "DoctorId", "DurationMinutes", "PatientId", "Price", "ScheduledAt", "Status" },
                values: new object[] { "Pacijent otkazao termin zbog bolesti.", new DateTime(2026, 8, 19, 20, 0, 0, 0, DateTimeKind.Utc), 14, new DateTime(2026, 8, 14, 9, 0, 0, 0, DateTimeKind.Utc), 7, 4, 60, 14, 350.00m, new DateTime(2026, 8, 20, 8, 0, 0, 0, DateTimeKind.Utc), 2 });

            migrationBuilder.UpdateData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "CreatedAt", "DentalServiceId", "DoctorId", "DurationMinutes", "PatientId", "Price", "ScheduledAt" },
                values: new object[] { new DateTime(2026, 8, 16, 8, 0, 0, 0, DateTimeKind.Utc), 2, 1, 45, 15, 80.00m, new DateTime(2026, 8, 21, 8, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 6,
                columns: new[] { "CancellationReason", "CancelledAt", "CancelledByUserId", "CreatedAt", "DentalServiceId", "DoctorId", "DurationMinutes", "PatientId", "Price", "ScheduledAt", "Status" },
                values: new object[] { "Ordinacija otkazala termin – doktor odsutan zbog bolesti.", new DateTime(2026, 8, 20, 15, 0, 0, 0, DateTimeKind.Utc), 12, new DateTime(2026, 8, 15, 8, 0, 0, 0, DateTimeKind.Utc), 3, 2, 30, 15, 60.00m, new DateTime(2026, 8, 21, 9, 0, 0, 0, DateTimeKind.Utc), 2 });

            migrationBuilder.UpdateData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 7,
                columns: new[] { "CreatedAt", "DentalServiceId", "DoctorId", "DurationMinutes", "PatientId", "Price", "ScheduledAt", "Status" },
                values: new object[] { new DateTime(2026, 8, 23, 9, 0, 0, 0, DateTimeKind.Utc), 6, 3, 20, 16, 50.00m, new DateTime(2026, 8, 27, 10, 0, 0, 0, DateTimeKind.Utc), 1 });

            migrationBuilder.UpdateData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 8,
                columns: new[] { "CreatedAt", "DentalServiceId", "DoctorId", "DurationMinutes", "PatientId", "Price", "ScheduledAt" },
                values: new object[] { new DateTime(2026, 8, 19, 8, 0, 0, 0, DateTimeKind.Utc), 8, 4, 90, 16, 700.00m, new DateTime(2026, 8, 24, 8, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 9,
                columns: new[] { "CancellationReason", "CancelledAt", "CancelledByUserId", "CreatedAt", "DentalServiceId", "DoctorId", "PatientId", "Price", "ScheduledAt", "Status" },
                values: new object[] { null, null, null, new DateTime(2026, 8, 24, 8, 30, 0, 0, DateTimeKind.Utc), 10, 5, 17, 70.00m, new DateTime(2026, 8, 28, 9, 0, 0, 0, DateTimeKind.Utc), 1 });

            migrationBuilder.UpdateData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 10,
                columns: new[] { "CreatedAt", "DentalServiceId", "DoctorId", "DurationMinutes", "PatientId", "Price", "ScheduledAt", "Status" },
                values: new object[] { new DateTime(2026, 8, 26, 7, 0, 0, 0, DateTimeKind.Utc), 1, 1, 30, 17, 40.00m, new DateTime(2026, 8, 31, 8, 0, 0, 0, DateTimeKind.Utc), 0 });

            migrationBuilder.UpdateData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 11,
                columns: new[] { "CreatedAt", "DentalServiceId", "DoctorId", "DurationMinutes", "PatientId", "Price", "ScheduledAt", "Status" },
                values: new object[] { new DateTime(2026, 8, 26, 7, 30, 0, 0, DateTimeKind.Utc), 7, 4, 60, 18, 350.00m, new DateTime(2026, 9, 1, 8, 0, 0, 0, DateTimeKind.Utc), 0 });

            migrationBuilder.UpdateData(
                table: "News",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedByUserId",
                value: 12);

            migrationBuilder.UpdateData(
                table: "News",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedByUserId",
                value: 12);

            migrationBuilder.UpdateData(
                table: "News",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedByUserId",
                value: 12);

            migrationBuilder.UpdateData(
                table: "News",
                keyColumn: "Id",
                keyValue: 4,
                column: "CreatedByUserId",
                value: 12);

            migrationBuilder.UpdateData(
                table: "News",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "Content", "CreatedByUserId", "IsPublished", "Title" },
                values: new object[] { "Termine sada možete platiti direktno u mobilnoj aplikaciji, sigurno i jednostavno, putem platne kartice.", 12, true, "Plaćanje karticom sada dostupno u aplikaciji" });

            migrationBuilder.InsertData(
                table: "News",
                columns: new[] { "Id", "Content", "CreatedAt", "CreatedByUserId", "ImageAssetId", "IsPublished", "PublishedAt", "Title" },
                values: new object[] { 6, "Priprema se javni seminar o pravilnoj njezi zubi za djecu — detalji uskoro.", new DateTime(2026, 8, 20, 9, 0, 0, 0, DateTimeKind.Utc), 12, null, false, new DateTime(2026, 8, 20, 9, 0, 0, 0, DateTimeKind.Utc), "Najava novog seminara o njezi zuba" });

            migrationBuilder.UpdateData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "CreatedAt", "Message", "UserId" },
                values: new object[] { new DateTime(2026, 8, 19, 9, 0, 0, 0, DateTimeKind.Utc), "Vaš termin zakazan za 20.08.2026. u 09:00 je potvrđen.", 13 });

            migrationBuilder.UpdateData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "AppointmentId", "CreatedAt", "IsRead", "Message", "ServiceCategoryId", "Title", "Type", "UserId" },
                values: new object[] { 1, new DateTime(2026, 8, 20, 9, 6, 0, 0, DateTimeKind.Utc), true, "Uplata od 40.00 KM za termin 20.08.2026. je uspješno izvršena.", null, "Plaćanje uspješno", 5, 13 });

            migrationBuilder.UpdateData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "AppointmentId", "CreatedAt", "Message", "Title", "Type", "UserId" },
                values: new object[] { 2, new DateTime(2026, 8, 23, 12, 1, 0, 0, DateTimeKind.Utc), "Izvršena je refundacija u iznosu od 150.00 KM za termin 22.08.2026.", "Refundacija izvršena", 6, 13 });

            migrationBuilder.UpdateData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 4,
                columns: new[] { "AppointmentId", "CreatedAt", "Message", "ServiceCategoryId", "Title", "Type", "UserId" },
                values: new object[] { 13, new DateTime(2026, 8, 25, 13, 6, 0, 0, DateTimeKind.Utc), "Vaš termin zakazan za 02.09.2026. u 09:00 je potvrđen.", null, "Termin potvrđen", 1, 13 });

            migrationBuilder.UpdateData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "AppointmentId", "CreatedAt", "Message", "Title", "Type", "UserId" },
                values: new object[] { 4, new DateTime(2026, 8, 19, 20, 5, 0, 0, DateTimeKind.Utc), "Vaš termin zakazan za 20.08.2026. u 08:00 je otkazan. Razlog: Pacijent otkazao termin zbog bolesti.", "Termin otkazan", 2, 14 });

            migrationBuilder.UpdateData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 6,
                columns: new[] { "AppointmentId", "CreatedAt", "IsRead", "Message", "UserId" },
                values: new object[] { 3, new DateTime(2026, 8, 24, 9, 0, 0, 0, DateTimeKind.Utc), true, "Vaš termin zakazan za 25.08.2026. u 10:00 je potvrđen.", 14 });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "CreatedAt", "PaidAt" },
                values: new object[] { new DateTime(2026, 8, 20, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 8, 20, 9, 5, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "Amount", "AppointmentId", "CreatedAt", "PaidAt", "RefundedAmount", "RefundedAt", "Status" },
                values: new object[] { 150.00m, 2, new DateTime(2026, 8, 22, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 8, 22, 10, 5, 0, 0, DateTimeKind.Utc), 150.00m, new DateTime(2026, 8, 23, 12, 0, 0, 0, DateTimeKind.Utc), 3 });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "Amount", "CreatedAt", "PaidAt" },
                values: new object[] { 1200.00m, new DateTime(2026, 8, 25, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 8, 25, 10, 5, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.InsertData(
                table: "Payments",
                columns: new[] { "Id", "Amount", "AppointmentId", "CreatedAt", "PaidAt", "ProviderTransactionId", "RefundedAmount", "RefundedAt", "Status" },
                values: new object[,]
                {
                    { 4, 80.00m, 5, new DateTime(2026, 8, 21, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 8, 21, 8, 5, 0, 0, DateTimeKind.Utc), "pi_seed_0004", null, null, 1 },
                    { 5, 50.00m, 7, new DateTime(2026, 8, 23, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 8, 23, 10, 5, 0, 0, DateTimeKind.Utc), "pi_seed_0005", null, null, 1 },
                    { 6, 700.00m, 8, new DateTime(2026, 8, 24, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 8, 24, 8, 5, 0, 0, DateTimeKind.Utc), "pi_seed_0006", null, null, 1 },
                    { 7, 70.00m, 9, new DateTime(2026, 8, 24, 9, 0, 0, 0, DateTimeKind.Utc), null, "pi_seed_0007", null, null, 0 }
                });

            migrationBuilder.UpdateData(
                table: "Reviews",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "Comment", "CreatedAt" },
                values: new object[] { "Odličan pregled, sve pohvale za osoblje.", new DateTime(2026, 8, 20, 12, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Reviews",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "AppointmentId", "Comment", "CreatedAt", "Rating" },
                values: new object[] { 2, "Nisam bila zadovoljna rezultatom, ali su brzo riješili refundaciju.", new DateTime(2026, 8, 22, 14, 0, 0, 0, DateTimeKind.Utc), 2 });

            migrationBuilder.UpdateData(
                table: "Reviews",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "AppointmentId", "Comment", "CreatedAt", "IsApproved", "Rating" },
                values: new object[] { 3, "Doktorica Selma je izuzetna, aparatić savršeno stoji.", new DateTime(2026, 8, 25, 13, 0, 0, 0, DateTimeKind.Utc), true, 5 });

            migrationBuilder.UpdateData(
                table: "Reviews",
                keyColumn: "Id",
                keyValue: 4,
                columns: new[] { "AppointmentId", "Comment", "CreatedAt", "IsApproved", "Rating" },
                values: new object[] { 5, "Sve je prošlo dobro, malo duže čekanje u čekaonici.", new DateTime(2026, 8, 21, 10, 0, 0, 0, DateTimeKind.Utc), false, 4 });

            migrationBuilder.InsertData(
                table: "Reviews",
                columns: new[] { "Id", "AppointmentId", "Comment", "CreatedAt", "IsApproved", "Rating" },
                values: new object[] { 5, 8, "Profesionalno urađen most, preporučujem.", new DateTime(2026, 8, 24, 11, 0, 0, 0, DateTimeKind.Utc), true, 5 });

            migrationBuilder.InsertData(
                table: "AppointmentStatusHistories",
                columns: new[] { "Id", "AppointmentId", "ChangedAt", "ChangedByUserId", "FromStatus", "Reason", "ToStatus" },
                values: new object[] { 15, 19, new DateTime(2026, 8, 24, 9, 35, 0, 0, DateTimeKind.Utc), 12, 1, null, 3 });

            migrationBuilder.InsertData(
                table: "Notifications",
                columns: new[] { "Id", "AppointmentId", "CreatedAt", "IsRead", "Message", "ServiceCategoryId", "Title", "Type", "UserId" },
                values: new object[,]
                {
                    { 7, null, new DateTime(2026, 8, 26, 8, 0, 0, 0, DateTimeKind.Utc), false, "Preporučujemo da zakažete termin za \"Ortodoncija\" — prošlo je 2 mjeseca od zadnje posjete.", 3, "Vrijeme je za kontrolu", 4, 14 },
                    { 8, 6, new DateTime(2026, 8, 20, 15, 5, 0, 0, DateTimeKind.Utc), true, "Vaš termin zakazan za 21.08.2026. u 09:00 je otkazan. Razlog: Ordinacija otkazala termin – doktor odsutan zbog bolesti.", null, "Termin otkazan", 2, 15 },
                    { 9, 5, new DateTime(2026, 8, 21, 8, 6, 0, 0, DateTimeKind.Utc), true, "Uplata od 80.00 KM za termin 21.08.2026. je uspješno izvršena.", null, "Plaćanje uspješno", 5, 15 },
                    { 10, 7, new DateTime(2026, 8, 26, 7, 0, 0, 0, DateTimeKind.Utc), false, "Podsjetnik: termin za \"Kontrola aparatića\" zakazan je za 27.08.2026. u 10:00.", null, "Podsjetnik za termin", 3, 16 },
                    { 11, 8, new DateTime(2026, 8, 24, 8, 6, 0, 0, DateTimeKind.Utc), true, "Uplata od 700.00 KM za termin 24.08.2026. je uspješno izvršena.", null, "Plaćanje uspješno", 5, 16 },
                    { 13, 9, new DateTime(2026, 8, 24, 8, 35, 0, 0, DateTimeKind.Utc), false, "Plaćanje za termin zakazan 28.08.2026. još nije izvršeno. Možete platiti karticom u aplikaciji ili na recepciji.", null, "Plaćanje na čekanju", 0, 17 }
                });

            migrationBuilder.InsertData(
                table: "Payments",
                columns: new[] { "Id", "Amount", "AppointmentId", "CreatedAt", "PaidAt", "ProviderTransactionId", "RefundedAmount", "RefundedAt", "Status" },
                values: new object[,]
                {
                    { 9, 150.00m, 13, new DateTime(2026, 8, 25, 13, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 8, 25, 13, 5, 0, 0, DateTimeKind.Utc), "pi_seed_0009", null, null, 1 },
                    { 11, 60.00m, 19, new DateTime(2026, 8, 24, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 8, 24, 9, 5, 0, 0, DateTimeKind.Utc), "pi_seed_0011", null, null, 1 }
                });

            migrationBuilder.InsertData(
                table: "UserRoles",
                columns: new[] { "Id", "DateAssigned", "RoleId", "UserId" },
                values: new object[,]
                {
                    { 14, new DateTime(2026, 8, 10, 0, 0, 0, 0, DateTimeKind.Utc), 2, 14 },
                    { 15, new DateTime(2026, 8, 11, 0, 0, 0, 0, DateTimeKind.Utc), 2, 15 },
                    { 16, new DateTime(2026, 8, 12, 0, 0, 0, 0, DateTimeKind.Utc), 2, 16 },
                    { 17, new DateTime(2026, 8, 13, 0, 0, 0, 0, DateTimeKind.Utc), 2, 17 },
                    { 18, new DateTime(2026, 8, 14, 0, 0, 0, 0, DateTimeKind.Utc), 2, 18 }
                });

            migrationBuilder.InsertData(
                table: "AppointmentStatusHistories",
                columns: new[] { "Id", "AppointmentId", "ChangedAt", "ChangedByUserId", "FromStatus", "Reason", "ToStatus" },
                values: new object[,]
                {
                    { 12, 15, new DateTime(2026, 8, 24, 12, 0, 0, 0, DateTimeKind.Utc), 12, 0, null, 1 },
                    { 13, 16, new DateTime(2026, 8, 26, 9, 0, 0, 0, DateTimeKind.Utc), 16, 1, "Promjena planova, pacijent otkazao termin.", 2 },
                    { 14, 17, new DateTime(2026, 8, 26, 14, 10, 0, 0, DateTimeKind.Utc), 12, 0, null, 1 }
                });

            migrationBuilder.InsertData(
                table: "Notifications",
                columns: new[] { "Id", "AppointmentId", "CreatedAt", "IsRead", "Message", "ServiceCategoryId", "Title", "Type", "UserId" },
                values: new object[,]
                {
                    { 12, 16, new DateTime(2026, 8, 26, 9, 5, 0, 0, DateTimeKind.Utc), false, "Vaš termin zakazan za 04.09.2026. u 09:00 je otkazan. Razlog: Promjena planova, pacijent otkazao termin.", null, "Termin otkazan", 2, 16 },
                    { 14, 12, new DateTime(2026, 8, 25, 12, 5, 0, 0, DateTimeKind.Utc), false, "Plaćanje karticom za termin 03.09.2026. nije uspjelo. Molimo pokušajte ponovo ili platite na recepciji.", null, "Plaćanje neuspješno", 0, 18 }
                });

            migrationBuilder.InsertData(
                table: "Payments",
                columns: new[] { "Id", "Amount", "AppointmentId", "CreatedAt", "PaidAt", "ProviderTransactionId", "RefundedAmount", "RefundedAt", "Status" },
                values: new object[,]
                {
                    { 8, 1200.00m, 12, new DateTime(2026, 8, 25, 12, 0, 0, 0, DateTimeKind.Utc), null, "pi_seed_0008", null, null, 2 },
                    { 10, 40.00m, 17, new DateTime(2026, 8, 26, 14, 5, 0, 0, DateTimeKind.Utc), new DateTime(2026, 8, 26, 14, 10, 0, 0, DateTimeKind.Utc), "pi_seed_0010", null, null, 1 }
                });

            // Moved to the end of Up() (hand-edited after `dotnet ef migrations add` generated this
            // first) — every other row above still pointed at old Users 1-11 via FK (News, then
            // AppointmentStatusHistories, ...) until its own UpdateData ran, so deleting the old
            // Users before all of that had rewired away from them tripped FK constraints one table
            // at a time. Doing the deletes last guarantees nothing still references them.
            migrationBuilder.DeleteData(
                table: "UserRoles",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "UserRoles",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "UserRoles",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "UserRoles",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "UserRoles",
                keyColumn: "Id",
                keyValue: 5);

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
                table: "Users",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 6);

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
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 12);

            migrationBuilder.DeleteData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 13);

            migrationBuilder.DeleteData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 14);

            migrationBuilder.DeleteData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 15);

            migrationBuilder.DeleteData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 14);

            migrationBuilder.DeleteData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 18);

            migrationBuilder.DeleteData(
                table: "News",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.DeleteData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 7);

            migrationBuilder.DeleteData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 8);

            migrationBuilder.DeleteData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 9);

            migrationBuilder.DeleteData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 10);

            migrationBuilder.DeleteData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 11);

            migrationBuilder.DeleteData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 12);

            migrationBuilder.DeleteData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 13);

            migrationBuilder.DeleteData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 14);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 7);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 8);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 9);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 10);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 11);

            migrationBuilder.DeleteData(
                table: "Reviews",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "UserRoles",
                keyColumn: "Id",
                keyValue: 14);

            migrationBuilder.DeleteData(
                table: "UserRoles",
                keyColumn: "Id",
                keyValue: 15);

            migrationBuilder.DeleteData(
                table: "UserRoles",
                keyColumn: "Id",
                keyValue: 16);

            migrationBuilder.DeleteData(
                table: "UserRoles",
                keyColumn: "Id",
                keyValue: 17);

            migrationBuilder.DeleteData(
                table: "UserRoles",
                keyColumn: "Id",
                keyValue: 18);

            migrationBuilder.DeleteData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 12);

            migrationBuilder.DeleteData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 13);

            migrationBuilder.DeleteData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 15);

            migrationBuilder.DeleteData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 16);

            migrationBuilder.DeleteData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 17);

            migrationBuilder.DeleteData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 19);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 14);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 15);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 16);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 17);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 18);

            migrationBuilder.UpdateData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "ChangedAt", "ChangedByUserId" },
                values: new object[] { new DateTime(2026, 1, 20, 10, 30, 0, 0, DateTimeKind.Utc), 1 });

            migrationBuilder.UpdateData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "ChangedAt", "ChangedByUserId" },
                values: new object[] { new DateTime(2026, 7, 10, 9, 30, 0, 0, DateTimeKind.Utc), 1 });

            migrationBuilder.UpdateData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "ChangedAt", "ChangedByUserId" },
                values: new object[] { new DateTime(2026, 6, 15, 12, 0, 0, 0, DateTimeKind.Utc), 1 });

            migrationBuilder.UpdateData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 4,
                columns: new[] { "ChangedAt", "ChangedByUserId", "FromStatus", "Reason", "ToStatus" },
                values: new object[] { new DateTime(2026, 7, 5, 13, 45, 0, 0, DateTimeKind.Utc), 1, 1, null, 3 });

            migrationBuilder.UpdateData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "ChangedAt", "ChangedByUserId" },
                values: new object[] { new DateTime(2026, 7, 12, 13, 30, 0, 0, DateTimeKind.Utc), 1 });

            migrationBuilder.UpdateData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 6,
                columns: new[] { "ChangedAt", "ChangedByUserId", "FromStatus", "Reason", "ToStatus" },
                values: new object[] { new DateTime(2026, 5, 10, 11, 0, 0, 0, DateTimeKind.Utc), 1, 1, null, 3 });

            migrationBuilder.UpdateData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 7,
                columns: new[] { "ChangedAt", "ChangedByUserId", "FromStatus", "ToStatus" },
                values: new object[] { new DateTime(2026, 3, 22, 14, 30, 0, 0, DateTimeKind.Utc), 1, 1, 3 });

            migrationBuilder.UpdateData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 8,
                columns: new[] { "ChangedAt", "ChangedByUserId" },
                values: new object[] { new DateTime(2026, 4, 18, 10, 15, 0, 0, DateTimeKind.Utc), 1 });

            migrationBuilder.UpdateData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 9,
                columns: new[] { "ChangedAt", "ChangedByUserId", "Reason", "ToStatus" },
                values: new object[] { new DateTime(2026, 3, 30, 18, 0, 0, 0, DateTimeKind.Utc), 10, "Pacijent otkazao termin.", 2 });

            migrationBuilder.UpdateData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 10,
                columns: new[] { "AppointmentId", "ChangedAt", "ChangedByUserId", "FromStatus", "ToStatus" },
                values: new object[] { 10, new DateTime(2026, 2, 14, 16, 30, 0, 0, DateTimeKind.Utc), 1, 1, 3 });

            migrationBuilder.UpdateData(
                table: "AppointmentStatusHistories",
                keyColumn: "Id",
                keyValue: 11,
                columns: new[] { "AppointmentId", "ChangedAt", "ChangedByUserId", "FromStatus", "ToStatus" },
                values: new object[] { 11, new DateTime(2026, 7, 25, 11, 30, 0, 0, DateTimeKind.Utc), 1, 1, 3 });

            migrationBuilder.UpdateData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "CreatedAt", "PatientId", "ScheduledAt" },
                values: new object[] { new DateTime(2026, 1, 15, 0, 0, 0, 0, DateTimeKind.Utc), 4, new DateTime(2026, 1, 20, 10, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "CreatedAt", "DentalServiceId", "DoctorId", "DurationMinutes", "PatientId", "Price", "ScheduledAt" },
                values: new object[] { new DateTime(2026, 7, 5, 0, 0, 0, 0, DateTimeKind.Utc), 1, 1, 30, 5, 40.00m, new DateTime(2026, 7, 10, 9, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "CreatedAt", "DentalServiceId", "DoctorId", "PatientId", "Price", "ScheduledAt" },
                values: new object[] { new DateTime(2026, 6, 10, 0, 0, 0, 0, DateTimeKind.Utc), 7, 4, 5, 350.00m, new DateTime(2026, 6, 15, 11, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 4,
                columns: new[] { "CancellationReason", "CancelledAt", "CancelledByUserId", "CreatedAt", "DentalServiceId", "DoctorId", "DurationMinutes", "PatientId", "Price", "ScheduledAt", "Status" },
                values: new object[] { null, null, null, new DateTime(2026, 6, 28, 0, 0, 0, 0, DateTimeKind.Utc), 9, 5, 45, 7, 150.00m, new DateTime(2026, 7, 5, 13, 0, 0, 0, DateTimeKind.Utc), 3 });

            migrationBuilder.UpdateData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "CreatedAt", "DentalServiceId", "DoctorId", "DurationMinutes", "PatientId", "Price", "ScheduledAt" },
                values: new object[] { new DateTime(2026, 7, 6, 0, 0, 0, 0, DateTimeKind.Utc), 10, 5, 30, 7, 70.00m, new DateTime(2026, 7, 12, 13, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 6,
                columns: new[] { "CancellationReason", "CancelledAt", "CancelledByUserId", "CreatedAt", "DentalServiceId", "DoctorId", "DurationMinutes", "PatientId", "Price", "ScheduledAt", "Status" },
                values: new object[] { null, null, null, new DateTime(2026, 5, 1, 0, 0, 0, 0, DateTimeKind.Utc), 5, 3, 60, 8, 1200.00m, new DateTime(2026, 5, 10, 10, 0, 0, 0, DateTimeKind.Utc), 3 });

            migrationBuilder.UpdateData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 7,
                columns: new[] { "CreatedAt", "DentalServiceId", "DoctorId", "DurationMinutes", "PatientId", "Price", "ScheduledAt", "Status" },
                values: new object[] { new DateTime(2026, 3, 18, 0, 0, 0, 0, DateTimeKind.Utc), 3, 2, 30, 9, 60.00m, new DateTime(2026, 3, 22, 14, 0, 0, 0, DateTimeKind.Utc), 3 });

            migrationBuilder.UpdateData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 8,
                columns: new[] { "CreatedAt", "DentalServiceId", "DoctorId", "DurationMinutes", "PatientId", "Price", "ScheduledAt" },
                values: new object[] { new DateTime(2026, 4, 14, 0, 0, 0, 0, DateTimeKind.Utc), 2, 1, 45, 9, 80.00m, new DateTime(2026, 4, 18, 9, 30, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 9,
                columns: new[] { "CancellationReason", "CancelledAt", "CancelledByUserId", "CreatedAt", "DentalServiceId", "DoctorId", "PatientId", "Price", "ScheduledAt", "Status" },
                values: new object[] { "Pacijent otkazao termin.", new DateTime(2026, 3, 30, 18, 0, 0, 0, DateTimeKind.Utc), 10, new DateTime(2026, 3, 25, 0, 0, 0, 0, DateTimeKind.Utc), 3, 2, 10, 60.00m, new DateTime(2026, 4, 1, 10, 0, 0, 0, DateTimeKind.Utc), 2 });

            migrationBuilder.UpdateData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 10,
                columns: new[] { "CreatedAt", "DentalServiceId", "DoctorId", "DurationMinutes", "PatientId", "Price", "ScheduledAt", "Status" },
                values: new object[] { new DateTime(2026, 2, 8, 0, 0, 0, 0, DateTimeKind.Utc), 8, 4, 90, 4, 700.00m, new DateTime(2026, 2, 14, 15, 0, 0, 0, DateTimeKind.Utc), 3 });

            migrationBuilder.UpdateData(
                table: "Appointments",
                keyColumn: "Id",
                keyValue: 11,
                columns: new[] { "CreatedAt", "DentalServiceId", "DoctorId", "DurationMinutes", "PatientId", "Price", "ScheduledAt", "Status" },
                values: new object[] { new DateTime(2026, 7, 20, 0, 0, 0, 0, DateTimeKind.Utc), 1, 1, 30, 11, 40.00m, new DateTime(2026, 7, 25, 11, 0, 0, 0, DateTimeKind.Utc), 3 });

            migrationBuilder.UpdateData(
                table: "News",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedByUserId",
                value: 1);

            migrationBuilder.UpdateData(
                table: "News",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedByUserId",
                value: 1);

            migrationBuilder.UpdateData(
                table: "News",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedByUserId",
                value: 2);

            migrationBuilder.UpdateData(
                table: "News",
                keyColumn: "Id",
                keyValue: 4,
                column: "CreatedByUserId",
                value: 1);

            migrationBuilder.UpdateData(
                table: "News",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "Content", "CreatedByUserId", "IsPublished", "Title" },
                values: new object[] { "Priprema se javni seminar o pravilnoj njezi zubi za djecu — detalji uskoro.", 3, false, "Najava novog seminara o njezi zuba" });

            migrationBuilder.UpdateData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "CreatedAt", "Message", "UserId" },
                values: new object[] { new DateTime(2026, 1, 18, 0, 0, 0, 0, DateTimeKind.Utc), "Vaš termin zakazan za 20.01.2026. u 10:00 je potvrđen.", 4 });

            migrationBuilder.UpdateData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "AppointmentId", "CreatedAt", "IsRead", "Message", "ServiceCategoryId", "Title", "Type", "UserId" },
                values: new object[] { null, new DateTime(2026, 7, 25, 0, 0, 0, 0, DateTimeKind.Utc), false, "Preporučujemo da zakažete termin za \"Opća stomatologija\" — prošlo je 6 mjeseci od zadnje posjete.", 1, "Vrijeme je za kontrolu", 4, 4 });

            migrationBuilder.UpdateData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "AppointmentId", "CreatedAt", "Message", "Title", "Type", "UserId" },
                values: new object[] { 9, new DateTime(2026, 3, 30, 18, 5, 0, 0, DateTimeKind.Utc), "Vaš termin zakazan za 01.04.2026. u 10:00 je otkazan. Razlog: Pacijent otkazao termin.", "Termin otkazan", 2, 10 });

            migrationBuilder.UpdateData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 4,
                columns: new[] { "AppointmentId", "CreatedAt", "Message", "ServiceCategoryId", "Title", "Type", "UserId" },
                values: new object[] { null, new DateTime(2026, 7, 12, 0, 0, 0, 0, DateTimeKind.Utc), "Preporučujemo da zakažete termin za \"Ortodoncija\" — prošlo je 2 mjeseca od zadnje posjete.", 3, "Vrijeme je za kontrolu", 4, 8 });

            migrationBuilder.UpdateData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "AppointmentId", "CreatedAt", "Message", "Title", "Type", "UserId" },
                values: new object[] { 2, new DateTime(2026, 7, 8, 0, 0, 0, 0, DateTimeKind.Utc), "Vaš termin zakazan za 10.07.2026. u 09:00 je potvrđen.", "Termin potvrđen", 1, 5 });

            migrationBuilder.UpdateData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 6,
                columns: new[] { "AppointmentId", "CreatedAt", "IsRead", "Message", "UserId" },
                values: new object[] { 4, new DateTime(2026, 7, 2, 0, 0, 0, 0, DateTimeKind.Utc), false, "Vaš termin zakazan za 05.07.2026. u 13:00 je potvrđen.", 7 });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "CreatedAt", "PaidAt" },
                values: new object[] { new DateTime(2026, 1, 20, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 1, 20, 10, 5, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "Amount", "AppointmentId", "CreatedAt", "PaidAt", "RefundedAmount", "RefundedAt", "Status" },
                values: new object[] { 1200.00m, 6, new DateTime(2026, 5, 10, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 10, 10, 5, 0, 0, DateTimeKind.Utc), null, null, 1 });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "Amount", "CreatedAt", "PaidAt" },
                values: new object[] { 350.00m, new DateTime(2026, 6, 15, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 15, 11, 5, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Reviews",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "Comment", "CreatedAt" },
                values: new object[] { "Odličan pregled, doktorica je bila vrlo profesionalna.", new DateTime(2026, 1, 21, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Reviews",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "AppointmentId", "Comment", "CreatedAt", "Rating" },
                values: new object[] { 4, "Zadovoljan sam rezultatom bijeljenja.", new DateTime(2026, 7, 6, 0, 0, 0, 0, DateTimeKind.Utc), 4 });

            migrationBuilder.UpdateData(
                table: "Reviews",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "AppointmentId", "Comment", "CreatedAt", "IsApproved", "Rating" },
                values: new object[] { 5, "Uredu, mogla je usluga biti malo brža.", new DateTime(2026, 7, 13, 0, 0, 0, 0, DateTimeKind.Utc), false, 3 });

            migrationBuilder.UpdateData(
                table: "Reviews",
                keyColumn: "Id",
                keyValue: 4,
                columns: new[] { "AppointmentId", "Comment", "CreatedAt", "IsApproved", "Rating" },
                values: new object[] { 6, "Vrlo zadovoljna, doktorica Selma je fantastična sa pacijentima.", new DateTime(2026, 5, 11, 0, 0, 0, 0, DateTimeKind.Utc), true, 5 });

            migrationBuilder.InsertData(
                table: "Users",
                columns: new[] { "Id", "Allergies", "BloodType", "CreatedAt", "Email", "EmailNotificationsEnabled", "FirstName", "IsActive", "LastLoginAt", "LastName", "MedicalNotes", "PasswordHash", "PasswordSalt", "PhoneNumber", "ProfileImageAssetId", "PushNotificationsEnabled", "Username" },
                values: new object[,]
                {
                    { 1, null, null, new DateTime(2026, 3, 9, 0, 0, 0, 0, DateTimeKind.Utc), "admin1@gmail.com", true, "Alice", true, null, "Admin", null, "5kRBQg4Ufcx4hAknG7P9zhfLPvY=", "FmvmUwPsJyRRffhNRQvbrA==", null, null, true, "admin1" },
                    { 2, null, null, new DateTime(2026, 3, 9, 0, 0, 0, 0, DateTimeKind.Utc), "admin2@gmail.com", true, "Bob", true, null, "Admin", null, "GBoyh1WP+OMgGjqRj6vK6L1+oGc=", "0AXpKx6xRp9xM42jCf/PiA==", null, null, true, "admin2" },
                    { 3, null, null, new DateTime(2026, 3, 9, 0, 0, 0, 0, DateTimeKind.Utc), "admin3@gmail.com", true, "Carol", true, null, "Admin", null, "x6JHKCTQywdAzTcZxGWFvrKPORM=", "IwhTfKQNgyqWfOlTqCDXrg==", null, null, true, "admin3" },
                    { 4, null, null, new DateTime(2026, 3, 9, 0, 0, 0, 0, DateTimeKind.Utc), "patient1@gmail.com", true, "Dave", true, null, "Patient", null, "E0fA2/f9GZvIRRt/cgqQemG/Cog=", "TiJxWTJcd7sBSiWNbhK9Vw==", null, null, true, "patient1" },
                    { 5, null, null, new DateTime(2026, 3, 9, 0, 0, 0, 0, DateTimeKind.Utc), "patient2@gmail.com", true, "Eve", true, null, "Patient", null, "Ov4LxpWKXXV9dwMYvBgqODdzIt0=", "KtWF6g7SemBqs4nVWV4Ziw==", null, null, true, "patient2" },
                    { 6, null, null, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), "amila.hasic@gmail.com", true, "Amila", true, null, "Hasić", null, "QltLi5GKYeCHaOehVfriIIhPfG0=", "HjfA2PFxZSH9zSYIKufiUA==", "061111222", null, true, "ahasic" },
                    { 7, null, null, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), "faruk.delic@gmail.com", true, "Faruk", true, null, "Delić", null, "V21TmB3/VulNFWlmvlYckBYSSpQ=", "WPc0zv025PwK+O/0+Pj3LA==", "061222333", null, true, "fdelic" },
                    { 8, null, null, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), "selma.kovacevic@gmail.com", true, "Selma", true, null, "Kovačević", null, "uSUoCV2SnmYw7COgUfoADfl2CmQ=", "EzJbcNnW0M0/H6fmm3r79A==", "061333444", null, true, "skovacevic" },
                    { 9, null, null, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), "nedim.zukic@gmail.com", true, "Nedim", true, null, "Zukić", null, "Sxcx82eS5eyS6RQdOSqrblwKi+c=", "UzF2pmAXcvHgrmgwwXfhQQ==", "061444555", null, true, "nzukic" },
                    { 10, null, null, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), "emina.sabic@gmail.com", true, "Emina", true, null, "Šabić", null, "oFdWjtfrOcx4I1FtFkL5S14dtqY=", "PJWyTaDYf+uNjdKNHciOuQ==", "061555666", null, true, "esabic" },
                    { 11, null, null, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), "haris.kurtovic@gmail.com", true, "Haris", true, null, "Kurtović", null, "wRuW4ybXsRCRf9NF+6EgFOUCEBc=", "mILDpEhLR9HlSIOzqraY/A==", "061666777", null, true, "hkurtovic" }
                });

            migrationBuilder.InsertData(
                table: "UserRoles",
                columns: new[] { "Id", "DateAssigned", "RoleId", "UserId" },
                values: new object[,]
                {
                    { 1, new DateTime(2026, 3, 9, 0, 0, 0, 0, DateTimeKind.Utc), 1, 1 },
                    { 2, new DateTime(2026, 3, 9, 0, 0, 0, 0, DateTimeKind.Utc), 1, 2 },
                    { 3, new DateTime(2026, 3, 9, 0, 0, 0, 0, DateTimeKind.Utc), 1, 3 },
                    { 4, new DateTime(2026, 3, 9, 0, 0, 0, 0, DateTimeKind.Utc), 2, 4 },
                    { 5, new DateTime(2026, 3, 9, 0, 0, 0, 0, DateTimeKind.Utc), 2, 5 },
                    { 6, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), 2, 6 },
                    { 7, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), 2, 7 },
                    { 8, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), 2, 8 },
                    { 9, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), 2, 9 },
                    { 10, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), 2, 10 },
                    { 11, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), 2, 11 }
                });
        }
    }
}
