import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/appointment.dart';
import '../models/enums.dart';
import '../models/search_result.dart';
import '../providers/appointment_provider.dart';
import '../theme/app_theme.dart';
import '../utils/utils_widgets.dart';
import '../widgets/new_appointment_dialog.dart';
import '../widgets/reschedule_appointment_dialog.dart';
import '../widgets/stat_card.dart';

class AppointmentList extends StatefulWidget {
  const AppointmentList({super.key, this.initialStatus});

  /// Pre-applies the status filter on open — used by the top bar's bell,
  /// which links straight to "termini na čekanju" instead of a separate
  /// notifications inbox.
  final AppointmentStatus? initialStatus;

  @override
  State<AppointmentList> createState() => _AppointmentListState();
}

enum _DateQuickFilter { today, tomorrow, thisWeek }

class _AppointmentListState extends State<AppointmentList> {
  static const _pageSize = 20;

  late AppointmentProvider _provider;
  SearchResult<Appointment>? result;
  bool isLoading = true;
  AppointmentStatus? _statusFilter;
  _DateQuickFilter? _dateFilter;
  int _page = 1;

  // Independent of `result` (which only ever holds the current page) — these
  // reflect the *whole* filtered result set, via cheap count-only requests,
  // so the cards don't shift as you page through instead of describing what
  // you searched for.
  int? _totalCount, _pendingCount, _confirmedCount, _completedCount;

  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _doctorNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatus;
    _provider = context.read<AppointmentProvider>();
    initTable();
    _loadStats();
  }

  (DateTime, DateTime)? _dateRangeFor(_DateQuickFilter? f) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (f) {
      case _DateQuickFilter.today:
        return (today, today.add(const Duration(days: 1)));
      case _DateQuickFilter.tomorrow:
        final tomorrow = today.add(const Duration(days: 1));
        return (tomorrow, tomorrow.add(const Duration(days: 1)));
      case _DateQuickFilter.thisWeek:
        // Monday-start week, matching how the rest of the app labels days
        // (see _dayNames elsewhere: Monday first).
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return (weekStart, weekStart.add(const Duration(days: 7)));
      case null:
        return null;
    }
  }

  /// Every non-status/non-paging filter currently active — shared between the
  /// paged table fetch and the count-only stats fetch below so both agree on
  /// "what you searched for".
  Map<String, dynamic> get _activeFilters {
    final range = _dateRangeFor(_dateFilter);
    return {
      if (_patientNameController.text.isNotEmpty)
        "patientName": _patientNameController.text,
      if (_doctorNameController.text.isNotEmpty)
        "doctorName": _doctorNameController.text,
      if (range != null) "dateFrom": range.$1.toIso8601String(),
      if (range != null) "dateTo": range.$2.toIso8601String(),
    };
  }

  Future<void> initTable() async {
    try {
      var data = await _provider.get(filter: {
        ..._activeFilters,
        "page": _page,
        "pageSize": _pageSize,
        "includeTotalCount": true,
        if (_statusFilter != null) "status": _statusFilter!.index,
      });
      if (!mounted) return;
      setState(() {
        result = data;
        isLoading = false;
      });
    } on Exception catch (e) {
      if (mounted) alertBox(context, 'Greška', e.toString());
    }
  }

  /// Cheap (pageSize:1, count-only) so this stays fast no matter how large
  /// the filtered result set is. Deliberately ignores the status filter
  /// itself — these cards are a breakdown *by* status, not a count of the
  /// status you happen to have selected.
  Future<void> _loadStats() async {
    try {
      final base = _activeFilters;
      final results = await Future.wait<dynamic>([
        _provider.get(filter: {...base, "pageSize": 1, "includeTotalCount": true}),
        _provider.get(filter: {
          ...base,
          "status": AppointmentStatus.pending.index,
          "pageSize": 1,
          "includeTotalCount": true,
        }),
        _provider.get(filter: {
          ...base,
          "status": AppointmentStatus.confirmed.index,
          "pageSize": 1,
          "includeTotalCount": true,
        }),
        _provider.get(filter: {
          ...base,
          "status": AppointmentStatus.completed.index,
          "pageSize": 1,
          "includeTotalCount": true,
        }),
      ]);
      if (!mounted) return;
      setState(() {
        _totalCount = (results[0] as SearchResult<Appointment>).totalCount;
        _pendingCount = (results[1] as SearchResult<Appointment>).totalCount;
        _confirmedCount = (results[2] as SearchResult<Appointment>).totalCount;
        _completedCount = (results[3] as SearchResult<Appointment>).totalCount;
      });
    } catch (_) {
      // Stats are a nice-to-have — a failed fetch here shouldn't block the table.
    }
  }

  /// Every filter/date-chip change starts back at page 1 — landing on
  /// (say) page 3 of a suddenly much-shorter filtered result would either
  /// show an empty page or silently clamp, both confusing.
  void _search() {
    setState(() {
      _page = 1;
      isLoading = true;
    });
    initTable();
    _loadStats();
  }

  void _goToPage(int page) {
    setState(() {
      _page = page;
      isLoading = true;
    });
    initTable();
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
            _buildDateQuickFilters(),
            _buildFilter(),
            isLoading
                ? const Expanded(
                    child: Center(child: CircularProgressIndicator()))
                : _buildTable(),
            if (!isLoading) _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    String show(int? v) => v?.toString() ?? '—';
    return Row(
      children: [
        StatCard(
          icon: Icons.event_outlined,
          label: "Ukupno termina",
          value: show(_totalCount),
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.hourglass_empty_outlined,
          label: "Na čekanju",
          value: show(_pendingCount),
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.event_available_outlined,
          label: "Potvrđeni",
          value: show(_confirmedCount),
          color: Theme.of(context).colorScheme.tertiary,
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.task_alt_outlined,
          label: "Završeni",
          value: show(_completedCount),
        ),
      ],
    );
  }

  Widget _buildDateQuickFilters() {
    Widget chip(String label, _DateQuickFilter? value) {
      final selected = _dateFilter == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) {
            setState(() => _dateFilter = value);
            _search();
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          chip("Svi termini", null),
          chip("Danas", _DateQuickFilter.today),
          chip("Sutra", _DateQuickFilter.tomorrow),
          chip("Ova sedmica", _DateQuickFilter.thisWeek),
        ],
      ),
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
              onSubmitted: (_) => _search(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _doctorNameController,
              decoration: const InputDecoration(labelText: "Doktor"),
              onSubmitted: (_) => _search(),
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
              // Same "click Pretraga to apply" behavior as the text fields
              // above — this used to filter instantly on selection while the
              // text fields didn't, which read as inconsistent.
              onChanged: (v) => setState(() => _statusFilter = v),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _search,
            child: const Text("Pretraga"),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _newAppointment,
            icon: const Icon(Icons.add),
            label: const Text("Novi termin"),
          ),
        ],
      ),
    );
  }

  Future _newAppointment() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => const NewAppointmentDialog(),
    );
    if (created == true) {
      initTable();
      _loadStats();
    }
  }

  Expanded _buildTable() {
    return Expanded(
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: DataTable(
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text("ID")),
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
                          DataCell(Text(e.id?.toString() ?? '')),
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

  Widget _buildPagination() {
    final total = result?.totalCount ?? 0;
    final totalPages = total == 0 ? 1 : (total / _pageSize).ceil();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: "Prethodna",
            icon: const Icon(Icons.chevron_left),
            onPressed: _page > 1 ? () => _goToPage(_page - 1) : null,
          ),
          Text("Strana $_page od $totalPages ($total termina)"),
          IconButton(
            tooltip: "Sljedeća",
            icon: const Icon(Icons.chevron_right),
            onPressed: _page < totalPages ? () => _goToPage(_page + 1) : null,
          ),
        ],
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
        if (status == AppointmentStatus.pending ||
            status == AppointmentStatus.confirmed)
          IconButton(
            tooltip: "Izmijeni",
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _reschedule(e),
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
      _loadStats();
    } on Exception catch (ex) {
      alertBox(context, "Greška", ex.toString());
    }
  }

  Future _reschedule(Appointment e) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => RescheduleAppointmentDialog(appointment: e),
    );
    if (changed == true) {
      initTable();
      _loadStats();
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
      _loadStats();
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
