import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/enums.dart';
import '../models/payment.dart';
import '../models/review.dart';
import '../providers/appointment_provider.dart';
import '../providers/doctor_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/review_provider.dart';
import '../theme/app_theme.dart';
import '../utils/booking_helpers.dart';
import '../utils/utils_widgets.dart';
import '../widgets/asset_avatar.dart';
import 'add_review_screen.dart';
import 'payment_screen.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final int appointmentId;

  const AppointmentDetailsScreen({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  Appointment? _appointment;
  Doctor? _doctor;
  Payment? _payment;
  Review? _review;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final appointment = await context
          .read<AppointmentProvider>()
          .getById(widget.appointmentId);

      final payments = await context
          .read<PaymentProvider>()
          .get(filter: {"appointmentId": widget.appointmentId});
      final reviews = await context
          .read<ReviewProvider>()
          .get(filter: {"appointmentId": widget.appointmentId});

      Doctor? doctor;
      if (appointment.doctorId != null) {
        try {
          doctor = await context
              .read<DoctorProvider>()
              .getById(appointment.doctorId!);
        } catch (_) {
          // Doctor lookup is only for the avatar photo — the name already came with the appointment.
        }
      }

      if (!mounted) return;
      setState(() {
        _appointment = appointment;
        _doctor = doctor;
        _payment = payments.items?.isNotEmpty == true ? payments.items!.first : null;
        _review = reviews.items?.isNotEmpty == true ? reviews.items!.first : null;
        isLoading = false;
      });
    } on Exception catch (e) {
      if (mounted) alertBox(context, 'Greška', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || _appointment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Termin")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final a = _appointment!;
    final status = AppointmentStatusX.fromInt(a.status);

    return Scaffold(
      appBar: AppBar(title: Text(a.dentalServiceName ?? '')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AssetAvatar(assetId: _doctor?.photoAssetId, radius: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          a.doctorName ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _row("Termin", a.scheduledAt?.toLocal().toString().substring(0, 16) ?? ''),
                  _row("Trajanje", "${a.durationMinutes} min"),
                  _row("Cijena", "${a.price} KM"),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const SizedBox(
                            width: 140,
                            child: Text("Status", style: TextStyle(color: Colors.grey))),
                        StatusBadge.appointment(status),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (status == AppointmentStatus.cancelled &&
              (a.cancellationReason?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.dangerContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.danger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Razlog otkazivanja: ${a.cancellationReason}",
                          style: const TextStyle(color: AppColors.danger, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Pratite novosti u aplikaciji — obavijestit ćemo Vas kada doktor "
                    "bude ponovo dostupan za rezervacije.",
                    style: TextStyle(color: AppColors.danger, fontSize: 12.5, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (status == AppointmentStatus.pending ||
              status == AppointmentStatus.confirmed) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _cancel,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text("Otkaži termin"),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (status == AppointmentStatus.cancelled) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => pickServiceAndBook(context),
                icon: const Icon(Icons.event_repeat_outlined),
                label: const Text("Zakaži ponovo"),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (PaymentStatusX.fromInt(_payment?.status) != PaymentStatus.paid &&
              status != AppointmentStatus.cancelled) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _pay,
                icon: const Icon(Icons.payment),
                label: const Text("Plati"),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (status == AppointmentStatus.completed && _review == null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addReview,
                icon: const Icon(Icons.star_outline),
                label: const Text("Ostavi recenziju"),
              ),
            ),
          if (_review != null)
            Card(
              child: ListTile(
                title: Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < (_review!.rating ?? 0) ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 18,
                    ),
                  ),
                ),
                subtitle: Text(_review!.comment ?? ''),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _cancel() async {
    final formKey = GlobalKey<FormState>();
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Otkaži termin"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: reasonController,
            decoration: const InputDecoration(labelText: "Razlog"),
            autofocus: true,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? "Razlog je obavezan" : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Odustani"),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, reasonController.text.trim());
              }
            },
            child: const Text("Otkaži termin"),
          ),
        ],
      ),
    );
    if (reason == null) return;

    try {
      await context.read<AppointmentProvider>().cancel(widget.appointmentId, reason);
      _load();
    } on Exception catch (e) {
      if (mounted) alertBox(context, 'Greška', e.toString());
    }
  }

  Future<void> _pay() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(appointmentId: widget.appointmentId),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _addReview() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddReviewScreen(
          appointmentId: widget.appointmentId,
          dentalServiceName: _appointment?.dentalServiceName ?? '',
        ),
      ),
    );
    if (result == true) _load();
  }
}
