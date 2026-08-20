import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/appointment.dart';
import '../models/enums.dart';
import '../models/search_result.dart';
import '../providers/appointment_provider.dart';
import '../theme/app_theme.dart';
import '../utils/utils_widgets.dart';
import '../widgets/stat_card.dart';

class AppointmentList extends StatefulWidget {
  const AppointmentList({super.key});

  @override
  State<AppointmentList> createState() => _AppointmentListState();
}

class _AppointmentListState extends State<AppointmentList> {
  late AppointmentProvider _provider;
  SearchResult<Appointment>? result;
  bool isLoading = true;
  AppointmentStatus? _statusFilter;

  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _doctorNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider = context.read<AppointmentProvider>();
    initTable();
  }

  Future<void> initTable() async {
    try {
      var data = await _provider.get(filter: {
        if (_statusFilter != null) "status": _statusFilter!.index,
        if (_patientNameController.text.isNotEmpty)
          "patientName": _patientNameController.text,
        if (_doctorNameController.text.isNotEmpty)
          "doctorName": _doctorNameController.text,
      });
      setState(() {
        result = data;
        isLoading = false;
      });
    } on Exception catch (e) {
      alertBox(context, 'Greška', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: "Termini",
      currentSection: AppSection.appointments,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!isLoading) ...[
              _buildStats(),
              const SizedBox(height: 8),
            ],
            _buildFilter(),
            isLoading
                ? const Expanded(
                    child: Center(child: CircularProgressIndicator()))
                : _buildTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final appointments = result?.items ?? [];
    final pending = appointments
        .where((a) => AppointmentStatusX.fromInt(a.status) == AppointmentStatus.pending)
        .length;
    final confirmed = appointments
        .where((a) => AppointmentStatusX.fromInt(a.status) == AppointmentStatus.confirmed)
        .length;
    final completed = appointments
        .where((a) => AppointmentStatusX.fromInt(a.status) == AppointmentStatus.completed)
        .length;
    return Row(
      children: [
        StatCard(
          icon: Icons.event_outlined,
          label: "Ukupno termina",
          value: appointments.length.toString(),
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.hourglass_empty_outlined,
          label: "Na čekanju",
          value: pending.toString(),
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.event_available_outlined,
          label: "Potvrđeni",
          value: confirmed.toString(),
          color: Theme.of(context).colorScheme.tertiary,
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.task_alt_outlined,
          label: "Završeni",
          value: completed.toString(),
        ),
      ],
    );
  }

  Padding _buildFilter() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _patientNameController,
              decoration: const InputDecoration(labelText: "Pacijent"),
              onSubmitted: (_) => initTable(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _doctorNameController,
              decoration: const InputDecoration(labelText: "Doktor"),
              onSubmitted: (_) => initTable(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<AppointmentStatus?>(
              initialValue: _statusFilter,
              decoration: const InputDecoration(labelText: "Status"),
              items: [
                const DropdownMenuItem(value: null, child: Text("Svi")),
                ...AppointmentStatus.values.map(
                  (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                ),
              ],
              onChanged: (v) {
                setState(() {
                  _statusFilter = v;
                  isLoading = true;
                });
                initTable();
              },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              setState(() => isLoading = true);
              initTable();
            },
            child: const Text("Pretraga"),
          ),
        ],
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
              DataColumn(label: Text("Pacijent")),
              DataColumn(label: Text("Doktor")),
              DataColumn(label: Text("Usluga")),
              DataColumn(label: Text("Termin")),
              DataColumn(label: Text("Cijena")),
              DataColumn(label: Text("Status")),
              DataColumn(label: Text("Akcije")),
            ],
            rows: result?.items
                    ?.map(
                      (e) => DataRow(
                        onSelectChanged: (v) => _showHistory(e),
                        cells: [
                          DataCell(Text(e.patientName ?? '')),
                          DataCell(Text(e.doctorName ?? '')),
                          DataCell(Text(e.dentalServiceName ?? '')),
                          DataCell(Text(e.scheduledAt?.toLocal().toString().substring(0, 16) ?? '')),
                          DataCell(Text(e.price != null ? "${e.price} KM" : '')),
                          DataCell(StatusBadge.appointment(AppointmentStatusX.fromInt(e.status))),
                          DataCell(_buildActions(e)),
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

  Widget _buildActions(Appointment e) {
    final status = AppointmentStatusX.fromInt(e.status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == AppointmentStatus.pending)
          IconButton(
            tooltip: "Potvrdi",
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: () => _confirm(e),
          ),
        if (status == AppointmentStatus.confirmed)
          IconButton(
            tooltip: "Završi",
            icon: const Icon(Icons.task_alt),
            onPressed: () => _complete(e),
          ),
        if (status == AppointmentStatus.pending ||
            status == AppointmentStatus.confirmed)
          IconButton(
            tooltip: "Otkaži",
            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
            onPressed: () => _cancel(e),
          ),
        IconButton(
          tooltip: "Historija",
          icon: const Icon(Icons.history),
          onPressed: () => _showHistory(e),
        ),
      ],
    );
  }

  Future _confirm(Appointment e) async {
    try {
      await _provider.confirm(e.id!);
      initTable();
    } on Exception catch (ex) {
      alertBox(context, "Greška", ex.toString());
    }
  }

  Future _complete(Appointment e) async {
    try {
      await _provider.complete(e.id!);
      initTable();
    } on Exception catch (ex) {
      alertBox(context, "Greška", ex.toString());
    }
  }

  Future _cancel(Appointment e) async {
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
            decoration: const InputDecoration(labelText: "Razlog otkazivanja"),
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
      await _provider.cancel(e.id!, reason);
      initTable();
    } on Exception catch (ex) {
      alertBox(context, "Greška", ex.toString());
    }
  }

  Future _showHistory(Appointment e) async {
    try {
      final history = await _provider.history(e.id!);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Historija statusa"),
          content: SizedBox(
            width: 400,
            child: ListView(
              shrinkWrap: true,
              children: history
                  .map((h) => ListTile(
                        title: Text(
                            "${AppointmentStatusX.fromInt(h.fromStatus).label} → ${AppointmentStatusX.fromInt(h.toStatus).label}"),
                        subtitle: Text(
                            "${h.changedByUserName ?? ''} — ${h.reason ?? ''}\n${h.changedAt?.toLocal().toString().substring(0, 16) ?? ''}"),
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Zatvori"),
            ),
          ],
        ),
      );
    } on Exception catch (ex) {
      alertBox(context, "Greška", ex.toString());
    }
  }
}
