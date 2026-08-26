import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/available_slot.dart';
import '../models/dental_service.dart';
import '../models/doctor.dart';
import '../models/search_result.dart';
import '../providers/appointment_provider.dart';
import '../providers/doctor_provider.dart';
import '../providers/review_provider.dart';
import '../utils/slot_utils.dart';
import '../utils/utils_widgets.dart';
import '../widgets/asset_avatar.dart';
import '../widgets/booking_steps.dart';
import 'booking_confirm_screen.dart';

/// Average rating + review count for one doctor, shown on their picker card.
/// There's no "total appointments" stat here (unlike the Figma reference's
/// doctor cards) — AppointmentService scopes non-Admin GETs to the caller's
/// own appointments only, so a patient-facing screen has no legitimate way
/// to ask the API "how many appointments has this doctor had in total."
/// Review count/rating is real data a patient CAN see (Reviews isn't scoped
/// that way) and serves the same "social proof" purpose.
class _DoctorStats {
  const _DoctorStats(this.avgRating, this.reviewCount);
  final double avgRating;
  final int reviewCount;
}

class BookAppointmentScreen extends StatefulWidget {
  final DentalService service;

  const BookAppointmentScreen({super.key, required this.service});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  late DoctorProvider _doctorProvider;
  late AppointmentProvider _appointmentProvider;

  SearchResult<Doctor>? doctors;
  Doctor? _selectedDoctor;
  DateTime _selectedDate = DateTime.now();
  List<AvailableSlot> _slots = [];
  AvailableSlot? _selectedSlot;
  Map<int, _DoctorStats> _doctorStats = {};
  bool isLoadingDoctors = true;
  bool isLoadingSlots = false;
  DateTime? _nextAvailableDate;
  bool _searchingNextDate = false;

