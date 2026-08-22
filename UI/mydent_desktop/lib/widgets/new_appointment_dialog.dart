import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/available_slot.dart';
import '../models/dental_service.dart';
import '../models/doctor.dart';
import '../models/doctor_specialty.dart';
import '../models/search_result.dart';
import '../models/user.dart';
import '../providers/appointment_provider.dart';
import '../providers/dental_service_provider.dart';
import '../providers/doctor_provider.dart';
import '../providers/doctor_specialty_provider.dart';
import '../providers/user_provider.dart';
import '../utils/slot_utils.dart';
import '../utils/utils_widgets.dart';

/// Admin-only "Novi termin" dialog — books an appointment on behalf of a
/// patient. Mirrors RescheduleAppointmentDialog's doctor/service/slot picking,
/// plus a patient search up front. Hits the same POST /Appointments the
/// patient-facing booking flow uses (AppointmentInsertValidator explicitly
/// allows an Admin caller to book for any PatientId).
class NewAppointmentDialog extends StatefulWidget {
  const NewAppointmentDialog({super.key});

  @override
  State<NewAppointmentDialog> createState() => _NewAppointmentDialogState();
}

class _NewAppointmentDialogState extends State<NewAppointmentDialog> {
  List<User> _patients = [];
  List<Doctor> _doctors = [];
  List<DentalService> _services = [];
  List<DoctorSpecialty> _specialties = [];
  bool _loadingOptions = true;

  User? _patient;
  int? _doctorId;
  int? _serviceId;
  DateTime _date = DateTime.now();

