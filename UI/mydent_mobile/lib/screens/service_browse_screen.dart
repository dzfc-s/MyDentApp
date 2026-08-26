import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dental_service.dart';
import '../models/search_result.dart';
import '../models/service_category.dart';
import '../providers/dental_service_provider.dart';
import '../providers/service_category_provider.dart';
import '../utils/utils_widgets.dart';
import 'dental_service_details_screen.dart';

/// Dedicated full-screen services browser — Figma's reference app has its own
/// "Usluge" screen (search + category filter + full catalog), separate from
/// Home's shorter inline preview. Home only ever showed services matching
/// whatever filter was active there; this gives patients a place to browse
/// the whole catalog without the rest of Home's content around it.
class ServiceBrowseScreen extends StatefulWidget {
  /// Pre-fills the search box when opened from Home's hero search — that
  /// search used to just re-filter Home's own small inline preview, which
  /// was confusing (a search box at the top of the screen visibly affecting
  /// a section several scrolls down, competing with the category chips and
  /// "Prikaži sve" link for the same job). Now Home's search box is purely an
  /// entry point into this dedicated browse screen instead.
  final String? initialQuery;

  const ServiceBrowseScreen({super.key, this.initialQuery});

  @override
  State<ServiceBrowseScreen> createState() => _ServiceBrowseScreenState();
}

class _ServiceBrowseScreenState extends State<ServiceBrowseScreen> {
  late DentalServiceProvider _serviceProvider;
  late ServiceCategoryProvider _categoryProvider;

  SearchResult<DentalService>? services;
  SearchResult<ServiceCategory>? categories;
  int? _selectedCategoryId;
  bool isLoading = true;

  late final TextEditingController _searchController =
      TextEditingController(text: widget.initialQuery ?? '');

  @override
  void initState() {
    super.initState();
    _serviceProvider = context.read<DentalServiceProvider>();
    _categoryProvider = context.read<ServiceCategoryProvider>();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    try {
      final s = await _serviceProvider.get(filter: {
        "name": _searchController.text,
        if (_selectedCategoryId != null)
          "serviceCategoryId": _selectedCategoryId,
        "isActive": true,
      });
      final c = await _categoryProvider.get(filter: {"isActive": true});
      if (!mounted) return;
      setState(() {
        services = s;
        categories = c;
        isLoading = false;
      });
    } on Exception catch (e) {
      setState(() => isLoading = false);
      if (mounted) alertBox(context, 'Greška', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usluge')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pretraži usluge',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text("Sve"),
                    selected: _selectedCategoryId == null,
                    onSelected: (_) {
                      setState(() => _selectedCategoryId = null);
                      _load();
                    },
                  ),
                ),
                ...?categories?.items?.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c.name ?? ''),
                        selected: _selectedCategoryId == c.id,
                        onSelected: (_) {
                          setState(() => _selectedCategoryId = c.id);
                          _load();
                        },
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : (services?.items?.isEmpty ?? true)
                    ? const Center(child: Text('Nema pronađenih usluga.'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: services!.items!.length,
                          itemBuilder: (context, index) =>
                              _buildServiceTile(services!.items![index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTile(DentalService s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(s.name ?? ''),
        subtitle: Text("${s.serviceCategoryName ?? ''} · ${s.durationMinutes} min"),
        trailing: Text("${s.price} KM",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => DentalServiceDetailsScreen(service: s)),
        ),
      ),
    );
  }
}
