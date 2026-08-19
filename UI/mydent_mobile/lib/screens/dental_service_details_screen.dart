import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/asset.dart';
import '../models/dental_service.dart';
import '../providers/asset_provider.dart';
import '../utils/utils_widgets.dart';
import 'book_appointment_screen.dart';

class DentalServiceDetailsScreen extends StatefulWidget {
  final DentalService service;

  const DentalServiceDetailsScreen({super.key, required this.service});

  @override
  State<DentalServiceDetailsScreen> createState() =>
      _DentalServiceDetailsScreenState();
}

class _DentalServiceDetailsScreenState
    extends State<DentalServiceDetailsScreen> {
  Asset? _image;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    if (widget.service.imageAssetId == null) return;
    try {
      final asset = await context
          .read<AssetProvider>()
          .getById(widget.service.imageAssetId!);
      if (mounted) setState(() => _image = asset);
    } catch (_) {
      // No image is fine — falls back to the placeholder icon below.
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    return Scaffold(
      appBar: AppBar(title: Text(s.name ?? '')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 220,
              width: double.infinity,
              child: _image?.base64Content != null
                  ? imageFromBase64String(_image!.base64Content!)
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.medical_services_outlined,
                          size: 64, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name ?? '',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(s.serviceCategoryName ?? '',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Chip(label: Text("${s.price} KM")),
                      const SizedBox(width: 8),
                      Chip(label: Text("${s.durationMinutes} min")),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(s.description ?? '',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookAppointmentScreen(service: s),
                        ),
                      ),
                      child: const Text("Zakaži termin"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
