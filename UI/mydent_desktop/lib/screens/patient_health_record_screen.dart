import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/appointment.dart';
import '../models/enums.dart';
import '../models/user.dart';
import '../providers/appointment_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../utils/utils_widgets.dart';
import '../widgets/stat_card.dart';

const List<String> _bloodTypes = [
  'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
];

/// Patient health record ("Zdravstveni karton") — Allergies/BloodType/MedicalNotes live on the
/// User entity itself (patients have no separate table), so saving here submits the full
/// UserUpdateRequest shape with the account's existing values untouched, plus these 3 fields.
///
/// Also shows a read-only visit summary (counts/spend/last-next visit) and a full appointment
/// history timeline, both derived client-side from GET /Appointments?patientId=... — Admin
/// callers aren't scoped to "their own" appointments the way patients are, so this works without
/// any backend changes. There is currently no dedicated Address/DOB field on User at all (not
/// just missing from this screen) — adding those needs a schema migration, done separately with
/// real DB tooling rather than guessed at here.
class PatientHealthRecordScreen extends StatefulWidget {
  final User patient;

  const PatientHealthRecordScreen({super.key, required this.patient});

  @override
  State<PatientHealthRecordScreen> createState() =>
      _PatientHealthRecordScreenState();
}

class _PatientHealthRecordScreenState
    extends State<PatientHealthRecordScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  late UserProvider _provider;

  List<Appointment> _visits = [];
  bool _loadingVisits = true;
  late bool _hasAllergies;

  @override
  void initState() {
    super.initState();
    _provider = context.read<UserProvider>();
    _hasAllergies = (widget.patient.allergies ?? '').trim().isNotEmpty;
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    try {
      final result = await context.read<AppointmentProvider>().get(filter: {
        "patientId": widget.patient.id,
        "pageSize": 200,
      });
      if (!mounted) return;
      final items = List<Appointment>.from(result.items ?? []);
      items.sort((a, b) => (b.scheduledAt ?? DateTime(0))
          .compareTo(a.scheduledAt ?? DateTime(0)));
      setState(() {
        _visits = items;
        _loadingVisits = false;
      });
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _loadingVisits = false);
        alertBox(context, 'Greška', e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.patient;
    final fullName = '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim();

    return MasterScreen(
      title: "Zdravstveni karton",
      currentSection: AppSection.users,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        _initials(p.firstName, p.lastName),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fullName.isEmpty ? '—' : fullName,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                          [
                            if ((p.username ?? '').isNotEmpty) p.username!,
                            if (p.createdAt != null)
                              "Korisnik od ${p.createdAt!.toLocal().year}.",
                          ].join(' · '),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),
                _buildStats(),
                const SizedBox(height: 16.0),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildForm(),
                  ),
                ),
                const SizedBox(height: 24.0),
                _buildActions(),
                const SizedBox(height: 24.0),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Historija posjeta",
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8.0),
                _buildHistory(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    final completed = _visits
        .where((a) =>
            AppointmentStatusX.fromInt(a.status) == AppointmentStatus.completed)
        .toList();
    final totalSpent =
        completed.fold<double>(0, (sum, a) => sum + (a.price ?? 0));

    final now = DateTime.now();
    final upcoming = _visits.where((a) {
      final s = AppointmentStatusX.fromInt(a.status);
      return (s == AppointmentStatus.pending || s == AppointmentStatus.confirmed) &&
          (a.scheduledAt?.isAfter(now) ?? false);
    }).toList()
      ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));

    // _visits is sorted newest-first, so the first completed entry is the most
    // recent past visit.
    final lastVisit = completed.isNotEmpty ? completed.first : null;
    final nextVisit = upcoming.isNotEmpty ? upcoming.first : null;

    String fmt(DateTime? d) {
      if (d == null) return '—';
      final l = d.toLocal();
      return "${l.day.toString().padLeft(2, '0')}.${l.month.toString().padLeft(2, '0')}.${l.year}.";
    }

    return Row(
      children: [
        StatCard(
          icon: Icons.event_outlined,
          label: "Ukupno posjeta",
          value: _loadingVisits ? '—' : _visits.length.toString(),
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.payments_outlined,
          label: "Potrošeno",
          value: _loadingVisits ? '—' : "${totalSpent.toStringAsFixed(0)} KM",
          color: AppColors.success,
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.history,
          label: "Zadnja posjeta",
          value: _loadingVisits ? '—' : fmt(lastVisit?.scheduledAt),
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.event_available_outlined,
          label: "Sljedeća posjeta",
          value: _loadingVisits ? '—' : fmt(nextVisit?.scheduledAt),
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildForm() {
    final p = widget.patient;
    return FormBuilder(
      key: _formKey,
      initialValue: {
        'bloodType': p.bloodType,
        'allergies': p.allergies ?? '',
        'medicalNotes': p.medicalNotes ?? '',
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormBuilderDropdown<String>(
            name: 'bloodType',
            decoration: const InputDecoration(labelText: "Krvna grupa"),
            items: _bloodTypes
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
          ),
          const SizedBox(height: 16.0),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: _hasAllergies ? const EdgeInsets.all(10) : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: _hasAllergies ? AppColors.dangerContainer : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_hasAllergies)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 16, color: AppColors.danger),
                        SizedBox(width: 6),
                        Text("Pacijent ima poznate alergije",
                            style: TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                FormBuilderTextField(
                  name: 'allergies',
                  decoration: const InputDecoration(
                    labelText: "Alergije",
                    hintText: "npr. penicilin, lateks...",
                  ),
                  maxLines: 2,
                  onChanged: (v) => setState(
                      () => _hasAllergies = (v ?? '').trim().isNotEmpty),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          FormBuilderTextField(
            name: 'medicalNotes',
            decoration: const InputDecoration(
              labelText: "Medicinske napomene",
              hintText: "Hronična stanja, terapije, napomene za doktora...",
            ),
            maxLines: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loadingVisits
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            : _visits.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text("Nema zabilježenih posjeta.",
                        style: TextStyle(color: Colors.grey)),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < _visits.length; i++) ...[
                        if (i > 0) const Divider(height: 24),
                        _buildVisitTile(_visits[i]),
                      ],
                    ],
                  ),
      ),
    );
  }

  Widget _buildVisitTile(Appointment a) {
    final status = AppointmentStatusX.fromInt(a.status);
    final d = a.scheduledAt?.toLocal();
    final dateLabel = d == null
        ? ''
        : "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}. u ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

    final dotColor = switch (status) {
      AppointmentStatus.completed => AppColors.success,
      AppointmentStatus.cancelled => AppColors.danger,
      _ => AppColors.primary,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "${a.dentalServiceName ?? ''} — ${a.doctorName ?? ''}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  StatusBadge.appointment(status),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                "$dateLabel${a.price != null ? ' · ${a.price} KM' : ''}",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (status == AppointmentStatus.cancelled &&
                  (a.cancellationReason?.trim().isNotEmpty ?? false))
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    "Razlog: ${a.cancellationReason}",
                    style: const TextStyle(fontSize: 12, color: AppColors.danger),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Odustani"),
        ),
        const SizedBox(width: 16.0),
        ElevatedButton(onPressed: _save, child: const Text("Sačuvaj")),
      ],
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final values = _formKey.currentState!.value;
    final p = widget.patient;

    try {
      await _provider.update(p.id!, {
        'firstName': p.firstName,
        'lastName': p.lastName,
        'email': p.email,
        'username': p.username,
        'phoneNumber': p.phoneNumber,
        'isActive': p.isActive ?? true,
        'profileImageAssetId': p.profileImageAssetId,
        'bloodType': values['bloodType'],
        'allergies': values['allergies'],
        'medicalNotes': values['medicalNotes'],
      });

      if (!mounted) return;
      Navigator.of(context).pop("reload");
    } catch (e) {
      if (!mounted) return;
      alertBox(context, "Greška", "Greška prilikom čuvanja: $e");
    }
  }

  String _initials(String? first, String? last) {
    final f = (first?.isNotEmpty == true) ? first![0].toUpperCase() : '';
    final l = (last?.isNotEmpty == true) ? last![0].toUpperCase() : '';
    return '$f$l';
  }
}
