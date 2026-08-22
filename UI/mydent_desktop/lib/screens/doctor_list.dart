import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/doctor.dart';
import '../models/search_result.dart';
import '../providers/appointment_provider.dart';
import '../providers/doctor_provider.dart';
import '../providers/review_provider.dart';
import '../utils/utils_widgets.dart';
import '../widgets/asset_thumbnail.dart';
import '../widgets/doctor_absences_dialog.dart';
import '../widgets/doctor_working_hours_dialog.dart';
import '../widgets/stat_card.dart';
import 'doctor_details_screen.dart';

class _DoctorStats {
  final double avgRating;
  final int reviewCount;
  final int apptsThisMonth;
  const _DoctorStats(this.avgRating, this.reviewCount, this.apptsThisMonth);
}

class DoctorList extends StatefulWidget {
  const DoctorList({super.key});

  @override
  State<DoctorList> createState() => _DoctorListState();
}

class _DoctorListState extends State<DoctorList> {
  late DoctorProvider _provider;
  SearchResult<Doctor>? result;
  bool isLoading = true;
  Map<int, _DoctorStats> _stats = {};

  @override
  void initState() {
    super.initState();
    _provider = context.read<DoctorProvider>();
    initTable();
  }

  Future<void> initTable() async {
    try {
      var data = await _provider.get(filter: {"pageSize": 200});
      if (!mounted) return;
      setState(() {
        result = data;
        isLoading = false;
      });
      _loadStats(data.items ?? []);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      alertBox(context, 'Greška', e.toString());
    }
  }

