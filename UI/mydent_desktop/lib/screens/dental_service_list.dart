import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/dental_service.dart';
import '../models/search_result.dart';
import '../providers/dental_service_provider.dart';
import '../utils/utils_widgets.dart';
import '../widgets/asset_thumbnail.dart';
import '../widgets/stat_card.dart';
import 'dental_service_details_screen.dart';

class DentalServiceList extends StatefulWidget {
  const DentalServiceList({super.key});

  @override
  State<DentalServiceList> createState() => _DentalServiceListState();
}

class _DentalServiceListState extends State<DentalServiceList> {
  late DentalServiceProvider _provider;
  SearchResult<DentalService>? result;
  bool isLoading = true;

  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider = context.read<DentalServiceProvider>();
    initTable();
  }

  Future<void> initTable() async {
    try {
      var data = await _provider.get(filter: {"name": _nameController.text});
      setState(() {
        result = data;
        isLoading = false;
      });
    } on Exception catch (e) {
      alertBox(context, 'Greška', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: "Stomatološke usluge",
      currentSection: AppSection.dentalServices,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!isLoading) ...[
              _buildStats(),
              const SizedBox(height: 16),
            ],
            _buildSearch(),
            isLoading
                ? const Expanded(
                    child: Center(child: CircularProgressIndicator()))
                : _buildTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final services = result?.items ?? [];
    final active = services.where((s) => s.isActive == true).length;
    return Row(
      children: [
        StatCard(
          icon: Icons.medical_information_outlined,
          label: "Ukupno usluga",
          value: services.length.toString(),
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.check_circle_outline,
          label: "Aktivne",
          value: active.toString(),
          color: Theme.of(context).colorScheme.tertiary,
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.pause_circle_outlined,
          label: "Neaktivne",
          value: (services.length - active).toString(),
          color: Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }

  Padding _buildSearch() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(label: Text("Naziv")),
              ),
            ),
          ),
          ElevatedButton(onPressed: initTable, child: const Text("Pretraga")),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () async {
              var refresh = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      const DentalServiceDetailsScreen(service: null),
                ),
              );
              if (refresh == "reload") initTable();
            },
            child: const Text("Nova"),
          ),
        ],
      ),
    );
  }

  Expanded _buildTable() {
    return Expanded(
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text("")),
              DataColumn(label: Text("Naziv")),
              DataColumn(label: Text("Kategorija")),
              DataColumn(label: Text("Cijena")),
              DataColumn(label: Text("Trajanje (min)")),
              DataColumn(label: Text("Aktivna")),
              DataColumn(label: Text("Obriši")),
            ],
            rows: result?.items
                    ?.map(
                      (e) => DataRow(
                        onSelectChanged: (value) async {
                          var refresh = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  DentalServiceDetailsScreen(service: e),
                            ),
                          );
                          if (refresh == "reload") initTable();
                        },
                        cells: [
                          DataCell(AssetThumbnail(assetId: e.imageAssetId)),
                          DataCell(Text(e.name ?? '')),
                          DataCell(Text(e.serviceCategoryName ?? '')),
                          DataCell(Text(
                              e.price != null ? "${e.price} KM" : '')),
                          DataCell(Text(e.durationMinutes?.toString() ?? '')),
                          DataCell(Text(e.isActive == true ? "Da" : "Ne")),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _confirmDelete(e),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList() ??
                List.empty(),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(DentalService e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Brisanje"),
        content: Text(
            "Deaktivirati uslugu '${e.name}'? Budući zakazani termini za ovu uslugu će biti automatski otkazani."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Odustani"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _provider.remove(e.id!);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Usluga obrisana")),
                );
                Navigator.pop(context);
                initTable();
              } on Exception catch (ex) {
                alertBoxMoveBack(context, "Greška", ex.toString());
              }
            },
            child: const Text("Da"),
          ),
        ],
      ),
    );
  }
}
