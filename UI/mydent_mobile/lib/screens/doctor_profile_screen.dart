import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doctor.dart';
import '../models/doctor_specialty.dart';
import '../models/doctor_working_hours.dart';
import '../models/review.dart';
import '../providers/doctor_specialty_provider.dart';
import '../providers/doctor_working_hours_provider.dart';
import '../providers/review_provider.dart';
import '../utils/utils_widgets.dart';
import '../widgets/asset_avatar.dart';

// C# System.DayOfWeek ordinals: Sunday=0 .. Saturday=6.
const List<String> _dayNames = [
  "Nedjelja", "Ponedjeljak", "Utorak", "Srijeda", "Četvrtak", "Petak", "Subota",
];

/// Read-only doctor profile — bio, specialties, working hours, and approved
/// reviews. Opened from DoctorBrowseScreen; deliberately has no booking
/// action (browsing a doctor and starting a booking are different intents —
/// booking always starts from a service, per BookAppointmentScreen).
class DoctorProfileScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorProfileScreen({super.key, required this.doctor});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  List<DoctorSpecialty> _specialties = [];
  List<DoctorWorkingHours> _workingHours = [];
  List<Review> _reviews = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<dynamic>([
        context.read<DoctorSpecialtyProvider>().get(filter: {"doctorId": widget.doctor.id}),
        context.read<DoctorWorkingHoursProvider>().get(filter: {"doctorId": widget.doctor.id}),
        context.read<ReviewProvider>().get(filter: {"doctorId": widget.doctor.id, "pageSize": 200}),
      ]);
      if (!mounted) return;
      final hours = List<DoctorWorkingHours>.from(results[1].items ?? []);
      hours.sort((a, b) => (a.dayOfWeek ?? 0).compareTo(b.dayOfWeek ?? 0));
      final approvedReviews = List<Review>.from(results[2].items ?? [])
          .where((r) => r.isApproved == true)
          .toList();
      setState(() {
        _specialties = List<DoctorSpecialty>.from(results[0].items ?? []);
        _workingHours = hours;
        _reviews = approvedReviews;
        isLoading = false;
      });
    } on Exception catch (e) {
      setState(() => isLoading = false);
      if (mounted) alertBox(context, 'Greška', e.toString());
    }
  }

  double get _avgRating {
    final rated = _reviews.map((r) => r.rating ?? 0).where((v) => v > 0).toList();
    if (rated.isEmpty) return 0;
    return rated.reduce((a, b) => a + b) / rated.length;
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.doctor;
    return Scaffold(
      appBar: AppBar(title: Text('${d.firstName} ${d.lastName}')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    AssetAvatar(assetId: d.photoAssetId, radius: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${d.firstName} ${d.lastName}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 4),
                          if (_reviews.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(_avgRating.toStringAsFixed(1),
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(width: 4),
                                Text('(${_reviews.length} recenzija)',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 12.5)),
                              ],
                            )
                          else
                            Text('Nema recenzija još',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ],
                ),
                if ((d.bio ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(d.bio!, style: TextStyle(color: Colors.grey[400], height: 1.4)),
                ],
                if (_specialties.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Specijalnosti', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _specialties
                        .map((s) => Chip(label: Text(s.serviceCategoryName ?? '')))
                        .toList(),
                  ),
                ],
                if (_workingHours.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Radno vrijeme', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Column(
                        children: _workingHours.map((h) {
                          final start = (h.startTime ?? '').substring(0, 5);
                          final end = (h.endTime ?? '').substring(0, 5);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_dayNames[h.dayOfWeek ?? 0]),
                                Text('$start – $end',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text('Recenzije', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_reviews.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('Nema recenzija još.', style: TextStyle(color: Colors.grey[500])),
                  )
                else
                  ..._reviews.map((r) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(r.patientName ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (i) => Icon(
                                        i < (r.rating ?? 0) ? Icons.star : Icons.star_border,
                                        size: 14,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if ((r.dentalServiceName ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(r.dentalServiceName!,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                ),
                              if ((r.comment ?? '').isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(r.comment!),
                              ],
                            ],
                          ),
                        ),
                      )),
              ],
            ),
    );
  }
}
