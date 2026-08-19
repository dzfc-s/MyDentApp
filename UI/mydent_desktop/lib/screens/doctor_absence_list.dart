import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/doctor.dart';
import '../models/doctor_absence.dart';
import '../models/search_result.dart';
import '../providers/doctor_absence_provider.dart';
import '../providers/doctor_provider.dart';
import '../utils/utils_widgets.dart';

class DoctorAbsenceList extends StatefulWidget {
  const DoctorAbsenceList({super.key});

  @override
  State<DoctorAbsenceList> createState() => _DoctorAbsenceListState();
}

class _DoctorAbsenceListState extends State<DoctorAbsenceList> {
  late DoctorAbsenceProvider _provider;
  late DoctorProvider _doctorProvider;

  SearchResult<DoctorAbsence>? result;
  SearchResult<Doctor>? doctors;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _provider = context.read<DoctorAbsenceProvider>();
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
      title: "Odsustva doktora",
      currentSection: AppSection.doctorAbsences,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _openDialog(null),
                child: const Text("Novo odsustvo"),
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
              DataColumn(label: Text("Od")),
              DataColumn(label: Text("Do")),
              DataColumn(label: Text("Razlog")),
              DataColumn(label: Text("Obriši")),
            ],
            rows: result?.items
                    ?.map(
                      (e) => DataRow(
                        onSelectChanged: (v) => _openDialog(e),
                        cells: [
                          DataCell(Text(e.doctorName ?? '')),
                          DataCell(Text(e.startDate ?? '')),
                          DataCell(Text(e.endDate ?? '')),
                          DataCell(Text(e.reason ?? '')),
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

  DateTime? _parseDate(String? yyyyMmDd) =>
      yyyyMmDd == null ? null : DateTime.tryParse(yyyyMmDd);

  String _formatDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  void _openDialog(DoctorAbsence? existing) {
    int? doctorId = existing?.doctorId;
    DateTime start = _parseDate(existing?.startDate) ?? DateTime.now();
    DateTime end = _parseDate(existing?.endDate) ?? DateTime.now();
    final reasonController = TextEditingController(text: existing?.reason ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? "Novo odsustvo" : "Uredi odsustvo"),
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
              ListTile(
                title: const Text("Od"),
                trailing: Text(_formatDate(start)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: start,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setDialogState(() => start = picked);
                },
              ),
              ListTile(
                title: const Text("Do"),
                trailing: Text(_formatDate(end)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: end,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setDialogState(() => end = picked);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: "Razlog"),
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
                      "startDate": _formatDate(start),
                      "endDate": _formatDate(end),
                      "reason": reasonController.text,
                    });
                  } else {
                    await _provider.update(existing.id!, {
                      "startDate": _formatDate(start),
                      "endDate": _formatDate(end),
                      "reason": reasonController.text,
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

  void _confirmDelete(DoctorAbsence e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Brisanje"),
        content: const Text("Ukloniti ovo odsustvo?"),
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
