import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/asset_provider.dart';

/// Square image thumbnail for an entity's `xAssetId` FK (News.imageAssetId) —
/// the rectangular counterpart to AssetAvatar, for News' redesigned square
/// cards. Falls back to a plain icon tile when there's no image, same
/// lazy-fetch-by-id pattern as AssetAvatar.
class AssetThumbnail extends StatefulWidget {
  final int? assetId;
  final double size;
  final IconData placeholderIcon;
  final BorderRadius? borderRadius;

  const AssetThumbnail({
    super.key,
    required this.assetId,
    this.size = 64,
    this.placeholderIcon = Icons.image_outlined,
    this.borderRadius,
  });

  @override
  State<AssetThumbnail> createState() => _AssetThumbnailState();
}

class _AssetThumbnailState extends State<AssetThumbnail> {
  String? _base64;

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
      setState(() => _base64 = null);
      return;
    }
    try {
      final asset = await context.read<AssetProvider>().getById(widget.assetId!);
      if (!mounted) return;
      setState(() => _base64 = asset.base64Content);
    } catch (_) {
      // Missing image is fine — falls back to the placeholder icon.
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(12);
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: widget.size,
        height: widget.size,
        color: Theme.of(context).cardColor,
        child: _base64 != null
            ? Image.memory(base64Decode(_base64!), fit: BoxFit.cover)
            : Icon(widget.placeholderIcon,
                size: widget.size * 0.4, color: Colors.grey[500]),
      ),
    );
  }
}
