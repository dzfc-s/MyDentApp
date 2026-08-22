import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doctor.dart';
import '../models/doctor_absence.dart';
import '../providers/doctor_absence_provider.dart';
import '../utils/utils_widgets.dart';

/// Opened from a doctor's own card/details instead of navigating to the
/// clinic-wide "Odsustva" section — scoped to just this doctor, so managing
/// one doctor's absences doesn't require finding them in a flat all-doctors
/// table.
Future<void> showDoctorAbsencesDialog(BuildContext context, Doctor doctor) {
  return showDialog(
    context: context,
    builder: (context) => _DoctorAbsencesDialog(doctor: doctor),
  );
}

class _DoctorAbsencesDialog extends StatefulWidget {
  final Doctor doctor;
  const _DoctorAbsencesDialog({required this.doctor});

  @override
  State<_DoctorAbsencesDialog> createState() => _DoctorAbsencesDialogState();
}

class _DoctorAbsencesDialogState extends State<_DoctorAbsencesDialog> {
  late DoctorAbsenceProvider _provider;
  List<DoctorAbsence> _absences = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _provider = context.read<DoctorAbsenceProvider>();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await _provider
          .get(filter: {"doctorId": widget.doctor.id, "pageSize": 200});
      if (!mounted) return;
      setState(() {
        _absences = result.items ?? [];
        _isLoading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      alertBox(context, "Greška", e.toString());
    }
  }

  DateTime? _parseDate(String? yyyyMmDd) =>
      yyyyMmDd == null ? null : DateTime.tryParse(yyyyMmDd);

  String _formatDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    final name = "${widget.doctor.firstName ?? ''} ${widget.doctor.lastName ?? ''}".trim();
    return AlertDialog(
      title: Text("Odsustva — $name"),
      content: SizedBox(
        width: 420,
        child: _isLoading
            ? const SizedBox(
                height: 100, child: Center(child: CircularProgressIndicator()))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_absences.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text("Nema evidentiranih odsustava.",
                          style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _absences.length,
                        itemBuilder: (context, index) {
                          final a = _absences[index];
                          return ListTile(
                            dense: true,
                            title: Text("${a.startDate} – ${a.endDate}"),
                            subtitle: Text(a.reason ?? ''),
                            onTap: () => _openForm(existing: a),
                            trailing: IconButton(
                              tooltip: "Ukloni",
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmDelete(a),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add),
                    label: const Text("Novo odsustvo"),
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

  Future<void> _openForm({DoctorAbsence? existing}) async {
    final formKey = GlobalKey<FormState>();
    DateTime start = _parseDate(existing?.startDate) ?? DateTime.now();
    DateTime end = _parseDate(existing?.endDate) ?? DateTime.now();
    final reasonController = TextEditingController(text: existing?.reason ?? '');
    String? startError;
    String? endError;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? "Novo odsustvo" : "Uredi odsustvo"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text("Od"),
                  subtitle: startError != null
                      ? Text(startError!,
                          style: const TextStyle(color: Colors.red, fontSize: 12))
                      : null,
                  trailing: Text(_formatDate(start)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: start,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        start = picked;
                        startError = null;
                      });
                    }
                  },
                ),
                ListTile(
                  title: const Text("Do"),
                  subtitle: endError != null
                      ? Text(endError!,
                          style: const TextStyle(color: Colors.red, fontSize: 12))
                      : null,
                  trailing: Text(_formatDate(end)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: end,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        end = picked;
                        endError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: "Razlog"),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? "Razlog je obavezan"
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Odustani"),
            ),
            ElevatedButton(
              onPressed: () async {
                final formValid = formKey.currentState?.validate() ?? false;
                setDialogState(() {
                  endError =
                      end.isBefore(start) ? "Datum do mora biti nakon datuma od" : null;
                });
                if (!formValid || endError != null) return;

                try {
                  if (existing == null) {
                    await _provider.insert({
                      "doctorId": widget.doctor.id,
                      "startDate": _formatDate(start),
                      "endDate": _formatDate(end),
                      "reason": reasonController.text.trim(),
                    });
                  } else {
                    await _provider.update(existing.id!, {
                      "startDate": _formatDate(start),
                      "endDate": _formatDate(end),
                      "reason": reasonController.text.trim(),
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

  void _confirmDelete(DoctorAbsence a) {
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
                await _provider.remove(a.id!);
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
