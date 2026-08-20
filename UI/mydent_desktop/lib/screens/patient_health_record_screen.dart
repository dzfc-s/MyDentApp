import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../utils/utils_widgets.dart';

const List<String> _bloodTypes = [
  'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
];

/// Patient health record ("Zdravstveni karton") — Allergies/BloodType/MedicalNotes live on the
/// User entity itself (patients have no separate table), so saving here submits the full
/// UserUpdateRequest shape with the account's existing values untouched, plus these 3 fields.
class PatientHealthRecordScreen extends StatefulWidget {
  final User patient;

  const PatientHealthRecordScreen({super.key, required this.patient});

  @override
  State<PatientHealthRecordScreen> createState() =>
      _PatientHealthRecordScreenState();
}

class _PatientHealthRecordScreenState
    extends State<PatientHealthRecordScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  late UserProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<UserProvider>();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.patient;
    final fullName = '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim();

    return MasterScreen(
      title: "Zdravstveni karton",
      currentSection: AppSection.users,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        _initials(p.firstName, p.lastName),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fullName.isEmpty ? '—' : fullName,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(p.username ?? '',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.colorScheme.outline)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildForm(),
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

  Widget _buildForm() {
    final p = widget.patient;
    return FormBuilder(
      key: _formKey,
      initialValue: {
        'bloodType': p.bloodType,
        'allergies': p.allergies ?? '',
        'medicalNotes': p.medicalNotes ?? '',
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormBuilderDropdown<String>(
            name: 'bloodType',
            decoration: const InputDecoration(labelText: "Krvna grupa"),
            items: _bloodTypes
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
          ),
          const SizedBox(height: 16.0),
          FormBuilderTextField(
            name: 'allergies',
            decoration: const InputDecoration(
              labelText: "Alergije",
              hintText: "npr. penicilin, lateks...",
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16.0),
          FormBuilderTextField(
            name: 'medicalNotes',
            decoration: const InputDecoration(
              labelText: "Medicinske napomene",
              hintText: "Hronična stanja, terapije, napomene za doktora...",
            ),
            maxLines: 6,
          ),
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
        ElevatedButton(onPressed: _save, child: const Text("Sačuvaj")),
      ],
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final values = _formKey.currentState!.value;
    final p = widget.patient;

    try {
      await _provider.update(p.id!, {
        'firstName': p.firstName,
        'lastName': p.lastName,
        'email': p.email,
        'username': p.username,
        'phoneNumber': p.phoneNumber,
        'isActive': p.isActive ?? true,
        'profileImageAssetId': p.profileImageAssetId,
        'bloodType': values['bloodType'],
        'allergies': values['allergies'],
        'medicalNotes': values['medicalNotes'],
      });

      if (!mounted) return;
      Navigator.of(context).pop("reload");
    } catch (e) {
      if (!mounted) return;
      alertBox(context, "Greška", "Greška prilikom čuvanja: $e");
    }
  }

  String _initials(String? first, String? last) {
    final f = (first?.isNotEmpty == true) ? first![0].toUpperCase() : '';
    final l = (last?.isNotEmpty == true) ? last![0].toUpperCase() : '';
    return '$f$l';
  }
}