  @override
  void initState() {
    super.initState();
    _doctorProvider = context.read<DoctorProvider>();
    _appointmentProvider = context.read<AppointmentProvider>();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final data = await _doctorProvider.get(filter: {
        "serviceCategoryId": widget.service.serviceCategoryId,
        "isActive": true,
      });
      if (!mounted) return;
      setState(() {
        doctors = data;
        _selectedDoctor = data.items?.isNotEmpty == true ? data.items!.first : null;
        isLoadingDoctors = false;
      });
      if (_selectedDoctor != null) _loadSlots();
      _loadDoctorStats(data.items ?? []);
    } on Exception catch (e) {
      alertBox(context, 'Greška', e.toString());
    }
  }

  Future<void> _loadDoctorStats(List<Doctor> list) async {
    final reviewProvider = context.read<ReviewProvider>();
    final entries = await Future.wait(list.map((d) async {
      try {
        final r = await reviewProvider.get(filter: {"doctorId": d.id, "pageSize": 200});
        final ratings = (r.items ?? [])
            .map((rv) => rv.rating ?? 0)
            .where((v) => v > 0)
            .toList();
        final avg = ratings.isEmpty
            ? 0.0
            : ratings.reduce((a, b) => a + b) / ratings.length;
        return MapEntry(d.id!, _DoctorStats(avg, ratings.length));
      } catch (_) {
        return MapEntry(d.id!, const _DoctorStats(0, 0));
      }
    }));
    if (!mounted) return;
    setState(() => _doctorStats = Map.fromEntries(entries));
  }

  Future<void> _loadSlots() async {
    if (_selectedDoctor == null) return;
    setState(() {
      isLoadingSlots = true;
      _selectedSlot = null;
      _nextAvailableDate = null;
    });
    try {
      final slots = await _appointmentProvider.getAvailableSlots(
        doctorId: _selectedDoctor!.id!,
        dentalServiceId: widget.service.id!,
        date: _selectedDate,
      );
      if (!mounted) return;
      setState(() {
        _slots = slots;
        isLoadingSlots = false;
      });

      if (slots.isEmpty) {
        setState(() => _searchingNextDate = true);
        final next = await findNextAvailableDate(
          provider: _appointmentProvider,
          doctorId: _selectedDoctor!.id!,
          dentalServiceId: widget.service.id!,
          startDate: _selectedDate,
        );
        if (!mounted) return;
        setState(() {
          _nextAvailableDate = next;
          _searchingNextDate = false;
        });
      }
    } on Exception catch (e) {
      setState(() => isLoadingSlots = false);
      if (mounted) alertBox(context, 'Greška', e.toString());
    }
  }

  String _formatTime(DateTime dt) {
    final t = dt.toLocal();
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadSlots();
    }
  }

  /// Doesn't book yet — hands off to [BookingConfirmScreen], which shows a
  /// summary + cancellation policy and only calls the booking API once the
  /// patient explicitly confirms (see that screen's doc comment for why).
  /// Marks the tapped chip selected *before* navigating (not just while the
  /// push animates) so that coming back from step 3 via "Nazad" shows this
  /// screen exactly as it was left, instead of a plain, unselected slot list
  /// that looks like the earlier choice was forgotten.
  void _selectSlot(AvailableSlot slot) {
    if (_selectedDoctor == null) return;
    setState(() => _selectedSlot = slot);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingConfirmScreen(
          service: widget.service,
          doctor: _selectedDoctor!,
          slot: slot,
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Doctor d) {
    final selected = _selectedDoctor?.id == d.id;
    final stats = _doctorStats[d.id];
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() => _selectedDoctor = d);
          _loadSlots();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? primary : Colors.grey.withValues(alpha: 0.3),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              AssetAvatar(assetId: d.photoAssetId, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${d.firstName} ${d.lastName}",
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if ((d.bio ?? '').isNotEmpty)
                      Text(d.bio!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    const SizedBox(height: 4),
                    if (stats != null && stats.reviewCount > 0)
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(stats.avgRating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          Text('(${stats.reviewCount} recenzija)',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        ],
                      )
                    else
                      Text('Nema recenzija još',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: primary),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Zakazivanje — ${widget.service.name}")),
      body: Column(
        children: [
          BookingSteps(
            step: 2,
            onBack: () => Navigator.maybePop(context),
            onNext: _selectedSlot != null ? () => _selectSlot(_selectedSlot!) : null,
          ),
          Expanded(
            child: isLoadingDoctors
                ? const Center(child: CircularProgressIndicator())
                : (doctors?.items?.isEmpty ?? true)
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text(
                            "Trenutno nema dostupnih doktora za ovu kategoriju usluge.",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                    Text("Doktor", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...doctors!.items!.map(_buildDoctorCard),
                    const SizedBox(height: 16),
                    Text("Datum", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                          "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}"),
                    ),
                    const SizedBox(height: 24),
                    Text("Dostupni termini", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (isLoadingSlots)
                      const Center(child: CircularProgressIndicator())
                    else if (_slots.isEmpty)
                      _searchingNextDate
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text("Tražim sljedeći slobodan termin...",
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nextAvailableDate != null
                                      ? "Na odabrani datum nema slobodnog termina. Prvi sljedeći slobodan termin: ${formatShortDate(_nextAvailableDate!)}"
                                      : "Na odabrani datum nema slobodnog termina.",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                if (_nextAvailableDate != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setState(() => _selectedDate = _nextAvailableDate!);
                                        _loadSlots();
                                      },
                                      child: const Text("Idi na taj datum"),
                                    ),
                                  ),
                              ],
                            )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          "Prvi slobodan termin dana: ${_formatTime(_slots.first.startTime!)}",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _slots.map((s) {
                          final t = s.startTime!.toLocal();
                          final label =
                              "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
                          final selected = _selectedSlot?.startTime == s.startTime;
                          return ChoiceChip(
                            label: Text(label),
                            selected: selected,
                            onSelected: (_) => _selectSlot(s),
                          );
                        }).toList(),
                      ),
                    ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
