import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "Korak X/3" progress indicator for the booking wizard (Figma reference's
/// booking screens all carry one). Step 1 is the service-picker bottom sheet
/// (transient, not a full page, so it doesn't host this); step 2 is
/// [BookAppointmentScreen] (doctor/date/time); step 3 is [BookingConfirmScreen].
class BookingSteps extends StatelessWidget {
  final int step;

  /// Explicit prev/next arrows next to the "Korak X/3" label — the tappable
  /// progress segments (below) already let you jump back to a finished step,
  /// but that's easy to miss since nothing about a plain progress bar looks
  /// tappable. Both are optional and independent: [onBack] renders a
  /// left-chevron (typically just an alias for the same pop the "Nazad"
  /// button/segment tap already do), [onNext] a right-chevron for advancing
  /// without needing to interact with the step's own content (e.g. jumping
  /// back to the already-selected time slot's step).
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  static const int totalSteps = 3;
  static const List<String> _labels = ['Usluga', 'Termin', 'Potvrda'];

  const BookingSteps({super.key, required this.step, this.onBack, this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null)
                InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(999),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.chevron_left, size: 18),
                  ),
                ),
              Expanded(
                child: Text(
                  'Korak $step/$totalSteps — ${_labels[step - 1]}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              if (onNext != null)
                InkWell(
                  onTap: onNext,
                  borderRadius: BorderRadius.circular(999),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.chevron_right, size: 18),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(totalSteps, (i) {
              final done = i < step;
              // Each finished step is a real, already-visited screen still sitting on the
              // Navigator stack — tapping it pops back there, the same as the in-page "Nazad"
              // button, just reachable from the step indicator too instead of only that one spot.
              return Expanded(
                child: GestureDetector(
                  onTap: done ? () => Navigator.maybePop(context) : null,
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i == totalSteps - 1 ? 0 : 6),
                    decoration: BoxDecoration(
                      color: done ? AppColors.primary : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
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
