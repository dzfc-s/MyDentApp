import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/service_category.dart';
import '../providers/service_category_provider.dart';
import '../utils/utils_widgets.dart';

class ServiceCategoryDetailsScreen extends StatefulWidget {
  final ServiceCategory? category;

  const ServiceCategoryDetailsScreen({super.key, this.category});

  @override
  State<ServiceCategoryDetailsScreen> createState() =>
      _ServiceCategoryDetailsScreenState();
}

class _ServiceCategoryDetailsScreenState
    extends State<ServiceCategoryDetailsScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  Map<String, dynamic> _initialValue = {};

  late ServiceCategoryProvider _provider;

  @override
  void initState() {
    super.initState();

    _initialValue = {
      'name': widget.category?.name ?? '',
      'description': widget.category?.description ?? '',
      'recommendedRecallMonths':
          widget.category?.recommendedRecallMonths?.toString() ?? '',
      'isActive': widget.category?.isActive ?? true,
    };

    _provider = context.read<ServiceCategoryProvider>();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MasterScreen(
      title: widget.category != null
          ? 'Uredi kategoriju'
          : 'Nova kategorija usluga',
      currentSection: AppSection.dentalServices,
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
          FormBuilderTextField(
            name: 'name',
            decoration: const InputDecoration(labelText: "Naziv"),
            validator: (v) => (v == null || v.isEmpty) ? mField : null,
          ),
          const SizedBox(height: 16.0),
          FormBuilderTextField(
            name: 'description',
            decoration: const InputDecoration(labelText: "Opis"),
            maxLines: 3,
          ),
          const SizedBox(height: 16.0),
          FormBuilderTextField(
            name: 'recommendedRecallMonths',
            decoration: const InputDecoration(
              labelText: "Preporučeni razmak kontrole (mjeseci)",
              helperText:
                  "Koristi se za podsjetnike pacijentima (npr. 6 za redovnu kontrolu)",
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.isEmpty) return null;
              return int.tryParse(v) == null ? numericField : null;
            },
          ),
          if (widget.category != null) ...[
            const SizedBox(height: 8.0),
            FormBuilderCheckbox(
              name: 'isActive',
              title: const Text("Aktivna"),
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
        ElevatedButton(onPressed: _save, child: const Text("Sačuvaj")),
      ],
    );
  }

  Future _save() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = Map<String, dynamic>.from(_formKey.currentState!.value);
      formData['recommendedRecallMonths'] =
          int.tryParse(formData['recommendedRecallMonths']?.toString() ?? '');

      try {
        if (widget.category != null) {
          await _provider.update(widget.category!.id!, formData);
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