  // Doctor has no rating or appointment-count field of its own — both are
  // computed client-side, one request per doctor (clinics have few enough
  // doctors for this to be fine). Admin isn't scoped to "own" appointments
  // the way a patient caller is, so the doctorId filter alone is enough to
  // get every patient's appointments with that doctor. Runs after the grid
  // already shows, so a slow fetch never blocks the doctor list itself.
  Future<void> _loadStats(List<Doctor> list) async {
    final reviewProvider = context.read<ReviewProvider>();
    final appointmentProvider = context.read<AppointmentProvider>();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final entries = await Future.wait(list.map((d) async {
      var avg = 0.0;
      var reviewCount = 0;
      var apptsThisMonth = 0;
      try {
        final r = await reviewProvider
            .get(filter: {"doctorId": d.id, "pageSize": 200});
        final ratings = (r.items ?? [])
            .map((rv) => rv.rating ?? 0)
            .where((v) => v > 0)
            .toList();
        if (ratings.isNotEmpty) {
          avg = ratings.reduce((a, b) => a + b) / ratings.length;
        }
        reviewCount = ratings.length;
      } catch (_) {
        // Leave rating stats at 0 — a doctor with no reviews yet, not an error state.
      }
      try {
        final appts = await appointmentProvider.get(filter: {
          "doctorId": d.id,
          "dateFrom": monthStart.toIso8601String(),
          "dateTo": monthEnd.toIso8601String(),
          "pageSize": 200,
        });
        apptsThisMonth = appts.items?.length ?? 0;
      } catch (_) {
        // Same reasoning — 0 rather than blocking the whole card on one failed request.
      }
      return MapEntry(d.id!, _DoctorStats(avg, reviewCount, apptsThisMonth));
    }));
    if (!mounted) return;
    setState(() => _stats = Map.fromEntries(entries));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MasterScreen(
      title: "Doktori",
      currentSection: AppSection.doctors,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(theme),
            const SizedBox(height: 20),
            _buildStats(theme),
            const SizedBox(height: 20),
            if (isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              _buildGrid(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.medical_services_outlined,
                  color: theme.colorScheme.onPrimaryContainer, size: 28),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Doktori',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('Upravljajte timom doktora klinike',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: () async {
            var refresh = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const DoctorDetailsScreen(doctor: null),
              ),
            );
            if (refresh == "reload") initTable();
          },
          icon: const Icon(Icons.person_add_outlined),
          label: const Text("Novi doktor"),
        ),
      ],
    );
  }

  Widget _buildStats(ThemeData theme) {
    final doctors = result?.items ?? [];
    final active = doctors.where((d) => d.isActive == true).length;

    final apptsThisMonth =
        _stats.values.fold<int>(0, (sum, s) => sum + s.apptsThisMonth);
    final rated = _stats.values.where((s) => s.reviewCount > 0).toList();
    final avgRating = rated.isEmpty
        ? 0.0
        : rated.fold<double>(0, (sum, s) => sum + s.avgRating) / rated.length;

    return Row(
      children: [
        StatCard(
          icon: Icons.groups_outlined,
          label: "Ukupno doktora",
          value: doctors.length.toString(),
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.check_circle_outline,
          label: "Aktivni",
          value: active.toString(),
          color: theme.colorScheme.tertiary,
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.pause_circle_outlined,
          label: "Neaktivni",
          value: (doctors.length - active).toString(),
          color: theme.colorScheme.error,
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.event_outlined,
          label: "Termini ovaj mj.",
          value: _stats.isEmpty ? '—' : apptsThisMonth.toString(),
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.star_outline,
          label: "Prosj. ocjena",
          value: rated.isEmpty ? '—' : avgRating.toStringAsFixed(1),
          color: Colors.amber[700],
        ),
      ],
    );
  }


  Widget _buildGrid(ThemeData theme) {
    final doctors = result?.items ?? [];

    if (doctors.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.medical_services_outlined,
                  size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              Text('Nema pronađenih doktora',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.outline)),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.only(top: 4),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 260,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.54,
        ),
        itemCount: doctors.length,
        itemBuilder: (context, index) => _DoctorCard(
          doctor: doctors[index],
          stats: _stats[doctors[index].id],
          onTap: () async {
            var refresh = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    DoctorDetailsScreen(doctor: doctors[index]),
              ),
            );
            if (refresh == "reload") initTable();
          },
          onDelete: () => _confirmDelete(doctors[index]),
          onSchedule: () => showDoctorWorkingHoursDialog(context, doctors[index]),
          onAbsences: () => showDoctorAbsencesDialog(context, doctors[index]),
        ),
      ),
    );
  }

  void _confirmDelete(Doctor e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Brisanje"),
        content: Text(
            "Deaktivirati doktora '${e.firstName} ${e.lastName}'? Budući zakazani termini kod ovog doktora će biti automatski otkazani."),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Doktor obrisan")),
                );
                Navigator.pop(context);
                initTable();
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

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final _DoctorStats? stats;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onSchedule;
  final VoidCallback onAbsences;

  const _DoctorCard({
    required this.doctor,
    required this.stats,
    required this.onTap,
    required this.onDelete,
    required this.onSchedule,
    required this.onAbsences,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = doctor.isActive ?? false;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.3,
              child: AssetThumbnail(
                assetId: doctor.photoAssetId,
                size: double.infinity,
                placeholderIcon: Icons.person_outline,
              ),
            ),
            Container(
              color: active ? null : const Color(0xFFF3F3F3),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${doctor.firstName ?? ''} ${doctor.lastName ?? ''}'
                              .trim(),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: active ? null : theme.colorScheme.outline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.bio?.isNotEmpty == true
                        ? doctor.bio!
                        : 'Nema biografije',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber[700]),
                      const SizedBox(width: 3),
                      Text(
                        (stats == null || stats!.reviewCount == 0)
                            ? 'Nema recenzija'
                            : '${stats!.avgRating.toStringAsFixed(1)} (${stats!.reviewCount})',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        '${stats?.apptsThisMonth ?? 0} termina',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: onSchedule,
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                ),
                                icon: const Icon(Icons.schedule_outlined, size: 16),
                                label: const Text("Raspored", style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: onAbsences,
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                ),
                                icon: const Icon(Icons.event_busy, size: 16),
                                label: const Text("Odsustva", style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: "Obriši",
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.delete_outline,
                            color: theme.colorScheme.error, size: 20),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
