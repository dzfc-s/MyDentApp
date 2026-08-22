using Microsoft.EntityFrameworkCore;
using MyDent.Model.Enums;
using MyDent.Services.Database;
using MyDent.Services.Policies;

namespace MyDent.NotificationWorker;

// Relocated from MyDent.WebAPI/BackgroundServices/ReminderBackgroundService.cs — a BackgroundService
// living inside the API project doesn't satisfy the microservices requirement, so the whole
// reminder-scheduling responsibility now runs here instead, in its own process/container.
// Runs independently of any HTTP request to send notifications that nothing else triggers:
// appointment reminders (24h/2h before) and recurring-checkup reminders (based on time since a
// patient's last completed visit in a category with a RecommendedRecallMonths set).
public class ReminderSchedulerService : BackgroundService
{
    private static readonly TimeSpan PollInterval = TimeSpan.FromMinutes(15);

    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<ReminderSchedulerService> _logger;

    public ReminderSchedulerService(IServiceScopeFactory scopeFactory, ILogger<ReminderSchedulerService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<MyDentDbContext>();

                await SendAppointmentRemindersAsync(dbContext, stoppingToken);
                await SendRecurringServiceRemindersAsync(dbContext, stoppingToken);
                await AutoCompletePastAppointmentsAsync(dbContext, stoppingToken);
            }
            catch (Exception ex)
            {
                // A single bad tick (e.g. transient DB hiccup) shouldn't kill the whole
                // background service for the rest of the worker's lifetime — log and retry next interval.
                _logger.LogError(ex, "ReminderSchedulerService tick failed.");
            }

            try
            {
                await Task.Delay(PollInterval, stoppingToken);
            }
            catch (TaskCanceledException)
            {
                // Expected on shutdown.
            }
        }
    }

    private static async Task SendAppointmentRemindersAsync(MyDentDbContext dbContext, CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;

        // "Due" = within the target window and not yet sent — checked this way (rather than a
        // narrow window matched to the poll interval) so a reminder still goes out even if a
        // tick is delayed or skipped, as long as it runs at least once before the appointment.
        var due24h = await dbContext.Appointments
            .Where(a => (a.Status == AppointmentStatus.Pending || a.Status == AppointmentStatus.Confirmed)
                && a.Reminder24hSentAt == null
                && a.ScheduledAt > now && a.ScheduledAt <= now.AddHours(24))
            .ToListAsync(cancellationToken);

        foreach (var appointment in due24h)
        {
            dbContext.Notifications.Add(new Notification
            {
                UserId = appointment.PatientId,
                Title = "Podsjetnik za termin",
                Message = $"Podsjećamo vas na termin zakazan za {appointment.ScheduledAt:dd.MM.yyyy. 'u' HH:mm} (za 24h).",
                Type = NotificationType.AppointmentReminder,
                AppointmentId = appointment.Id,
                CreatedAt = now
            });

            appointment.Reminder24hSentAt = now;
        }

        var due2h = await dbContext.Appointments
            .Where(a => (a.Status == AppointmentStatus.Pending || a.Status == AppointmentStatus.Confirmed)
                && a.Reminder2hSentAt == null
                && a.ScheduledAt > now && a.ScheduledAt <= now.AddHours(2))
            .ToListAsync(cancellationToken);

        foreach (var appointment in due2h)
        {
            dbContext.Notifications.Add(new Notification
            {
                UserId = appointment.PatientId,
                Title = "Podsjetnik za termin",
                Message = $"Podsjećamo vas na termin zakazan za {appointment.ScheduledAt:dd.MM.yyyy. 'u' HH:mm} (za 2h).",
                Type = NotificationType.AppointmentReminder,
                AppointmentId = appointment.Id,
                CreatedAt = now
            });

            appointment.Reminder2hSentAt = now;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    // Confirmed appointments whose time has passed used to only ever become Completed if an
    // Admin remembered to click "Završi" by hand — most clinics don't run that way, an appointment
    // is just "done" once its slot has passed. This makes that transition automatic; the manual
    // button in the desktop UI still exists for edge cases (e.g. correcting a stale record), but
    // isn't the primary path anymore.
    private static async Task AutoCompletePastAppointmentsAsync(MyDentDbContext dbContext, CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;

        var due = await dbContext.Appointments
            .Where(a => a.Status == AppointmentStatus.Confirmed
                && a.ScheduledAt.AddMinutes(a.DurationMinutes) <= now)
            .ToListAsync(cancellationToken);

        if (due.Count == 0)
        {
            return;
        }

        // Status-change history requires a real actor (ChangedByUserId is a non-nullable FK) —
        // there's no authenticated caller in a background worker, so this attributes automatic
        // completions to the first seeded Admin account, same convention as "system" actions in
        // apps with no dedicated service-account row.
        var systemUserId = await dbContext.Users
            .Where(u => u.UserRoles.Any(ur => ur.Role.Name == "Admin"))
            .Select(u => u.Id)
            .FirstOrDefaultAsync(cancellationToken);

        if (systemUserId == 0)
        {
            return;
        }

        foreach (var appointment in due)
        {
            dbContext.AppointmentStatusHistories.Add(new AppointmentStatusHistory
            {
                AppointmentId = appointment.Id,
                FromStatus = AppointmentStatus.Confirmed,
                ToStatus = AppointmentStatus.Completed,
                ChangedByUserId = systemUserId,
                Reason = "Automatski označeno kao završeno (isteklo je vrijeme termina).",
                ChangedAt = now
            });

            appointment.Status = AppointmentStatus.Completed;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private static async Task SendRecurringServiceRemindersAsync(MyDentDbContext dbContext, CancellationToken cancellationToken)
    {
        var categories = await dbContext.ServiceCategories
            .Where(c => c.IsActive && c.RecommendedRecallMonths.HasValue)
            .ToListAsync(cancellationToken);

        foreach (var category in categories)
        {
            var cutoff = RecallPolicy.CutoffDate(category.RecommendedRecallMonths!.Value);

            // Last completed visit per patient in this category, only where that visit is
            // already past the recall cutoff.
            var overdueVisits = await dbContext.Appointments
                .Where(a => a.Status == AppointmentStatus.Completed && a.DentalService.ServiceCategoryId == category.Id)
                .GroupBy(a => a.PatientId)
                .Select(g => new { PatientId = g.Key, LastVisit = g.Max(a => a.ScheduledAt) })
                .Where(x => x.LastVisit <= cutoff)
                .ToListAsync(cancellationToken);

            foreach (var visit in overdueVisits)
            {
                // Only remind once per recall cycle: skip if a reminder for this patient+category
                // was already sent after their last completed visit (i.e. for this same cycle).
                var alreadyReminded = await dbContext.Notifications.AnyAsync(n =>
                    n.UserId == visit.PatientId &&
                    n.ServiceCategoryId == category.Id &&
                    n.Type == NotificationType.RecurringServiceReminder &&
                    n.CreatedAt > visit.LastVisit,
                    cancellationToken);

                if (alreadyReminded)
                {
                    continue;
                }

                dbContext.Notifications.Add(new Notification
                {
                    UserId = visit.PatientId,
                    Title = "Vrijeme je za kontrolu",
                    Message = $"Preporučujemo da zakažete termin za \"{category.Name}\" — prošlo je {category.RecommendedRecallMonths} mjeseci od zadnje posjete.",
                    Type = NotificationType.RecurringServiceReminder,
                    ServiceCategoryId = category.Id,
                    CreatedAt = DateTime.UtcNow
                });
            }
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }
}
