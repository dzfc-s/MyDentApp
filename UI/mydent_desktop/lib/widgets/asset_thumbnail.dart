import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/asset_provider.dart';

/// Small rounded thumbnail for an entity's `xAssetId` FK (Doctor.photoAssetId,
/// DentalService.imageAssetId, News.imageAssetId), used in list/table rows. Fetches the asset
/// lazily and shows a placeholder icon while loading, on null id, or on fetch failure.
class AssetThumbnail extends StatefulWidget {
  final int? assetId;
  final double size;
  final IconData placeholderIcon;

  const AssetThumbnail({
    super.key,
    required this.assetId,
    this.size = 36,
    this.placeholderIcon = Icons.image_outlined,
  });

  @override
  State<AssetThumbnail> createState() => _AssetThumbnailState();
}

class _AssetThumbnailState extends State<AssetThumbnail> {
  String? _base64;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AssetThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetId != widget.assetId) _load();
  }

  Future<void> _load() async {
    if (widget.assetId == null) {
      setState(() {
        _base64 = null;
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    try {
      final asset =
          await context.read<AssetProvider>().getById(widget.assetId!);
      if (!mounted) return;
      setState(() {
        _base64 = asset.base64Content;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill = widget.size.isInfinite;
    final placeholderSize = fill ? 32.0 : widget.size * 0.55;

    Widget content = _isLoading
        ? Container(color: theme.colorScheme.surfaceContainerHighest)
        : _base64 != null
            ? Image.memory(base64Decode(_base64!), fit: BoxFit.cover)
            : Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(widget.placeholderIcon,
                    size: placeholderSize, color: theme.colorScheme.outline),
              );

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: fill
          ? SizedBox.expand(child: content)
          : SizedBox(width: widget.size, height: widget.size, child: content),
    );
  }
}
