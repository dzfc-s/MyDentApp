import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "Korak X/3" progress indicator for the booking wizard (Figma reference's
/// booking screens all carry one). Step 1 is the service-picker bottom sheet
/// (transient, not a full page, so it doesn't host this); step 2 is
/// [BookAppointmentScreen] (doctor/date/time); step 3 is [BookingConfirmScreen].
class BookingSteps extends StatelessWidget {
  final int step;
  static const int totalSteps = 3;
  static const List<String> _labels = ['Usluga', 'Termin', 'Potvrda'];

  const BookingSteps({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Korak $step/$totalSteps — ${_labels[step - 1]}',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(totalSteps, (i) {
              final done = i < step;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i == totalSteps - 1 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: done ? AppColors.primary : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
