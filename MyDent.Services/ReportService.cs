using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Enums;
using MyDent.Model.Exceptions;
using MyDent.Model.Requests;
using MyDent.Services.Database;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace MyDent.Services
{
    public class ReportService : IReportService
    {
        private readonly MyDentDbContext _dbContext;

        public ReportService(MyDentDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<byte[]> GenerateRevenueReportAsync(RevenueReportRequest request)
        {
            var (startDate, endDate) = ValidateDateRange(request.StartDate, request.EndDate);

            // endDate is inclusive of the whole day, not just midnight.
            var rangeEnd = endDate.Date.AddDays(1);

            var query = _dbContext.Appointments
                .Include(a => a.DentalService).ThenInclude(s => s.ServiceCategory)
                .Where(a => a.Status == AppointmentStatus.Completed
                    && a.ScheduledAt >= startDate.Date
                    && a.ScheduledAt < rangeEnd);

            if (request.DoctorId.HasValue)
            {
                query = query.Where(a => a.DoctorId == request.DoctorId.Value);
            }

            var appointments = await query.ToListAsync();

            // Grouped by category — "which category brought in the most revenue this period",
            // not a flat chronological list of every appointment.
            var rows = appointments
                .GroupBy(a => a.DentalService.ServiceCategory)
                .Select(g => new
                {
                    Category = g.Key,
                    AppointmentCount = g.Count(),
                    Revenue = g.Sum(a => a.Price)
                })
                .OrderByDescending(x => x.Revenue)
                .ToList();

            var totalRevenue = rows.Sum(r => r.Revenue);
            var totalAppointments = rows.Sum(r => r.AppointmentCount);

            string? doctorName = null;
            if (request.DoctorId.HasValue)
            {
                var doctor = await _dbContext.Doctors.FindAsync(request.DoctorId.Value);
                if (doctor != null)
                {
                    doctorName = $"{doctor.FirstName} {doctor.LastName}";
                }
            }

            var document = QuestPDF.Fluent.Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Size(PageSizes.A4);
                    page.Margin(2, Unit.Centimetre);
                    page.DefaultTextStyle(x => x.FontSize(10));

                    page.Header().Column(col =>
                    {
                        col.Item().Text("MyDent — Izvještaj o prihodu po kategoriji").FontSize(18).Bold();
                        col.Item().Text($"Period: {startDate:dd.MM.yyyy.} — {endDate:dd.MM.yyyy.}");
                        if (!string.IsNullOrWhiteSpace(doctorName))
                        {
                            col.Item().Text($"Doktor: {doctorName}");
                        }
                        col.Item().Text($"Generisano: {DateTime.Now:dd.MM.yyyy. HH:mm}").FontSize(8).FontColor(Colors.Grey.Darken1);
                        col.Item().PaddingTop(10).LineHorizontal(1).LineColor(Colors.Grey.Lighten1);
                    });

                    page.Content().PaddingTop(10).Table(table =>
                    {
                        table.ColumnsDefinition(columns =>
                        {
                            columns.RelativeColumn(1);
                            columns.RelativeColumn(4);
                            columns.RelativeColumn(2);
                            columns.RelativeColumn(2);
                        });

                        table.Header(header =>
                        {
                            header.Cell().Element(HeaderCell).Text("#");
                            header.Cell().Element(HeaderCell).Text("Kategorija");
                            header.Cell().Element(HeaderCell).AlignRight().Text("Broj termina");
                            header.Cell().Element(HeaderCell).AlignRight().Text("Prihod (KM)");
                        });

                        var rank = 1;
                        foreach (var row in rows)
                        {
                            table.Cell().Element(DataCell).Text(rank.ToString());
                            table.Cell().Element(DataCell).Text(row.Category.Name);
                            table.Cell().Element(DataCell).AlignRight().Text(row.AppointmentCount.ToString());
                            table.Cell().Element(DataCell).AlignRight().Text(row.Revenue.ToString("N2"));
                            rank++;
                        }
                    });

                    page.Footer().Column(col =>
                    {
                        col.Item().PaddingTop(5).LineHorizontal(1).LineColor(Colors.Grey.Lighten1);
                        col.Item().AlignRight().Text($"Ukupno završenih termina: {totalAppointments}").FontSize(9);
                        col.Item().AlignRight().Text($"Ukupan prihod: {totalRevenue:N2} KM").Bold().FontSize(12);
                    });
                });
            });

            return document.GeneratePdf();
        }

        public async Task<byte[]> GenerateServicePopularityReportAsync(ServicePopularityReportRequest request)
        {
            var (startDate, endDate) = ValidateDateRange(request.StartDate, request.EndDate);

            var rangeEnd = endDate.Date.AddDays(1);

            var bookingCounts = await _dbContext.Appointments
                .Where(a => a.Status != AppointmentStatus.Cancelled
                    && a.ScheduledAt >= startDate.Date
                    && a.ScheduledAt < rangeEnd)
                .GroupBy(a => a.DentalServiceId)
                .Select(g => new { DentalServiceId = g.Key, BookingCount = g.Count() })
                .OrderByDescending(x => x.BookingCount)
                .ToListAsync();

            var serviceIds = bookingCounts.Select(x => x.DentalServiceId).ToList();
            var services = await _dbContext.DentalServices
                .Include(s => s.ServiceCategory)
                .Where(s => serviceIds.Contains(s.Id))
                .ToDictionaryAsync(s => s.Id);

            var rows = bookingCounts
                .Where(x => services.ContainsKey(x.DentalServiceId))
                .Select(x => (Service: services[x.DentalServiceId], x.BookingCount))
                .ToList();
            var totalBookings = rows.Sum(r => r.BookingCount);

            var document = QuestPDF.Fluent.Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Size(PageSizes.A4);
                    page.Margin(2, Unit.Centimetre);
                    page.DefaultTextStyle(x => x.FontSize(10));

                    page.Header().Column(col =>
                    {
                        col.Item().Text("MyDent — Izvještaj o popularnosti usluga").FontSize(18).Bold();
                        col.Item().Text($"Period: {startDate:dd.MM.yyyy.} — {endDate:dd.MM.yyyy.}");
                        col.Item().Text($"Generisano: {DateTime.Now:dd.MM.yyyy. HH:mm}").FontSize(8).FontColor(Colors.Grey.Darken1);
                        col.Item().PaddingTop(10).LineHorizontal(1).LineColor(Colors.Grey.Lighten1);
                    });

                    page.Content().PaddingTop(10).Table(table =>
                    {
                        table.ColumnsDefinition(columns =>
                        {
                            columns.RelativeColumn(1);
                            columns.RelativeColumn(4);
                            columns.RelativeColumn(3);
                            columns.RelativeColumn(2);
                        });

                        table.Header(header =>
                        {
                            header.Cell().Element(HeaderCell).Text("#");
                            header.Cell().Element(HeaderCell).Text("Usluga");
                            header.Cell().Element(HeaderCell).Text("Kategorija");
                            header.Cell().Element(HeaderCell).AlignRight().Text("Broj termina");
                        });

                        var rank = 1;
                        foreach (var row in rows)
                        {
                            table.Cell().Element(DataCell).Text(rank.ToString());
                            table.Cell().Element(DataCell).Text(row.Service.Name);
                            table.Cell().Element(DataCell).Text(row.Service.ServiceCategory.Name);
                            table.Cell().Element(DataCell).AlignRight().Text(row.BookingCount.ToString());
                            rank++;
                        }
                    });

                    page.Footer().Column(col =>
                    {
                        col.Item().PaddingTop(5).LineHorizontal(1).LineColor(Colors.Grey.Lighten1);
                        col.Item().AlignRight().Text($"Ukupno termina u periodu: {totalBookings}").Bold().FontSize(12);
                    });
                });
            });

            return document.GeneratePdf();
        }

        // Nullable in, non-null out — forces the caller to have both dates before doing anything
        // else, with one clear error message instead of a silently-empty report.
        private static (DateTime StartDate, DateTime EndDate) ValidateDateRange(DateTime? startDate, DateTime? endDate)
        {
            if (!startDate.HasValue || !endDate.HasValue)
            {
                throw new ClientException("StartDate and EndDate are both required.");
            }

            if (endDate.Value < startDate.Value)
            {
                throw new ClientException("EndDate must not be before StartDate.");
            }

            return (startDate.Value, endDate.Value);
        }

        private static IContainer HeaderCell(IContainer container)
        {
            return container.BorderBottom(1).BorderColor(Colors.Black).PaddingVertical(4).PaddingHorizontal(2).DefaultTextStyle(x => x.Bold());
        }

        private static IContainer DataCell(IContainer container)
        {
            return container.BorderBottom(0.5f).BorderColor(Colors.Grey.Lighten2).PaddingVertical(4).PaddingHorizontal(2);
        }
    }
}
