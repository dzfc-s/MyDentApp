import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../models/available_slot.dart';
import '../providers/appointment_provider.dart';
import '../utils/slot_utils.dart';
import '../utils/utils_widgets.dart';

/// Admin-only "Izmjena termina" dialog — moves an existing Pending/Confirmed
/// appointment to a new date/time. Doctor and service are fixed to whatever
/// the appointment already has: changing *who* or *what* isn't really a
/// reschedule, it's a different booking, so that's a cancel-and-rebook via
/// NewAppointmentDialog instead — keeping this dialog to just the date/time
/// also means it never needs the specialty-filtering NewAppointmentDialog
/// has to do. Only offers slots the backend's own availability check will
/// actually accept (the same GET /Appointments/available-slots the
/// patient-facing booking flow uses), so this mostly avoids round-tripping a
/// save the server would reject anyway.
class RescheduleAppointmentDialog extends StatefulWidget {
  final Appointment appointment;

  const RescheduleAppointmentDialog({super.key, required this.appointment});

  @override
  State<RescheduleAppointmentDialog> createState() =>
      _RescheduleAppointmentDialogState();
}

class _RescheduleAppointmentDialogState
    extends State<RescheduleAppointmentDialog> {
  late DateTime _date;

  List<AvailableSlot> _slots = [];
  bool _loadingSlots = false;
  AvailableSlot? _selectedSlot;

  DateTime? _nextAvailableDate;
  bool _searchingNextDate = false;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final scheduled = widget.appointment.scheduledAt?.toLocal();
    _date = scheduled != null
        ? DateTime(scheduled.year, scheduled.month, scheduled.day)
        : DateTime.now();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    final doctorId = widget.appointment.doctorId;
    final serviceId = widget.appointment.dentalServiceId;
    if (doctorId == null || serviceId == null) return;

    setState(() {
      _loadingSlots = true;
      _selectedSlot = null;
      _slots = [];
      _nextAvailableDate = null;
    });

    final scheduled = widget.appointment.scheduledAt?.toLocal();
    // The available-slots endpoint has no idea which appointment we're editing,
    // so it always treats this appointment's own current time as "taken" by
    // itself and won't offer it back. If the date still matches the original
    // booking, splice that slot back in so staff can keep the unchanged time
    // instead of the picker looking emptier than it should.
    final sameDateAsOriginal = scheduled != null &&
        scheduled.year == _date.year &&
        scheduled.month == _date.month &&
        scheduled.day == _date.day;

    final provider = context.read<AppointmentProvider>();
    try {
      final slots = await provider.getAvailableSlots(
        doctorId: doctorId,
        dentalServiceId: serviceId,
        date: _date,
      );
      if (!mounted) return;

      if (sameDateAsOriginal && !slots.any((s) => s.startTime == scheduled)) {
        slots.insert(
          0,
          AvailableSlot(
            startTime: scheduled,
            endTime: scheduled.add(
              Duration(minutes: widget.appointment.durationMinutes ?? 30),
            ),
          ),
        );
      }

      AvailableSlot? preselect;
      if (sameDateAsOriginal) {
        for (final s in slots) {
          if (s.startTime == scheduled) {
            preselect = s;
            break;
          }
        }
      }

      setState(() {
        _slots = slots;
        _loadingSlots = false;
        _selectedSlot = preselect;
      });

      if (slots.isEmpty) {
        setState(() => _searchingNextDate = true);
        final next = await findNextAvailableDate(
          provider: provider,
          doctorId: doctorId,
          dentalServiceId: serviceId,
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
    final doctorId = widget.appointment.doctorId;
    final serviceId = widget.appointment.dentalServiceId;
    if (doctorId == null || serviceId == null || _selectedSlot?.startTime == null) {
      alertBox(context, 'Greška', 'Odaberite termin.');
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AppointmentProvider>().reschedule(
            widget.appointment.id!,
            doctorId: doctorId,
            dentalServiceId: serviceId,
            scheduledAt: _selectedSlot!.startTime!,
          );
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
    final a = widget.appointment;
    return AlertDialog(
      title: const Text("Izmjena termina"),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Pacijent: ${a.patientName ?? ''}",
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text("Doktor: ${a.doctorName ?? ''}"),
              Text("Usluga: ${a.dentalServiceName ?? ''}"),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  "Doktor i usluga se ne mijenjaju ovdje — za to otkažite termin i zakažite novi.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: "Datum"),
                  child: Text(formatShortDate(_date)),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Termin", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _loadingSlots
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _slots.isEmpty
                      ? _searchingNextDate
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
                            )
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
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Sačuvaj izmjene"),
        ),
      ],
    );
  }
}
