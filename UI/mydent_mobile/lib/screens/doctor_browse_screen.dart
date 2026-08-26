import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doctor.dart';
import '../models/search_result.dart';
import '../providers/doctor_provider.dart';
import '../providers/review_provider.dart';
import '../utils/utils_widgets.dart';
import '../widgets/asset_avatar.dart';
import 'doctor_profile_screen.dart';

class _DoctorStats {
  const _DoctorStats(this.avgRating, this.reviewCount);
  final double avgRating;
  final int reviewCount;
}

/// Patient-facing doctor directory — Home's "Pregled doktora" quick action.
/// Previously there was no way for a patient to browse doctors at all except
/// as a step embedded inside booking a specific service; this is a
/// standalone, read-only "get to know the team" view (bio, specialty,
/// working hours, reviews) with no booking action of its own.
class DoctorBrowseScreen extends StatefulWidget {
  const DoctorBrowseScreen({super.key});

  @override
  State<DoctorBrowseScreen> createState() => _DoctorBrowseScreenState();
}

class _DoctorBrowseScreenState extends State<DoctorBrowseScreen> {
  SearchResult<Doctor>? doctors;
  Map<int, _DoctorStats> _stats = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await context.read<DoctorProvider>().get(filter: {"isActive": true});
      if (!mounted) return;
      setState(() {
        doctors = data;
        isLoading = false;
      });
      _loadStats(data.items ?? []);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      alertBox(context, 'Greška', e.toString());
    }
  }

  Future<void> _loadStats(List<Doctor> list) async {
    final reviewProvider = context.read<ReviewProvider>();
    final entries = await Future.wait(list.map((d) async {
      try {
        final r = await reviewProvider.get(filter: {"doctorId": d.id, "pageSize": 200});
        final ratings = (r.items ?? [])
            .where((rv) => rv.isApproved == true)
            .map((rv) => rv.rating ?? 0)
            .where((v) => v > 0)
            .toList();
        final avg = ratings.isEmpty ? 0.0 : ratings.reduce((a, b) => a + b) / ratings.length;
        return MapEntry(d.id!, _DoctorStats(avg, ratings.length));
      } catch (_) {
        return MapEntry(d.id!, const _DoctorStats(0, 0));
      }
    }));
    if (!mounted) return;
    setState(() => _stats = Map.fromEntries(entries));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doktori')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (doctors?.items?.isEmpty ?? true)
              ? const Center(child: Text('Trenutno nema dostupnih doktora.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: doctors!.items!.length,
                  itemBuilder: (context, index) => _buildDoctorCard(doctors!.items![index]),
                ),
    );
  }

  Widget _buildDoctorCard(Doctor d) {
    final stats = _stats[d.id];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DoctorProfileScreen(doctor: d)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AssetAvatar(assetId: d.photoAssetId, radius: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${d.firstName} ${d.lastName}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    if ((d.bio ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(d.bio!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5, color: Colors.grey[500])),
                      ),
                    const SizedBox(height: 6),
                    if (stats != null && stats.reviewCount > 0)
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(stats.avgRating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          Text('(${stats.reviewCount})',
                              style: TextStyle(fontSize: 12.5, color: Colors.grey[500])),
                        ],
                      )
                    else
                      Text('Nema recenzija još',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey[500])),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
