import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doctor.dart';
import '../models/doctor_working_hours.dart';
import '../providers/doctor_working_hours_provider.dart';
import '../utils/utils_widgets.dart';

// C# System.DayOfWeek ordinals: Sunday=0 .. Saturday=6.
const List<String> _dayNames = [
  "Nedjelja",
  "Ponedjeljak",
  "Utorak",
  "Srijeda",
  "Četvrtak",
  "Petak",
  "Subota",
];

/// Opened from the "Raspored" button on a doctor's card instead of navigating
/// to the clinic-wide working-hours section — scoped to just this doctor.
Future<void> showDoctorWorkingHoursDialog(BuildContext context, Doctor doctor) {
  return showDialog(
    context: context,
    builder: (context) => _DoctorWorkingHoursDialog(doctor: doctor),
  );
}

class _DoctorWorkingHoursDialog extends StatefulWidget {
  final Doctor doctor;
  const _DoctorWorkingHoursDialog({required this.doctor});

  @override
  State<_DoctorWorkingHoursDialog> createState() =>
      _DoctorWorkingHoursDialogState();
}

class _DoctorWorkingHoursDialogState extends State<_DoctorWorkingHoursDialog> {
  late DoctorWorkingHoursProvider _provider;
  List<DoctorWorkingHours> _hours = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _provider = context.read<DoctorWorkingHoursProvider>();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await _provider
          .get(filter: {"doctorId": widget.doctor.id, "pageSize": 200});
      if (!mounted) return;
      final items = result.items ?? [];
      items.sort((a, b) => (a.dayOfWeek ?? 0).compareTo(b.dayOfWeek ?? 0));
      setState(() {
        _hours = items;
        _isLoading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      alertBox(context, "Greška", e.toString());
    }
  }

  TimeOfDay? _parseTime(String? hhmmss) {
    if (hhmmss == null) return null;
    final parts = hhmmss.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00";

  @override
  Widget build(BuildContext context) {
    final name =
        "${widget.doctor.firstName ?? ''} ${widget.doctor.lastName ?? ''}".trim();
    return AlertDialog(
      title: Text("Radno vrijeme — $name"),
      content: SizedBox(
        width: 420,
        child: _isLoading
            ? const SizedBox(
                height: 100, child: Center(child: CircularProgressIndicator()))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hours.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text("Nema definisanog radnog vremena.",
                          style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _hours.length,
                        itemBuilder: (context, index) {
                          final h = _hours[index];
                          return ListTile(
                            dense: true,
                            title: Text(_dayNames[h.dayOfWeek ?? 0]),
                            subtitle: Text(
                                "${(h.startTime ?? '').substring(0, 5)} – ${(h.endTime ?? '').substring(0, 5)}"),
                            onTap: () => _openForm(existing: h),
                            trailing: IconButton(
                              tooltip: "Ukloni",
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmDelete(h),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add),
                    label: const Text("Novi termin"),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Zatvori"),
        ),
      ],
    );
  }

  Future<void> _openForm({DoctorWorkingHours? existing}) async {
    int dayOfWeek = existing?.dayOfWeek ?? 1;
    TimeOfDay start =
        _parseTime(existing?.startTime) ?? const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay end =
        _parseTime(existing?.endTime) ?? const TimeOfDay(hour: 16, minute: 0);
    String? timeError;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? "Novi termin" : "Uredi termin"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: dayOfWeek,
                decoration: const InputDecoration(labelText: "Dan u sedmici"),
                items: List.generate(
                  7,
                  (i) => DropdownMenuItem(value: i, child: Text(_dayNames[i])),
                ),
                onChanged: existing == null
                    ? (v) => setDialogState(() => dayOfWeek = v ?? 1)
                    : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text("Od"),
                trailing: Text(_formatTime(start).substring(0, 5)),
                onTap: () async {
                  final picked =
                      await showTimePicker(context: context, initialTime: start);
                  if (picked != null) {
                    setDialogState(() {
                      start = picked;
                      timeError = null;
                    });
                  }
                },
              ),
              ListTile(
                title: const Text("Do"),
                subtitle: timeError != null
                    ? Text(timeError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12))
                    : null,
                trailing: Text(_formatTime(end).substring(0, 5)),
                onTap: () async {
                  final picked =
                      await showTimePicker(context: context, initialTime: end);
                  if (picked != null) {
                    setDialogState(() {
                      end = picked;
                      timeError = null;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Odustani"),
            ),
            ElevatedButton(
              onPressed: () async {
                final startMinutes = start.hour * 60 + start.minute;
                final endMinutes = end.hour * 60 + end.minute;
                setDialogState(() {
                  timeError = endMinutes <= startMinutes
                      ? "Vrijeme do mora biti nakon vremena od"
                      : null;
                });
                if (timeError != null) return;

                try {
                  if (existing == null) {
                    await _provider.insert({
                      "doctorId": widget.doctor.id,
                      "dayOfWeek": dayOfWeek,
                      "startTime": _formatTime(start),
                      "endTime": _formatTime(end),
                    });
                  } else {
                    await _provider.update(existing.id!, {
                      "startTime": _formatTime(start),
                      "endTime": _formatTime(end),
                    });
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context, true);
                } on Exception catch (e) {
                  if (!context.mounted) return;
                  alertBox(context, "Greška", e.toString());
                }
              },
              child: const Text("Sačuvaj"),
            ),
          ],
        ),
      ),
    );

    if (saved == true) _load();
  }

  void _confirmDelete(DoctorWorkingHours h) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Brisanje"),
        content: const Text("Ukloniti ovaj termin radnog vremena?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Odustani"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _provider.remove(h.id!);
                if (!context.mounted) return;
                Navigator.pop(context);
                _load();
              } on Exception catch (ex) {
                if (!context.mounted) return;
                alertBox(context, "Greška", ex.toString());
              }
            },
            child: const Text("Da"),
          ),
        ],
      ),
    );
  }
}
