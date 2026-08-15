using System;

namespace MyDent.Services.Policies
{
    // Shared by RecommenderService (time-based leg, computed on demand for one patient) and
    // MyDent.NotificationWorker's ReminderSchedulerService (proactive, batch-checked across all
    // patients on a schedule) — both need the exact same answer to "is this recall overdue", just
    // triggered differently. Kept as plain static math (no DB access) so it works both against an
    // already-loaded in-memory list (LINQ-to-Objects) and as a precomputed constant inside an EF
    // Core query (LINQ-to-Entities can't translate an arbitrary method call, but it can compare
    // against a DateTime value computed ahead of time).
    public static class RecallPolicy
    {
        public static DateTime CutoffDate(int recommendedRecallMonths, DateTime? asOf = null)
        {
            var now = asOf ?? DateTime.UtcNow;
            return now.AddMonths(-recommendedRecallMonths);
        }

        public static bool IsOverdue(DateTime lastVisit, int recommendedRecallMonths, DateTime? asOf = null)
        {
            return lastVisit <= CutoffDate(recommendedRecallMonths, asOf);
        }
    }
}
