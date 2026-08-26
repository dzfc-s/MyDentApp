import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/available_slot.dart';
import '../models/dental_service.dart';
import '../models/doctor.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/utils_widgets.dart';
import '../widgets/asset_avatar.dart';
import '../widgets/booking_steps.dart';
import 'booking_success_screen.dart';

/// Review/confirm step between picking a time slot and actually booking it —
/// ported from the Figma reference's "booking-confirm" screen (step 3 of its
/// wizard). Previously `BookAppointmentScreen` booked the instant a slot chip
/// was tapped, with no summary and no cancellation-policy notice; that call
/// now happens here instead, after the patient explicitly confirms.
class BookingConfirmScreen extends StatefulWidget {
  final DentalService service;
  final Doctor doctor;
  final AvailableSlot slot;

  const BookingConfirmScreen({
    super.key,
    required this.service,
    required this.doctor,
    required this.slot,
  });

  @override
  State<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends State<BookingConfirmScreen> {
  bool _isBooking = false;

  static const _weekdays = [
    'Ponedjeljak', 'Utorak', 'Srijeda', 'Četvrtak', 'Petak', 'Subota', 'Nedjelja',
  ];
  static const _months = [
    'januara', 'februara', 'marta', 'aprila', 'maja', 'juna',
    'jula', 'avgusta', 'septembra', 'oktobra', 'novembra', 'decembra',
  ];

  String get _formattedDate {
    final d = widget.slot.startTime!.toLocal();
    return '${_weekdays[d.weekday - 1]}, ${d.day}. ${_months[d.month - 1]} ${d.year}.';
  }

  String get _formattedTime {
    final d = widget.slot.startTime!.toLocal();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirm() async {
    setState(() => _isBooking = true);
    try {
      final appointment = await context.read<AppointmentProvider>().insert({
        "patientId": AuthProvider.userId,
        "doctorId": widget.doctor.id,
        "dentalServiceId": widget.service.id,
        "scheduledAt": widget.slot.startTime!.toIso8601String(),
      });
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSuccessScreen(
            appointmentId: appointment.id!,
            doctorName: '${widget.doctor.firstName} ${widget.doctor.lastName}',
            serviceName: widget.service.name ?? '',
            dateLabel: _formattedDate,
            timeLabel: _formattedTime,
          ),
        ),
      );
    } on Exception catch (e) {
      setState(() => _isBooking = false);
      if (mounted) alertBox(context, 'Greška', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final doctor = widget.doctor;

    return Scaffold(
      appBar: AppBar(title: const Text('Potvrda rezervacije')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          BookingSteps(
            step: 3,
            onBack: _isBooking ? null : () => Navigator.maybePop(context),
            onNext: _isBooking ? null : _confirm,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AssetAvatar(assetId: doctor.photoAssetId, radius: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${doctor.firstName} ${doctor.lastName}',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(service.name ?? '',
                                style: TextStyle(color: Colors.grey[400])),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  _row(context, Icons.calendar_today_outlined, 'Datum', _formattedDate),
                  _row(context, Icons.access_time, 'Vrijeme', _formattedTime),
                  _row(context, Icons.timelapse, 'Trajanje',
                      '${service.durationMinutes ?? '-'} min'),
                  _row(
                    context,
                    Icons.payments_outlined,
                    'Cijena',
                    service.price != null ? '${service.price!.toStringAsFixed(0)} KM' : '-',
                  ),
                  const Divider(height: 28),
                  // Not using _row here — the address is long enough on a narrow
                  // screen to overflow _row's single-line, unwrapped value text.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 18, color: Colors.grey[400]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(ClinicInfo.name,
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            Text(ClinicInfo.address,
                                style: TextStyle(color: Colors.grey[400], fontSize: 12.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warningContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Termin je moguće besplatno otkazati najkasnije 24h prije zakazanog vremena. '
                    'Kasnije otkazivanje ili nedolazak može biti evidentirano u vašoj historiji.',
                    style: TextStyle(color: AppColors.warning, fontSize: 12.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isBooking ? null : _confirm,
              child: _isBooking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Potvrdi rezervaciju'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _isBooking ? null : () => Navigator.pop(context),
              child: const Text('Nazad'),
            ),
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey[400])),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
