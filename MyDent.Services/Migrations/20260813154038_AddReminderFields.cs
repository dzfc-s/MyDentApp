using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MyDent.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddReminderFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "RecommendedRecallMonths",
                table: "ServiceCategories",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ServiceCategoryId",
                table: "Notifications",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "Reminder24hSentAt",
                table: "Appointments",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "Reminder2hSentAt",
                table: "Appointments",
                type: "datetime2",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_ServiceCategoryId",
                table: "Notifications",
                column: "ServiceCategoryId");

            migrationBuilder.AddForeignKey(
                name: "FK_Notifications_ServiceCategories_ServiceCategoryId",
                table: "Notifications",
                column: "ServiceCategoryId",
                principalTable: "ServiceCategories",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Notifications_ServiceCategories_ServiceCategoryId",
                table: "Notifications");

            migrationBuilder.DropIndex(
                name: "IX_Notifications_ServiceCategoryId",
                table: "Notifications");

            migrationBuilder.DropColumn(
                name: "RecommendedRecallMonths",
                table: "ServiceCategories");

            migrationBuilder.DropColumn(
                name: "ServiceCategoryId",
                table: "Notifications");

            migrationBuilder.DropColumn(
                name: "Reminder24hSentAt",
                table: "Appointments");

            migrationBuilder.DropColumn(
                name: "Reminder2hSentAt",
                table: "Appointments");
        }
    }
}
