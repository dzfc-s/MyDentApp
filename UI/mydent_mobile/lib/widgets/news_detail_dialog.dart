import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/asset.dart';
import '../models/news.dart';
import '../providers/asset_provider.dart';
import '../utils/utils_widgets.dart';

class NewsDetailDialog extends StatefulWidget {
  final News news;

  const NewsDetailDialog({super.key, required this.news});

  @override
  State<NewsDetailDialog> createState() => _NewsDetailDialogState();
}

class _NewsDetailDialogState extends State<NewsDetailDialog> {
  Asset? _image;

  @override
  void initState() {
    super.initState();
    if (widget.news.imageAssetId != null) {
      context
          .read<AssetProvider>()
          .getById(widget.news.imageAssetId!)
          .then((a) {
        if (mounted) setState(() => _image = a);
      }).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.news.title ?? ''),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_image?.base64Content != null)
              imageFromBase64String(_image!.base64Content!),
            const SizedBox(height: 12),
            Text(widget.news.content ?? ''),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Zatvori"),
        ),
      ],
    );
  }
}
