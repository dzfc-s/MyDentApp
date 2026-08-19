import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/news.dart';
import '../providers/asset_provider.dart';
import '../providers/news_provider.dart';
import '../utils/utils_widgets.dart';
import '../widgets/image_asset_picker.dart';

class NewsDetailsScreen extends StatefulWidget {
  final News? news;

  const NewsDetailsScreen({super.key, this.news});

  @override
  State<NewsDetailsScreen> createState() => _NewsDetailsScreenState();
}

class _NewsDetailsScreenState extends State<NewsDetailsScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _imagePickerKey = GlobalKey<ImageAssetPickerState>();
  Map<String, dynamic> _initialValue = {};

  late NewsProvider _provider;
  late AssetProvider _assetProvider;

  @override
  void initState() {
    super.initState();

    _initialValue = {
      'title': widget.news?.title ?? '',
      'content': widget.news?.content ?? '',
      'isPublished': widget.news?.isPublished ?? true,
    };

    _provider = context.read<NewsProvider>();
    _assetProvider = context.read<AssetProvider>();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MasterScreen(
      title: widget.news != null ? 'Uredi vijest' : 'Nova vijest',
      currentSection: AppSection.news,
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
            initialAssetId: widget.news?.imageAssetId,
            assetProvider: _assetProvider,
          ),
          const SizedBox(height: 16.0),
          FormBuilderTextField(
            name: 'title',
            decoration: const InputDecoration(labelText: "Naslov"),
            validator: (v) => (v == null || v.isEmpty) ? mField : null,
          ),
          const SizedBox(height: 16.0),
          FormBuilderTextField(
            name: 'content',
            decoration: const InputDecoration(labelText: "Sadržaj"),
            maxLines: 6,
            validator: (v) => (v == null || v.isEmpty) ? mField : null,
          ),
          const SizedBox(height: 8.0),
          FormBuilderCheckbox(name: 'isPublished', title: const Text("Objavljena")),
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
        formData['imageAssetId'] =
            await _imagePickerKey.currentState?.resolveAssetId();

        if (widget.news != null) {
          await _provider.update(widget.news!.id!, formData);
        } else {
          formData.remove('isPublished');
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
