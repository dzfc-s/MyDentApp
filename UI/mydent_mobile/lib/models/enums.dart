// Mirrors the int-valued enums in MyDent.Model.Enums (backend serializes them as plain ints,
// no JsonStringEnumConverter is registered) — order must stay identical to the C# enums.

enum AppointmentStatus { pending, confirmed, cancelled, completed }

extension AppointmentStatusX on AppointmentStatus {
  static AppointmentStatus fromInt(int? value) =>
      AppointmentStatus.values[value ?? 0];

  String get label => switch (this) {
        AppointmentStatus.pending => 'Na čekanju',
        AppointmentStatus.confirmed => 'Potvrđen',
        AppointmentStatus.cancelled => 'Otkazan',
        AppointmentStatus.completed => 'Završen',
      };
}

enum PaymentStatus { pending, paid, failed, refunded }

extension PaymentStatusX on PaymentStatus {
  static PaymentStatus fromInt(int? value) => PaymentStatus.values[value ?? 0];

  String get label => switch (this) {
        PaymentStatus.pending => 'Na čekanju',
        PaymentStatus.paid => 'Plaćeno',
        PaymentStatus.failed => 'Neuspješno',
        PaymentStatus.refunded => 'Refundirano',
      };
}

enum NotificationType {
  general,
  appointmentConfirmed,
  appointmentCancelled,
  appointmentReminder,
  recurringServiceReminder,
  // Order must match MyDent.Model.Enums.NotificationType exactly (int-mapped) — append only.
  paymentSucceeded,
  paymentRefunded,
}

extension NotificationTypeX on NotificationType {
  static NotificationType fromInt(int? value) =>
      NotificationType.values[value ?? 0];
}

enum RecommendationReason { popularity, contentBased, timeBased }

extension RecommendationReasonX on RecommendationReason {
  static RecommendationReason fromInt(int? value) =>
      RecommendationReason.values[value ?? 0];
}
