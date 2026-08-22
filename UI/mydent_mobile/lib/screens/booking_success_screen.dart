import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'appointment_details_screen.dart';

/// Closure screen shown right after a successful booking — ported from the
/// Figma reference's "booking-success" screen. The app previously had no
/// equivalent: booking a slot silently jumped straight to the appointment
/// details screen with no confirmation moment.
class BookingSuccessScreen extends StatelessWidget {
  final int appointmentId;
  final String doctorName;
  final String serviceName;
  final String dateLabel;
  final String timeLabel;

  const BookingSuccessScreen({
    super.key,
    required this.appointmentId,
    required this.doctorName,
    required this.serviceName,
    required this.dateLabel,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, color: AppColors.success, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                'Termin je uspješno zakazan!',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Poslali smo vam potvrdu i podsjetit ćemo vas prije termina.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(serviceName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('sa $doctorName', style: TextStyle(color: Colors.grey[400])),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        Text(dateLabel),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        Text(timeLabel),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Wrapped in Expanded (unlike the date/time rows above) since
                    // the clinic name+address is long enough to overflow otherwise.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('${ClinicInfo.name}, ${ClinicInfo.address}'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AppointmentDetailsScreen(appointmentId: appointmentId),
                    ),
                  ),
                  child: const Text('Pogledaj moj termin'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  child: const Text('Nazad na početnu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
