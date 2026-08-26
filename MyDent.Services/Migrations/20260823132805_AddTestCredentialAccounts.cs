using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace MyDent.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddTestCredentialAccounts : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "Users",
                columns: new[] { "Id", "Allergies", "BloodType", "CreatedAt", "Email", "EmailNotificationsEnabled", "FirstName", "IsActive", "LastLoginAt", "LastName", "MedicalNotes", "PasswordHash", "PasswordSalt", "PhoneNumber", "ProfileImageAssetId", "PushNotificationsEnabled", "Username" },
                values: new object[,]
                {
                    { 12, null, null, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), "desktop.test@mydent.example", true, "Desktop", true, null, "Test", null, "XEl2qoKu2YArgsq1Y3VhlyjqjiM=", "roKn7IGTdP3yztR2+qc+7Q==", null, null, true, "desktop" },
                    { 13, null, null, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), "mobile.test@mydent.example", true, "Mobile", true, null, "Test", null, "omyGZFUqPKsvhuX2Id1vnNGw+pE=", "ytRbBjA/SsKMyuSRMtS95A==", null, null, true, "mobile" }
                });

            migrationBuilder.InsertData(
                table: "UserRoles",
                columns: new[] { "Id", "DateAssigned", "RoleId", "UserId" },
                values: new object[,]
                {
                    { 12, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), 1, 12 },
                    { 13, new DateTime(2026, 3, 10, 0, 0, 0, 0, DateTimeKind.Utc), 2, 13 }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "UserRoles",
                keyColumn: "Id",
                keyValue: 12);

            migrationBuilder.DeleteData(
                table: "UserRoles",
                keyColumn: "Id",
                keyValue: 13);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 12);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 13);
        }
    }
}
