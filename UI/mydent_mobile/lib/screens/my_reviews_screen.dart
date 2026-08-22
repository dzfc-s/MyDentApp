import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../models/enums.dart';
import '../models/review.dart';
import '../models/search_result.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/review_provider.dart';
import '../theme/app_theme.dart';
import '../utils/utils_widgets.dart';
import 'add_review_screen.dart';

/// "Moje recenzije" — ported from the Figma reference's reviews screen.
/// The app previously had no place to browse/edit/delete reviews already
/// submitted; `AddReviewScreen` (reachable from an appointment's details)
/// only ever wrote a new one and was never listed anywhere.
///
/// Also surfaces a "Čekaju recenziju" section — completed appointments that
/// don't have a review yet — matching Figma's reference, which shows pending
/// reviews above the already-submitted list rather than leaving patients to
/// stumble onto AddReviewScreen only via an appointment's own details page.
class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  SearchResult<Review>? result;
  List<Appointment> _pendingReviews = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    try {
      // Unlike Appointments, the Reviews endpoint is NOT auto-scoped to the
      // caller — patientId must be passed explicitly or this would return
      // every patient's reviews.
      final reviews = await context.read<ReviewProvider>().get(filter: {
        "patientId": AuthProvider.userId,
        "pageSize": 200,
      });
      // Appointments IS auto-scoped to "my own" for a non-admin caller, so no
      // patientId filter needed here.
      final appointments =
          await context.read<AppointmentProvider>().get(filter: {"pageSize": 200});

      if (!mounted) return;

      final reviewedAppointmentIds = (reviews.items ?? [])
          .map((r) => r.appointmentId)
          .whereType<int>()
          .toSet();

      final pending = (appointments.items ?? [])
          .where((a) =>
              AppointmentStatusX.fromInt(a.status) == AppointmentStatus.completed &&
              !reviewedAppointmentIds.contains(a.id))
          .toList()
        ..sort((a, b) =>
            (b.scheduledAt ?? DateTime(0)).compareTo(a.scheduledAt ?? DateTime(0)));

      setState(() {
        result = reviews;
        _pendingReviews = pending;
        isLoading = false;
      });
    } on Exception catch (e) {
      if (mounted) setState(() => isLoading = false);
      if (mounted) alertBox(context, 'Greška', e.toString());
    }
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

  Future<void> _edit(Review review) async {
    int rating = review.rating ?? 5;
    final commentController = TextEditingController(text: review.comment ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Uredi recenziju', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return IconButton(
                    onPressed: () => setSheetState(() => rating = star),
                    icon: Icon(
                      star <= rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Komentar',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                maxLength: 1000,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  child: const Text('Sačuvaj izmjene'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved != true || !mounted) return;
    try {
      await context.read<ReviewProvider>().update(review.id!, {
        'rating': rating,
        'comment': commentController.text.trim(),
      });
      if (mounted) _load();
    } on Exception catch (e) {
      if (mounted) alertBox(context, 'Greška', e.toString());
    }
  }

  Future<void> _delete(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obriši recenziju'),
        content: const Text('Da li ste sigurni da želite obrisati ovu recenziju?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Odustani')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Obriši')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<ReviewProvider>().remove(review.id!);
      if (mounted) _load();
    } on Exception catch (e) {
      if (mounted) alertBox(context, 'Greška', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (result?.items ?? [])
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    final hasContent = _pendingReviews.isNotEmpty || items.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Moje recenzije'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _load,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : !hasContent
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('Nemate završenih termina za ocjenu')),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (_pendingReviews.isNotEmpty) ...[
                        Text(
                          'Čekaju recenziju (${_pendingReviews.length})',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ..._pendingReviews.map(_buildPendingCard),
                        const SizedBox(height: 16),
                      ],
                      if (items.isNotEmpty) ...[
                        Text(
                          'Ostavljene recenzije',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...items.map(_buildReviewCard),
                      ],
                    ],
                  ),
      ),
    );
  }

  Widget _buildPendingCard(Appointment a) {
    final d = a.scheduledAt?.toLocal();
    final dateLabel = d == null
        ? ''
        : "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}.";

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppColors.primary.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: const Icon(Icons.rate_review_outlined, color: AppColors.primary),
        title: Text(a.dentalServiceName ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [
            if ((a.doctorName ?? '').isNotEmpty) a.doctorName!,
            dateLabel,
          ].where((s) => s.isNotEmpty).join(' · '),
        ),
        trailing: FilledButton(
          onPressed: () => _openAddReview(a),
          child: const Text('Ocijeni'),
        ),
      ),
    );
  }

  Widget _buildReviewCard(Review r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.dentalServiceName ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < (r.rating ?? 0) ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            if ((r.doctorName ?? '').isNotEmpty)
              Text(r.doctorName!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            if ((r.comment ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(r.comment!),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _edit(r),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Uredi'),
                ),
                TextButton.icon(
                  onPressed: () => _delete(r),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Obriši'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
