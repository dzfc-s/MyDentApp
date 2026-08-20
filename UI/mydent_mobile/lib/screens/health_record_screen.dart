import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/user_provider.dart';
import '../utils/utils_widgets.dart';

const List<String> _bloodTypes = [
  'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
];

/// Patient's own health record ("Zdravstveni karton") — Allergies/BloodType/MedicalNotes live on
/// the User entity itself, so saving submits the full update request shape with the account's
/// existing values untouched, plus these 3 fields.
class HealthRecordScreen extends StatefulWidget {
  final User user;

  const HealthRecordScreen({super.key, required this.user});

  @override
  State<HealthRecordScreen> createState() => _HealthRecordScreenState();
}

class _HealthRecordScreenState extends State<HealthRecordScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  late UserProvider _provider;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _provider = context.read<UserProvider>();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return Scaffold(
      appBar: AppBar(title: const Text("Zdravstveni karton")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FormBuilder(
              key: _formKey,
              initialValue: {
                'bloodType': u.bloodType,
                'allergies': u.allergies ?? '',
                'medicalNotes': u.medicalNotes ?? '',
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ovi podaci pomažu doktoru da pruži sigurniju njegu.",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 20),
                  FormBuilderDropdown<String>(
                    name: 'bloodType',
                    decoration: const InputDecoration(labelText: "Krvna grupa"),
                    items: _bloodTypes
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  FormBuilderTextField(
                    name: 'allergies',
                    decoration: const InputDecoration(
                      labelText: "Alergije",
                      hintText: "npr. penicilin, lateks...",
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  FormBuilderTextField(
                    name: 'medicalNotes',
                    decoration: const InputDecoration(
                      labelText: "Medicinske napomene",
                      hintText: "Hronična stanja, terapije...",
                    ),
                    maxLines: 6,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("Sačuvaj"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final values = _formKey.currentState!.value;
    final u = widget.user;

    setState(() => _isSaving = true);
    try {
      await _provider.update(u.id!, {
        'firstName': u.firstName,
        'lastName': u.lastName,
        'email': u.email,
        'username': u.username,
        'phoneNumber': u.phoneNumber,
        'isActive': u.isActive ?? true,
        'profileImageAssetId': u.profileImageAssetId,
        'bloodType': values['bloodType'],
        'allergies': values['allergies'],
        'medicalNotes': values['medicalNotes'],
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Zdravstveni karton ažuriran")),
      );
      Navigator.pop(context, 'reload');
    } on Exception catch (e) {
      setState(() => _isSaving = false);
      if (mounted) alertBox(context, 'Greška', e.toString());
    }
  }
}
