import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/doctor.dart';
import '../models/doctor_working_hours.dart';
import '../models/search_result.dart';
import '../providers/doctor_provider.dart';
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

class DoctorWorkingHoursList extends StatefulWidget {
  const DoctorWorkingHoursList({super.key});

  @override
  State<DoctorWorkingHoursList> createState() =>
      _DoctorWorkingHoursListState();
}

class _DoctorWorkingHoursListState extends State<DoctorWorkingHoursList> {
  late DoctorWorkingHoursProvider _provider;
  late DoctorProvider _doctorProvider;

  SearchResult<DoctorWorkingHours>? result;
  SearchResult<Doctor>? doctors;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _provider = context.read<DoctorWorkingHoursProvider>();
    _doctorProvider = context.read<DoctorProvider>();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _provider.get(filter: {});
      final d = await _doctorProvider.get(filter: {});
      setState(() {
        result = data;
        doctors = d;
        isLoading = false;
      });
    } on Exception catch (e) {
      alertBox(context, 'Greška', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: "Radno vrijeme doktora",
      currentSection: AppSection.doctorWorkingHours,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _openDialog(null),
                child: const Text("Dodaj termin"),
              ),
            ),
            const SizedBox(height: 8),
            isLoading
                ? const Expanded(
                    child: Center(child: CircularProgressIndicator()))
                : _buildTable(),
          ],
        ),
      ),
    );
  }

  Expanded _buildTable() {
    return Expanded(
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text("Doktor")),
              DataColumn(label: Text("Dan")),
              DataColumn(label: Text("Od")),
              DataColumn(label: Text("Do")),
              DataColumn(label: Text("Obriši")),
            ],
            rows: result?.items
                    ?.map(
                      (e) => DataRow(
                        onSelectChanged: (v) => _openDialog(e),
                        cells: [
                          DataCell(Text(e.doctorName ?? '')),
                          DataCell(Text(_dayNames[e.dayOfWeek ?? 0])),
                          DataCell(Text(e.startTime ?? '')),
                          DataCell(Text(e.endTime ?? '')),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _confirmDelete(e),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList() ??
                List.empty(),
          ),
        ),
      ),
    );
  }

  TimeOfDay? _parseTime(String? hhmmss) {
    if (hhmmss == null) return null;
    final parts = hhmmss.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00";

  void _openDialog(DoctorWorkingHours? existing) {
    int? doctorId = existing?.doctorId;
    int dayOfWeek = existing?.dayOfWeek ?? 1;
    TimeOfDay? start = _parseTime(existing?.startTime) ??
        const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay? end =
        _parseTime(existing?.endTime) ?? const TimeOfDay(hour: 16, minute: 0);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? "Novi termin" : "Uredi termin"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (existing == null)
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: "Doktor"),
                  items: doctors?.items
                          ?.map((d) => DropdownMenuItem(
                              value: d.id,
                              child: Text("${d.firstName} ${d.lastName}")))
                          .toList() ??
                      [],
                  onChanged: (v) => setDialogState(() => doctorId = v),
                )
              else
                Text("Doktor: ${existing.doctorName}"),
              const SizedBox(height: 12),
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
                trailing: Text(_formatTime(start!).substring(0, 5)),
                onTap: () async {
                  final picked =
                      await showTimePicker(context: context, initialTime: start!);
                  if (picked != null) setDialogState(() => start = picked);
                },
              ),
              ListTile(
                title: const Text("Do"),
                trailing: Text(_formatTime(end!).substring(0, 5)),
                onTap: () async {
                  final picked =
                      await showTimePicker(context: context, initialTime: end!);
                  if (picked != null) setDialogState(() => end = picked);
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
                try {
                  if (existing == null) {
                    if (doctorId == null) return;
                    await _provider.insert({
                      "doctorId": doctorId,
                      "dayOfWeek": dayOfWeek,
                      "startTime": _formatTime(start!),
                      "endTime": _formatTime(end!),
                    });
                  } else {
                    await _provider.update(existing.id!, {
                      "startTime": _formatTime(start!),
                      "endTime": _formatTime(end!),
                    });
                  }
                  if (!mounted) return;
                  Navigator.pop(context);
                  _load();
                } on Exception catch (e) {
                  alertBox(context, "Greška", e.toString());
                }
              },
              child: const Text("Sačuvaj"),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(DoctorWorkingHours e) {
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
                await _provider.remove(e.id!);
                if (!mounted) return;
                Navigator.pop(context);
                _load();
              } on Exception catch (ex) {
                alertBoxMoveBack(context, "Greška", ex.toString());
              }
            },
            child: const Text("Da"),
          ),
        ],
      ),
    );
  }
}
