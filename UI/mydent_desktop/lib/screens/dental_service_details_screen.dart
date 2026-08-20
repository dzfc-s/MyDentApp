import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/dental_service.dart';
import '../models/search_result.dart';
import '../models/service_category.dart';
import '../providers/asset_provider.dart';
import '../providers/dental_service_provider.dart';
import '../providers/service_category_provider.dart';
import '../utils/utils_widgets.dart';
import '../widgets/image_asset_picker.dart';

class DentalServiceDetailsScreen extends StatefulWidget {
  final DentalService? service;

  const DentalServiceDetailsScreen({super.key, this.service});

  @override
  State<DentalServiceDetailsScreen> createState() =>
      _DentalServiceDetailsScreenState();
}

class _DentalServiceDetailsScreenState
    extends State<DentalServiceDetailsScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _imagePickerKey = GlobalKey<ImageAssetPickerState>();
  Map<String, dynamic> _initialValue = {};

  late DentalServiceProvider _provider;
  late ServiceCategoryProvider _categoryProvider;
  late AssetProvider _assetProvider;

  SearchResult<ServiceCategory>? _categoriesResult;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _initialValue = {
      'name': widget.service?.name ?? '',
      'description': widget.service?.description ?? '',
      'price': widget.service?.price?.toString() ?? '',
      'durationMinutes': widget.service?.durationMinutes?.toString() ?? '',
      'serviceCategoryId': widget.service?.serviceCategoryId,
      'isActive': widget.service?.isActive ?? true,
    };

    _provider = context.read<DentalServiceProvider>();
    _categoryProvider = context.read<ServiceCategoryProvider>();
    _assetProvider = context.read<AssetProvider>();
    _initForm();
  }

  Future _initForm() async {
    try {
      var categories = await _categoryProvider.get(filter: {});
      if (!mounted) return;
      setState(() {
        _categoriesResult = categories;
        isLoading = false;
      });
    } on Exception catch (e) {
      alertBox(context, "Greška", e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MasterScreen(
      title: widget.service != null ? 'Uredi uslugu' : 'Nova usluga',
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
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
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
        children: [
          ImageAssetPicker(
            key: _imagePickerKey,
            initialAssetId: widget.service?.imageAssetId,
            assetProvider: _assetProvider,
          ),
          const SizedBox(height: 16.0),
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
          Row(
            children: [
              Expanded(
                child: FormBuilderTextField(
                  name: 'price',
                  decoration: const InputDecoration(labelText: "Cijena (KM)"),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return mField;
                    return double.tryParse(v) == null ? numericField : null;
                  },
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: FormBuilderTextField(
                  name: 'durationMinutes',
                  decoration:
                      const InputDecoration(labelText: "Trajanje (minuta)"),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return mField;
                    return int.tryParse(v) == null ? numericField : null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FormBuilderDropdown(
                  name: 'serviceCategoryId',
                  decoration:
                      const InputDecoration(labelText: "Kategorija usluge"),
                  validator: (v) => v == null ? mField : null,
                  items: _categoriesResult?.items
                          ?.map((c) => DropdownMenuItem(
                              value: c.id, child: Text(c.name ?? '')))
                          .toList() ??
                      [],
                ),
              ),
              const SizedBox(width: 8.0),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: IconButton.filledTonal(
                  tooltip: "Nova kategorija",
                  icon: const Icon(Icons.add),
                  onPressed: _addCategory,
                ),
              ),
            ],
          ),
          if (widget.service != null) ...[
            const SizedBox(height: 8.0),
            FormBuilderCheckbox(name: 'isActive', title: const Text("Aktivna")),
          ],
        ],
      ),
    );
  }

  Future<void> _addCategory() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nova kategorija usluge"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Naziv"),
            autofocus: true,
            validator: (v) => (v == null || v.trim().isEmpty) ? mField : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Odustani"),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, nameController.text.trim());
              }
            },
            child: const Text("Dodaj"),
          ),
        ],
      ),
    );
    if (name == null) return;

    try {
      final created = await _categoryProvider.insert({'name': name});
      final categories = await _categoryProvider.get(filter: {});
      if (!mounted) return;
      setState(() => _categoriesResult = categories);
      _formKey.currentState?.fields['serviceCategoryId']
          ?.didChange(created.id);
    } catch (e) {
      if (!mounted) return;
      alertBox(context, "Greška", "Greška prilikom dodavanja kategorije: $e");
    }
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
      formData['price'] = double.tryParse(formData['price'].toString());
      formData['durationMinutes'] =
          int.tryParse(formData['durationMinutes'].toString());

      try {
        formData['imageAssetId'] =
            await _imagePickerKey.currentState?.resolveAssetId();

        if (widget.service != null) {
          await _provider.update(widget.service!.id!, formData);
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
