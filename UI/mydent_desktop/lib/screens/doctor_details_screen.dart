import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/doctor.dart';
import '../providers/asset_provider.dart';
import '../providers/doctor_provider.dart';
import '../utils/utils_widgets.dart';
import '../widgets/image_asset_picker.dart';

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
  }

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
                    child: _buildForm(theme),
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

  Future _save() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = Map<String, dynamic>.from(_formKey.currentState!.value);

      try {
        formData['photoAssetId'] =
            await _imagePickerKey.currentState?.resolveAssetId();

        if (widget.doctor != null) {
          await _provider.update(widget.doctor!.id!, formData);
        } else {
          await _provider.insert(formData);
        }

        if (!mounted) return;
        Navigator.of(context).pop("reload");
      } catch (e) {
        if (!mounted) return;
        alertBox(context, "Greška", "Greška prilikom čuvanja: $e");
      }
    }
  }
}
