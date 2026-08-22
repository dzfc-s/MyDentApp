import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/review_provider.dart';
import '../theme/app_theme.dart';
import '../utils/utils_widgets.dart';

const List<String> _ratingLabels = [
  'Loše',
  'Može biti bolje',
  'Dobro',
  'Vrlo dobro',
  'Odlično!',
];

class AddReviewScreen extends StatefulWidget {
  final int appointmentId;
  final String dentalServiceName;

  const AddReviewScreen({
    super.key,
    required this.appointmentId,
    required this.dentalServiceName,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  // Starts unrated (Figma requires an explicit tap before submitting is
  // possible) — unlike the backend's own AppointmentStatus/etc. enums, there
  // is no "0" rating value, this is purely "nothing picked yet" UI state.
  int _rating = 0;
  final _comment = TextEditingController();
  bool _saving = false;
  bool _submitted = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() => _saving = true);
    try {
      await context.read<ReviewProvider>().insert({
        'appointmentId': widget.appointmentId,
        'rating': _rating,
        'comment': _comment.text.trim(),
      });
      if (mounted) {
        setState(() {
          _saving = false;
          _submitted = true;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        alertBox(context, 'Greška', e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildThankYou();

    return Scaffold(
      appBar: AppBar(title: const Text('Ostavi recenziju'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.dentalServiceName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Text('Ocjena', style: Theme.of(context).textTheme.titleSmall),
            Row(
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  onPressed: () => setState(() => _rating = star),
                  icon: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                );
              }),
            ),
            if (_rating > 0)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  _ratingLabels[_rating - 1],
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _comment,
              decoration: const InputDecoration(
                labelText: 'Komentar',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              maxLength: 1000,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: (_saving || _rating == 0) ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Pošalji recenziju'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThankYou() {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: AppColors.successContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded, color: AppColors.success, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                'Hvala na recenziji!',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Vaše mišljenje pomaže drugim pacijentima i našem timu da bude još bolji.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Natrag na recenzije'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
