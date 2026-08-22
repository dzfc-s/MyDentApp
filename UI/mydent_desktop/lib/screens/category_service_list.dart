import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/dental_service.dart';
import '../models/service_category.dart';
import '../providers/dental_service_provider.dart';
import '../providers/service_category_provider.dart';
import '../theme/app_theme.dart';
import '../utils/utils_widgets.dart';
import '../widgets/asset_thumbnail.dart';
import 'dental_service_details_screen.dart';
import 'service_category_details_screen.dart';

/// Replaces the former separate "Kategorije usluga" and "Usluge" sections —
/// services only ever make sense in the context of their category (that's
/// what determines which doctors can perform them), so browsing them as two
/// unrelated flat tables meant constantly cross-referencing IDs by eye.
/// Deliberately has no search — the whole point is a small, at-a-glance
/// browse view, not a table to filter through.
class CategoryServiceList extends StatefulWidget {
  const CategoryServiceList({super.key});

  @override
  State<CategoryServiceList> createState() => _CategoryServiceListState();
}

class _CategoryServiceListState extends State<CategoryServiceList> {
  late ServiceCategoryProvider _categoryProvider;
  late DentalServiceProvider _serviceProvider;

  bool isLoading = true;
  List<ServiceCategory> _categories = [];
  List<DentalService> _services = [];

  @override
  void initState() {
    super.initState();
    _categoryProvider = context.read<ServiceCategoryProvider>();
    _serviceProvider = context.read<DentalServiceProvider>();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<dynamic>([
        _categoryProvider.get(filter: {"pageSize": 500}),
        _serviceProvider.get(filter: {"pageSize": 500}),
      ]);
      if (!mounted) return;
      final categories = List<ServiceCategory>.from(results[0].items ?? []);
      categories.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
      setState(() {
        _categories = categories;
        _services = List<DentalService>.from(results[1].items ?? []);
        isLoading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      alertBox(context, 'Greška', e.toString());
    }
  }

  List<DentalService> _servicesFor(int? categoryId) {
    final list = _services.where((s) => s.serviceCategoryId == categoryId).toList();
    list.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: "Usluge",
      currentSection: AppSection.dentalServices,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _newCategory,
                      icon: const Icon(Icons.add),
                      label: const Text("Nova kategorija"),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _categories.isEmpty
                        ? const Center(child: Text("Nema kategorija usluga."))
                        : ListView.builder(
                            itemCount: _categories.length,
                            itemBuilder: (context, index) =>
                                _buildCategoryCard(_categories[index]),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCategoryCard(ServiceCategory category) {
    final categoryActive = category.isActive == true;
    final services = _servicesFor(category.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: categoryActive ? null : const Color(0xFFF3F3F3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(category.name ?? '',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                StatusBadge.active(categoryActive),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: "Uredi kategoriju",
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editCategory(category),
                ),
                if (categoryActive)
                  IconButton(
                    tooltip: "Deaktiviraj kategoriju",
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDeactivateCategory(category),
                  )
                else
                  IconButton(
                    tooltip: "Aktiviraj kategoriju",
                    icon: const Icon(Icons.restore, color: Colors.green),
                    onPressed: () => _activateCategory(category),
                  ),
              ],
            ),
            if ((category.description ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 8),
                child: Text(category.description!,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            const Divider(height: 16),
            if (services.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text("Nema usluga u ovoj kategoriji.",
                    style: TextStyle(color: Colors.grey)),
              )
            else
              ...services.map((s) => _buildServiceRow(s, categoryActive)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _newService(category.id),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Nova usluga"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceRow(DentalService service, bool categoryActive) {
    final serviceActive = service.isActive == true;
    // A service can't be meaningfully edited/reactivated on its own while
    // its category is inactive — it would immediately look broken again
    // (offered nowhere, since booking already only looks at active
    // categories) — the category has to come back first.
    final editable = categoryActive;

    return Opacity(
      opacity: editable ? 1 : 0.55,
      child: InkWell(
        onTap: editable ? () => _editService(service) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              AssetThumbnail(assetId: service.imageAssetId, size: 32),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: Text(service.name ?? ''),
              ),
              Expanded(
                child: Text(
                  service.price != null ? "${service.price} KM" : '',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              Expanded(
                child: Text(
                  service.durationMinutes != null
                      ? "${service.durationMinutes} min"
                      : '',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              StatusBadge.active(serviceActive),
              const SizedBox(width: 8),
              if (!serviceActive && editable)
                IconButton(
                  tooltip: "Aktiviraj uslugu",
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.restore, color: Colors.green, size: 20),
                  onPressed: () => _activateService(service),
                )
              else if (serviceActive)
                IconButton(
                  tooltip: "Deaktiviraj uslugu",
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _confirmDeactivateService(service),
                )
              else
                const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _newCategory() async {
    final refresh = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const ServiceCategoryDetailsScreen(category: null),
    ));
    if (refresh == "reload") _load();
  }

  Future<void> _editCategory(ServiceCategory category) async {
    final refresh = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ServiceCategoryDetailsScreen(category: category),
    ));
    if (refresh == "reload") _load();
  }

  Future<void> _newService(int? categoryId) async {
    final refresh = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) =>
          DentalServiceDetailsScreen(service: null, initialCategoryId: categoryId),
    ));
    if (refresh == "reload") _load();
  }

  Future<void> _editService(DentalService service) async {
    final refresh = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => DentalServiceDetailsScreen(service: service),
    ));
    if (refresh == "reload") _load();
  }

  Future<void> _activateCategory(ServiceCategory c) async {
    try {
      await _categoryProvider.update(c.id!, {
        "name": c.name,
        "description": c.description,
        "recommendedRecallMonths": c.recommendedRecallMonths,
        "isActive": true,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Kategorija aktivirana")));
      _load();
    } on Exception catch (ex) {
      if (mounted) alertBox(context, "Greška", ex.toString());
    }
  }

  void _confirmDeactivateCategory(ServiceCategory c) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Deaktivacija"),
        content: Text(
            "Deaktivirati kategoriju '${c.name}'? Sve usluge unutar nje će takođe postati neaktivne, i njihovi budući zakazani termini će biti otkazani."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Odustani")),
          ElevatedButton(
            onPressed: () async {
              try {
                await _categoryProvider.remove(c.id!);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Kategorija deaktivirana")));
                _load();
              } on Exception catch (ex) {
                if (mounted) alertBoxMoveBack(context, "Greška", ex.toString());
              }
            },
            child: const Text("Da"),
          ),
        ],
      ),
    );
  }

  Future<void> _activateService(DentalService s) async {
    try {
      await _serviceProvider.update(s.id!, {
        "name": s.name,
        "description": s.description,
        "price": s.price,
        "durationMinutes": s.durationMinutes,
        "serviceCategoryId": s.serviceCategoryId,
        "imageAssetId": s.imageAssetId,
        "isActive": true,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Usluga aktivirana")));
      _load();
    } on Exception catch (ex) {
      if (mounted) alertBox(context, "Greška", ex.toString());
    }
  }

  void _confirmDeactivateService(DentalService s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Deaktivacija"),
        content: Text(
            "Deaktivirati uslugu '${s.name}'? Budući zakazani termini za ovu uslugu će biti automatski otkazani."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Odustani")),
          ElevatedButton(
            onPressed: () async {
              try {
                await _serviceProvider.remove(s.id!);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text("Usluga deaktivirana")));
                _load();
              } on Exception catch (ex) {
                if (mounted) alertBoxMoveBack(context, "Greška", ex.toString());
              }
            },
            child: const Text("Da"),
          ),
        ],
      ),
    );
  }
}
