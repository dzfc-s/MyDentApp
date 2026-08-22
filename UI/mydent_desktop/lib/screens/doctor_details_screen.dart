import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/doctor.dart';
import '../models/doctor_specialty.dart';
import '../models/doctor_working_hours.dart';
import '../models/search_result.dart';
import '../models/service_category.dart';
import '../providers/asset_provider.dart';
import '../providers/doctor_provider.dart';
import '../providers/doctor_specialty_provider.dart';
import '../providers/doctor_working_hours_provider.dart';
import '../providers/service_category_provider.dart';
import '../utils/utils_widgets.dart';
import '../widgets/image_asset_picker.dart';

// C# System.DayOfWeek ordinals: Sunday=0 .. Saturday=6.
const List<String> _dayNames = [
  "Nedjelja",
  "Ponedjeljak",
  "Utorak",
  "Srijeda",
  "Četvrtak",
  "Petak",
  "Subota",
];
// Monday-first display order — reads as a normal work week instead of
// starting on Sunday just because that's the C# enum's zero value.
const List<int> _displayDayOrder = [1, 2, 3, 4, 5, 6, 0];

class _DayHours {
  TimeOfDay start;
  TimeOfDay end;
  final int? existingId;
  _DayHours({required this.start, required this.end, this.existingId});
}

class DoctorDetailsScreen extends StatefulWidget {
  final Doctor? doctor;

  const DoctorDetailsScreen({super.key, this.doctor});

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _imagePickerKey = GlobalKey<ImageAssetPickerState>();
  Map<String, dynamic> _initialValue = {};

  late DoctorProvider _provider;
  late AssetProvider _assetProvider;
  late ServiceCategoryProvider _categoryProvider;
  late DoctorSpecialtyProvider _specialtyProvider;
  late DoctorWorkingHoursProvider _workingHoursProvider;

  bool _isLoading = true;
  bool _saving = false;

  List<ServiceCategory> _categories = [];
  final Set<int> _selectedCategoryIds = {};
  List<DoctorSpecialty> _originalSpecialties = [];

  final Map<int, _DayHours> _workingHours = {};
  List<DoctorWorkingHours> _originalWorkingHours = [];

  // Only shown once the admin actually tries to save with these empty —
  // showing "required" red text on a form that hasn't been touched yet
  // reads as broken, not helpful.
  bool _showSpecialtyError = false;
  bool _showHoursError = false;

  @override
  void initState() {
    super.initState();

    _initialValue = {
      'firstName': widget.doctor?.firstName ?? '',
      'lastName': widget.doctor?.lastName ?? '',
      'bio': widget.doctor?.bio ?? '',
      'isActive': widget.doctor?.isActive ?? true,
    };

    _provider = context.read<DoctorProvider>();
    _assetProvider = context.read<AssetProvider>();
    _categoryProvider = context.read<ServiceCategoryProvider>();
    _specialtyProvider = context.read<DoctorSpecialtyProvider>();
    _workingHoursProvider = context.read<DoctorWorkingHoursProvider>();
    _load();
  }

