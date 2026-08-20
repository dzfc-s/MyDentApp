import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/asset_provider.dart';

/// Small circular avatar for an entity's `xAssetId` FK (Doctor.photoAssetId), used in dropdowns
/// and detail rows. Fetches the asset lazily and falls back to a placeholder icon.
class AssetAvatar extends StatefulWidget {
  final int? assetId;
  final double radius;
  final IconData placeholderIcon;

  const AssetAvatar({
    super.key,
    required this.assetId,
    this.radius = 16,
    this.placeholderIcon = Icons.person_outline,
  });

  @override
  State<AssetAvatar> createState() => _AssetAvatarState();
}

class _AssetAvatarState extends State<AssetAvatar> {
  String? _base64;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AssetAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetId != widget.assetId) _load();
  }

  Future<void> _load() async {
    if (widget.assetId == null) {
      setState(() => _base64 = null);
      return;
    }
    try {
      final asset =
          await context.read<AssetProvider>().getById(widget.assetId!);
      if (!mounted) return;
      setState(() => _base64 = asset.base64Content);
    } catch (_) {
      // Missing image is fine — falls back to the placeholder icon.
    }
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: widget.radius,
      backgroundImage:
          _base64 != null ? MemoryImage(base64Decode(_base64!)) : null,
      child: _base64 == null
          ? Icon(widget.placeholderIcon, size: widget.radius)
          : null,
    );
  }
}