  List<AvailableSlot> _slots = [];
  bool _loadingSlots = false;
  AvailableSlot? _selectedSlot;
  DateTime? _nextAvailableDate;
  bool _searchingNextDate = false;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final results = await Future.wait<dynamic>([
        context.read<UserProvider>().get(filter: {"role": "Patient", "pageSize": 500}),
        context.read<DoctorProvider>().get(filter: {"isActive": true}),
        context.read<DentalServiceProvider>().get(filter: {"isActive": true}),
        context.read<DoctorSpecialtyProvider>().get(filter: {"pageSize": 1000}),
      ]);
      if (!mounted) return;
      setState(() {
        _patients = (results[0] as SearchResult<User>).items ?? [];
        _doctors = (results[1] as SearchResult<Doctor>).items ?? [];
        _services = (results[2] as SearchResult<DentalService>).items ?? [];
        _specialties = (results[3] as SearchResult<DoctorSpecialty>).items ?? [];
        _loadingOptions = false;
      });
    } on Exception catch (e) {
      if (mounted) alertBox(context, 'Greška', e.toString());
    }
  }

  /// Doctors not specialized in the selected service's category are hidden
  /// rather than just disallowed at save time — picking a service/doctor pair
  /// the backend would reject anyway wastes a round trip and confuses the
  /// "why can't I book this" moment. Service comes first (not doctor) since
  /// that's the natural question ("what does the patient need?") and it's
  /// the same order the patient-facing mobile booking flow already uses.
  List<Doctor> get _availableDoctors {
    if (_serviceId == null) return _doctors;
    int? categoryId;
    for (final s in _services) {
      if (s.id == _serviceId) {
        categoryId = s.serviceCategoryId;
        break;
      }
    }
    if (categoryId == null) return _doctors;
    final doctorIds = _specialties
        .where((s) => s.serviceCategoryId == categoryId)
        .map((s) => s.doctorId)
        .toSet();
    return _doctors.where((d) => doctorIds.contains(d.id)).toList();
  }

  Future<void> _loadSlots() async {
    if (_doctorId == null || _serviceId == null) return;
    setState(() {
      _loadingSlots = true;
      _selectedSlot = null;
      _slots = [];
      _nextAvailableDate = null;
    });
    final provider = context.read<AppointmentProvider>();
    try {
      final slots = await provider.getAvailableSlots(
        doctorId: _doctorId!,
        dentalServiceId: _serviceId!,
        date: _date,
      );
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _loadingSlots = false;
      });

      if (slots.isEmpty) {
        setState(() => _searchingNextDate = true);
        final next = await findNextAvailableDate(
          provider: provider,
          doctorId: _doctorId!,
          dentalServiceId: _serviceId!,
          startDate: _date,
        );
        if (!mounted) return;
        setState(() {
          _nextAvailableDate = next;
          _searchingNextDate = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _loadingSlots = false);
        alertBox(context, 'Greška', e.toString());
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _date = picked);
    _loadSlots();
  }

  Future<void> _save() async {
    if (_patient?.id == null ||
        _doctorId == null ||
        _serviceId == null ||
        _selectedSlot?.startTime == null) {
      alertBox(context, 'Greška', 'Odaberite pacijenta, doktora, uslugu i termin.');
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AppointmentProvider>().insert({
        "patientId": _patient!.id,
        "doctorId": _doctorId,
        "dentalServiceId": _serviceId,
        "scheduledAt": _selectedSlot!.startTime!.toIso8601String(),
      });
      if (mounted) Navigator.pop(context, true);
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        alertBox(context, 'Greška', e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Novi termin"),
      content: SizedBox(
        width: 460,
        child: _loadingOptions
            ? const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Autocomplete<User>(
                      displayStringForOption: (u) =>
                          "${u.firstName ?? ''} ${u.lastName ?? ''}".trim(),
                      optionsBuilder: (value) {
                        if (value.text.isEmpty) return _patients;
                        final q = value.text.toLowerCase();
                        return _patients.where((u) {
                          final name =
                              "${u.firstName ?? ''} ${u.lastName ?? ''} ${u.username ?? ''} ${u.email ?? ''}"
                                  .toLowerCase();
                          return name.contains(q);
                        });
                      },
                      onSelected: (u) => setState(() => _patient = u),
                      fieldViewBuilder:
                          (context, controller, focusNode, onSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: "Pacijent",
                            hintText: "Pretraži po imenu, korisničkom imenu ili emailu",
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _serviceId,
                      decoration: const InputDecoration(labelText: "Usluga"),
                      items: _services
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name ?? ''),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _serviceId = v;
                          // The previously picked doctor may not be specialized in
                          // this service's category anymore.
                          if (!_availableDoctors.any((d) => d.id == _doctorId)) {
                            _doctorId = null;
                          }
                        });
                        _loadSlots();
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_serviceId != null && _availableDoctors.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          "Trenutno nema dostupnog doktora za ovu uslugu. "
                          "Pratite obavještenja klinike za ažuriranja.",
                          style: TextStyle(color: Colors.red[700], fontSize: 12),
                        ),
                      ),
                    DropdownButtonFormField<int>(
                      initialValue: _doctorId,
                      decoration: InputDecoration(
                        labelText: "Doktor",
                        helperText: _serviceId == null
                            ? "Prvo odaberite uslugu"
                            : "Prikazani su samo doktori specijalizovani za ovu uslugu",
                      ),
                      items: _availableDoctors
                          .map((d) => DropdownMenuItem(
                                value: d.id,
                                child: Text("${d.firstName} ${d.lastName}"),
                              ))
                          .toList(),
                      onChanged: _serviceId == null
                          ? null
                          : (v) {
                              setState(() => _doctorId = v);
                              _loadSlots();
                            },
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: "Datum"),
                        child: Text(formatShortDate(_date)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Termin",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _serviceId == null || _doctorId == null
                        ? const Text(
                            "Odaberite uslugu i doktora da vidite dostupne termine.",
                            style: TextStyle(color: Colors.grey),
                          )
                        : _loadingSlots
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _slots.isEmpty
                            ? (_searchingNextDate
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        SizedBox(width: 8),
                                        Text("Tražim sljedeći slobodan termin...",
                                            style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  )
                                : Text(
                                    _nextAvailableDate != null
                                        ? "Na odabrani datum nema slobodnog termina. Prvi sljedeći slobodan termin: ${formatShortDate(_nextAvailableDate!)}"
                                        : "Na odabrani datum nema slobodnog termina.",
                                    style: const TextStyle(color: Colors.grey),
                                  ))
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _slots.map((s) {
                                  final t = s.startTime!.toLocal();
                                  final label =
                                      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
                                  final selected =
                                      _selectedSlot?.startTime == s.startTime;
                                  return ChoiceChip(
                                    label: Text(label),
                                    selected: selected,
                                    onSelected: (_) =>
                                        setState(() => _selectedSlot = s),
                                  );
                                }).toList(),
                              ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text("Odustani"),
        ),
        ElevatedButton(
          onPressed: _saving || _loadingOptions ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Zakaži"),
        ),
      ],
    );
  }
}