  Future<void> _load() async {
    try {
      final categoriesResult =
          await _categoryProvider.get(filter: {"isActive": true, "pageSize": 200});

      List<DoctorSpecialty> specialties = [];
      List<DoctorWorkingHours> hours = [];
      final doctorId = widget.doctor?.id;
      if (doctorId != null) {
        final results = await Future.wait<dynamic>([
          _specialtyProvider.get(filter: {"doctorId": doctorId, "pageSize": 100}),
          _workingHoursProvider.get(filter: {"doctorId": doctorId, "pageSize": 100}),
        ]);
        specialties = (results[0] as SearchResult<DoctorSpecialty>).items ?? [];
        hours = (results[1] as SearchResult<DoctorWorkingHours>).items ?? [];
      }

      if (!mounted) return;
      setState(() {
        _categories = categoriesResult.items ?? [];
        _originalSpecialties = specialties;
        _selectedCategoryIds.addAll(
            specialties.map((s) => s.serviceCategoryId).whereType<int>());
        _originalWorkingHours = hours;
        for (final h in hours) {
          final day = h.dayOfWeek;
          final start = _parseTime(h.startTime);
          final end = _parseTime(h.endTime);
          if (day != null && start != null && end != null) {
            _workingHours[day] = _DayHours(start: start, end: end, existingId: h.id);
          }
        }
        _isLoading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      alertBox(context, "Greška", e.toString());
    }
  }

  TimeOfDay? _parseTime(String? hhmmss) {
    if (hhmmss == null) return null;
    final parts = hhmmss.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeOfDay(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00";

  String _hhmm(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MasterScreen(
      title: widget.doctor != null ? 'Uredi doktora' : 'Novi doktor',
      currentSection: AppSection.doctors,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _buildForm(theme),
                  ),
                ),
                const SizedBox(height: 24.0),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return FormBuilder(
      key: _formKey,
      initialValue: _initialValue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ImageAssetPicker(
            key: _imagePickerKey,
            initialAssetId: widget.doctor?.photoAssetId,
            assetProvider: _assetProvider,
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: FormBuilderTextField(
                  name: 'firstName',
                  decoration: const InputDecoration(labelText: "Ime"),
                  validator: (v) => (v == null || v.isEmpty) ? mField : null,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: FormBuilderTextField(
                  name: 'lastName',
                  decoration: const InputDecoration(labelText: "Prezime"),
                  validator: (v) => (v == null || v.isEmpty) ? mField : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          FormBuilderTextField(
            name: 'bio',
            decoration: const InputDecoration(labelText: "Biografija"),
            maxLines: 4,
          ),
          if (widget.doctor != null) ...[
            const SizedBox(height: 8.0),
            FormBuilderCheckbox(name: 'isActive', title: const Text("Aktivan")),
          ],
          const SizedBox(height: 24.0),
          const Divider(),
          const SizedBox(height: 8.0),
          _buildSpecialtiesSection(theme),
          const SizedBox(height: 24.0),
          const Divider(),
          const SizedBox(height: 8.0),
          _buildWorkingHoursSection(theme),
        ],
      ),
    );
  }

  Widget _buildSpecialtiesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Specijalnosti *",
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          "Kategorije usluga za koje je ovaj doktor specijalizovan — određuje koje ga usluge nude pri zakazivanju.",
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 10),
        if (_categories.isEmpty)
          const Text("Nema aktivnih kategorija usluga.",
              style: TextStyle(color: Colors.grey))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((c) {
              final selected = _selectedCategoryIds.contains(c.id);
              return FilterChip(
                label: Text(c.name ?? ''),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedCategoryIds.add(c.id!);
                    } else {
                      _selectedCategoryIds.remove(c.id);
                    }
                    if (_selectedCategoryIds.isNotEmpty) _showSpecialtyError = false;
                  });
                },
              );
            }).toList(),
          ),
        if (_showSpecialtyError && _selectedCategoryIds.isEmpty) ...[
          const SizedBox(height: 6),
          Text("Odaberite bar jednu specijalnost.",
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildWorkingHoursSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Radno vrijeme *",
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          "Dani i sati kada je doktor dostupan za zakazivanje.",
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 10),
        ..._displayDayOrder.map((day) => _buildDayRow(theme, day)),
        if (_showHoursError && _workingHours.isEmpty) ...[
          const SizedBox(height: 6),
          Text("Postavite radno vrijeme za bar jedan dan.",
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildDayRow(ThemeData theme, int day) {
    final hours = _workingHours[day];
    final enabled = hours != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: CheckboxListTile(
              value: enabled,
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(_dayNames[day]),
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _workingHours[day] = _DayHours(
                      start: const TimeOfDay(hour: 8, minute: 0),
                      end: const TimeOfDay(hour: 16, minute: 0),
                    );
                    _showHoursError = false;
                  } else {
                    _workingHours.remove(day);
                  }
                });
              },
            ),
          ),
          if (enabled) ...[
            OutlinedButton(
              onPressed: () async {
                final picked = await showTimePicker(
                    context: context, initialTime: hours.start);
                if (picked != null) setState(() => hours.start = picked);
              },
              child: Text(_hhmm(hours.start)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text("—"),
            ),
            OutlinedButton(
              onPressed: () async {
                final picked = await showTimePicker(
                    context: context, initialTime: hours.end);
                if (picked != null) setState(() => hours.end = picked);
              },
              child: Text(_hhmm(hours.end)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Odustani"),
        ),
        const SizedBox(width: 16.0),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Sačuvaj"),
        ),
      ],
    );
  }

  Future _save() async {
    final formValid = _formKey.currentState?.saveAndValidate() ?? false;
    final specialtiesValid = _selectedCategoryIds.isNotEmpty;
    final hoursValid = _workingHours.isNotEmpty;

    if (!specialtiesValid || !hoursValid) {
      setState(() {
        _showSpecialtyError = !specialtiesValid;
        _showHoursError = !hoursValid;
      });
    }
    if (!formValid || !specialtiesValid || !hoursValid) return;

    final formData = Map<String, dynamic>.from(_formKey.currentState!.value);

    setState(() => _saving = true);
    try {
      formData['photoAssetId'] =
          await _imagePickerKey.currentState?.resolveAssetId();

      int doctorId;
      if (widget.doctor != null) {
        final updated = await _provider.update(widget.doctor!.id!, formData);
        doctorId = updated.id!;
      } else {
        final created = await _provider.insert(formData);
        doctorId = created.id!;
      }

      await _saveSpecialties(doctorId);
      await _saveWorkingHours(doctorId);

      if (!mounted) return;
      Navigator.of(context).pop("reload");
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      alertBox(context, "Greška", "Greška prilikom čuvanja: $e");
    }
  }

  Future<void> _saveSpecialties(int doctorId) async {
    final originalCategoryIds =
        _originalSpecialties.map((s) => s.serviceCategoryId).whereType<int>().toSet();

    for (final specialty in _originalSpecialties) {
      if (specialty.serviceCategoryId != null &&
          !_selectedCategoryIds.contains(specialty.serviceCategoryId)) {
        await _specialtyProvider.remove(specialty.id!);
      }
    }
    for (final categoryId in _selectedCategoryIds) {
      if (!originalCategoryIds.contains(categoryId)) {
        await _specialtyProvider.insert({
          "doctorId": doctorId,
          "serviceCategoryId": categoryId,
        });
      }
    }
  }

  Future<void> _saveWorkingHours(int doctorId) async {
    final currentDays = _workingHours.keys.toSet();

    for (final h in _originalWorkingHours) {
      if (h.dayOfWeek != null && !currentDays.contains(h.dayOfWeek)) {
        await _workingHoursProvider.remove(h.id!);
      }
    }
    for (final entry in _workingHours.entries) {
      final dayHours = entry.value;
      if (dayHours.existingId != null) {
        await _workingHoursProvider.update(dayHours.existingId!, {
          "startTime": _formatTimeOfDay(dayHours.start),
          "endTime": _formatTimeOfDay(dayHours.end),
        });
      } else {
        await _workingHoursProvider.insert({
          "doctorId": doctorId,
          "dayOfWeek": entry.key,
          "startTime": _formatTimeOfDay(dayHours.start),
          "endTime": _formatTimeOfDay(dayHours.end),
        });
      }
    }
  }
}
