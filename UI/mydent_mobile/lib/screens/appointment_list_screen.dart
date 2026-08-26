import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../models/enums.dart';
import '../models/search_result.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/review_provider.dart';
import '../theme/app_theme.dart';
import '../utils/booking_helpers.dart';
import '../utils/utils_widgets.dart';
import 'add_review_screen.dart';
import 'appointment_details_screen.dart';

/// Upcoming/history split with counts in the tab labels — ported from the
/// Figma reference's "Nadolazeći (N)" / "Historija (N)" tabs. Each card also
/// carries the same quick action Figma puts directly on the card (Otkaži /
/// Ostavi recenziju / Zakaži ponovo) instead of forcing a trip through the
/// details screen for everything.
class AppointmentListScreen extends StatefulWidget {
  /// Bumped by `ContainerScreen` every time the Termini tab is switched to —
  /// `IndexedStack` keeps this screen's State alive across tab switches, so
  /// without this, `_load()` only ever ran once in `initState` (same
  /// staleness `HomeScreen`/`NotificationListScreen` had — a just-booked
  /// appointment wouldn't show here until a manual pull-to-refresh).
  final int refreshTick;

  const AppointmentListScreen({super.key, this.refreshTick = 0});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  SearchResult<Appointment>? result;
  Set<int> _reviewedAppointmentIds = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void didUpdateWidget(covariant AppointmentListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTick != oldWidget.refreshTick) _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      // AppointmentService forces non-Admin callers to their own appointments
      // regardless of filter. pageSize is raised from the 10-item default so the
      // "Historija" tab isn't silently missing older appointments.
      final data = await context
          .read<AppointmentProvider>()
          .get(filter: {"pageSize": 200});

      // Needed to know which completed appointments still need "Ostavi
      // recenziju" vs. already have one — Reviews isn't auto-scoped like
      // Appointments, so patientId must be passed explicitly.
      Set<int> reviewed = {};
      try {
        final reviews = await context.read<ReviewProvider>().get(filter: {
          "patientId": AuthProvider.userId,
          "pageSize": 200,
        });
        reviewed = (reviews.items ?? [])
            .map((r) => r.appointmentId)
            .whereType<int>()
            .toSet();
      } catch (_) {
        // Non-critical — worst case "Ostavi recenziju" shows on an already-
        // reviewed appointment, which AddReviewScreen's own backend
        // validation would reject anyway.
      }

      if (!mounted) return;
      setState(() {
        result = data;
        _reviewedAppointmentIds = reviewed;
        isLoading = false;
      });
    } on Exception catch (e) {
      if (mounted) alertBox(context, 'Greška', e.toString());
    }
  }

  bool _isUpcoming(Appointment a) {
    final status = AppointmentStatusX.fromInt(a.status);
    if (status == AppointmentStatus.cancelled || status == AppointmentStatus.completed) {
      return false;
    }
    return a.scheduledAt != null && a.scheduledAt!.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final items = result?.items ?? [];
    final upcoming = items.where(_isUpcoming).toList()
      ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
    final history = items.where((a) => !_isUpcoming(a)).toList()
      ..sort((a, b) => (b.scheduledAt ?? DateTime(0)).compareTo(a.scheduledAt ?? DateTime(0)));

    return Column(
      children: [
        Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white54,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Nadolazeći (${upcoming.length})'),
              Tab(text: 'Historija (${history.length})'),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(upcoming, emptyText: 'Nemate nadolazećih termina'),
                    _buildList(history, emptyText: 'Nemate historije termina'),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildList(List<Appointment> items, {required String emptyText}) {
    return RefreshIndicator(
      onRefresh: _load,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(child: Text(emptyText)),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              itemBuilder: (context, index) => _buildCard(items[index]),
            ),
    );
  }

  Widget _buildCard(Appointment a) {
    final status = AppointmentStatusX.fromInt(a.status);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(a.dentalServiceName ?? ''),
            subtitle: Text(
              "${a.doctorName ?? ''}\n${a.scheduledAt?.toLocal().toString().substring(0, 16) ?? ''}",
            ),
            isThreeLine: true,
            trailing: StatusBadge.appointment(status),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AppointmentDetailsScreen(appointmentId: a.id!),
                ),
              );
              _load();
            },
          ),
          if (status == AppointmentStatus.cancelled &&
              (a.cancellationReason?.trim().isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                "Razlog: ${a.cancellationReason}",
                style: const TextStyle(fontSize: 12, color: AppColors.danger),
              ),
            ),
          _buildActionsRow(a, status),
        ],
      ),
    );
  }

  Widget _buildActionsRow(Appointment a, AppointmentStatus status) {
    final actions = <Widget>[];

    if (status == AppointmentStatus.pending || status == AppointmentStatus.confirmed) {
      actions.add(TextButton(
        onPressed: () => _cancel(a),
        style: TextButton.styleFrom(foregroundColor: AppColors.danger),
        child: const Text('Otkaži'),
      ));
    }

    if (status == AppointmentStatus.completed &&
        !_reviewedAppointmentIds.contains(a.id)) {
      actions.add(TextButton(
        onPressed: () => _openAddReview(a),
        child: const Text('Ostavi recenziju'),
      ));
    }

    if (status == AppointmentStatus.cancelled) {
      actions.add(TextButton(
        onPressed: () => pickServiceAndBook(context),
        child: const Text('Zakaži ponovo'),
      ));
    }

    if (actions.isEmpty) return const SizedBox(height: 4);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
    );
  }

  Future<void> _openAddReview(Appointment a) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddReviewScreen(
          appointmentId: a.id!,
          dentalServiceName: a.dentalServiceName ?? '',
        ),
      ),
    );
    if (saved == true && mounted) _load();
  }

  Future<void> _cancel(Appointment a) async {
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
      await context.read<AppointmentProvider>().cancel(a.id!, reason);
      _load();
    } on Exception catch (e) {
      if (mounted) alertBox(context, 'Greška', e.toString());
    }
  }
}
