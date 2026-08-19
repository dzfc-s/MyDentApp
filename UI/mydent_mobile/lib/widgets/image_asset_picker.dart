import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/asset.dart';
import '../providers/asset_provider.dart';

/// Reusable single-image picker for entities that store a nullable `xAssetId` FK
/// (Doctor.photoAssetId, DentalService.imageAssetId, News.imageAssetId). Shows the existing
/// image (fetched by id) if any, lets the user pick a replacement, and only uploads it as a new
/// Asset when the form is actually saved (via [resolveAssetId]) — so cancelling the form never
/// creates orphan assets on the server.
class ImageAssetPicker extends StatefulWidget {
  final int? initialAssetId;
  final AssetProvider assetProvider;

  const ImageAssetPicker({
    super.key,
    required this.initialAssetId,
    required this.assetProvider,
  });

  @override
  State<ImageAssetPicker> createState() => ImageAssetPickerState();
}

class ImageAssetPickerState extends State<ImageAssetPicker> {
  Asset? _existingAsset;
  Asset? _pickedAsset;
  bool _cleared = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    if (widget.initialAssetId != null) {
      try {
        _existingAsset =
            await widget.assetProvider.getById(widget.initialAssetId!);
      } catch (_) {
        // Ignore — asset may have been deleted independently of its owner.
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pick() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = await file.xFile.readAsBytes();
    setState(() {
      _pickedAsset = Asset(
        fileName: file.name,
        contentType:
            file.extension != null ? 'image/${file.extension}' : 'image/png',
        base64Content: base64Encode(bytes),
      );
      _cleared = false;
    });
  }

  void _clear() {
    setState(() {
      _pickedAsset = null;
      _existingAsset = null;
      _cleared = true;
    });
  }

  /// Uploads the newly picked image (if any) and returns the id to save on the parent entity:
  /// the new upload's id, the untouched existing id, or null if cleared/never set.
  Future<int?> resolveAssetId() async {
    if (_pickedAsset != null) {
      final uploaded =
          await widget.assetProvider.insert(_pickedAsset!.toJson());
      return uploaded.id;
    }
    if (_cleared) return null;
    return _existingAsset?.id ?? widget.initialAssetId;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final base64 = _pickedAsset?.base64Content ?? _existingAsset?.base64Content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (base64 != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              base64Decode(base64),
              height: 140,
              width: 140,
              fit: BoxFit.cover,
            ),
          )
        else
          Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image_outlined, size: 40),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.upload_outlined),
              label: const Text("Odaberi sliku"),
            ),
            if (base64 != null) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _clear,
                icon: const Icon(Icons.close),
                label: const Text("Ukloni"),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
