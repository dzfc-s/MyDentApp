import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/available_slot.dart';
import '../models/dental_service.dart';
import '../models/doctor.dart';
import '../models/search_result.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/doctor_provider.dart';
import '../utils/utils_widgets.dart';
import 'appointment_details_screen.dart';

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
  bool isLoadingDoctors = true;
  bool isLoadingSlots = false;
  bool isBooking = false;

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
    } on Exception catch (e) {
      alertBox(context, 'Greška', e.toString());
    }
  }

  Future<void> _loadSlots() async {
    if (_selectedDoctor == null) return;
    setState(() => isLoadingSlots = true);
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
    } on Exception catch (e) {
      setState(() => isLoadingSlots = false);
      if (mounted) alertBox(context, 'Greška', e.toString());
    }
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

  Future<void> _book(AvailableSlot slot) async {
    setState(() => isBooking = true);
    try {
      final appointment = await _appointmentProvider.insert({
        "patientId": AuthProvider.userId,
        "doctorId": _selectedDoctor!.id,
        "dentalServiceId": widget.service.id,
        "scheduledAt": slot.startTime!.toIso8601String(),
      });
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AppointmentDetailsScreen(appointmentId: appointment.id!),
        ),
      );
    } on Exception catch (e) {
      setState(() => isBooking = false);
      if (mounted) alertBox(context, 'Greška', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Zakazivanje — ${widget.service.name}")),
      body: isLoadingDoctors
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
                    DropdownButtonFormField<Doctor>(
                      initialValue: _selectedDoctor,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: doctors!.items!
                          .map((d) => DropdownMenuItem(
                              value: d, child: Text("${d.firstName} ${d.lastName}")))
                          .toList(),
                      onChanged: (d) {
                        setState(() => _selectedDoctor = d);
                        _loadSlots();
                      },
                    ),
                    const SizedBox(height: 24),
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
                      const Text("Nema dostupnih termina za odabrani datum.")
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _slots.map((s) {
                          final t = s.startTime!.toLocal();
                          final label =
                              "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
                          return ActionChip(
                            label: Text(label),
                            onPressed: isBooking ? null : () => _book(s),
                          );
                        }).toList(),
                      ),
                  ],
                ),
    );
  }
}
