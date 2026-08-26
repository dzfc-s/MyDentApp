namespace MyDent.Model.Enums
{
    public enum NotificationType
    {
        General,
        AppointmentConfirmed,
        AppointmentCancelled,
        AppointmentReminder,
        RecurringServiceReminder,
        // Appended, not inserted — this enum is stored as an int, so existing rows' values must
        // never shift.
        PaymentSucceeded,
        PaymentRefunded
    }
}
