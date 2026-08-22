import '../providers/appointment_provider.dart';

/// Scans forward day by day from [startDate] (exclusive) for the next date
/// this doctor/service pair has at least one open slot — used to turn "nema
/// termina" into a helpful pointer ("prvi sljedeći slobodan termin: ...")
/// instead of a dead end. Returns null if nothing opens up within
/// [maxDaysToCheck].
Future<DateTime?> findNextAvailableDate({
  required AppointmentProvider provider,
  required int doctorId,
  required int dentalServiceId,
  required DateTime startDate,
  int maxDaysToCheck = 60,
}) async {
  for (var i = 1; i <= maxDaysToCheck; i++) {
    final date = startDate.add(Duration(days: i));
    try {
      final slots = await provider.getAvailableSlots(
        doctorId: doctorId,
        dentalServiceId: dentalServiceId,
        date: date,
      );
      if (slots.isNotEmpty) return date;
    } catch (_) {
      // Keep scanning — one bad day shouldn't abort the whole search.
    }
  }
  return null;
}

String formatShortDate(DateTime d) =>
    "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}.";
