using System;

namespace MyDent.Services
{
    // DoctorWorkingHours and Appointment.ScheduledAt are entered and stored as naive clinic-local
    // wall-clock time (Europe/Sarajevo), but the API container runs on UTC. Comparing that data
    // against DateTime.UtcNow directly is off by the local UTC offset — e.g. a 14:00 slot would
    // still look "in the future" at 15:07 local time. Use this wherever "now" needs to be compared
    // against scheduling data, so both sides are in the same time frame.
    public static class ClinicClock
    {
        private static readonly TimeZoneInfo ClinicTimeZone = TimeZoneInfo.FindSystemTimeZoneById("Europe/Sarajevo");

        public static DateTime Now => TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, ClinicTimeZone);
    }
}
