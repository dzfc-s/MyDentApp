import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/doctor.dart';
import '../models/doctor_specialty.dart';
import '../models/search_result.dart';
import '../models/service_category.dart';
import '../providers/doctor_provider.dart';
import '../providers/doctor_specialty_provider.dart';
import '../providers/service_category_provider.dart';
import '../utils/utils_widgets.dart';

// Junction entity (Doctor <-> ServiceCategory) — DoctorSpecialtiesController only exposes
// insert/delete (no update), so this list manages both in one screen instead of a details page.
class DoctorSpecialtyList extends StatefulWidget {
  const DoctorSpecialtyList({super.key});

  @override
  State<DoctorSpecialtyList> createState() => _DoctorSpecialtyListState();
}

class _DoctorSpecialtyListState extends State<DoctorSpecialtyList> {
  late DoctorSpecialtyProvider _provider;
  late DoctorProvider _doctorProvider;
  late ServiceCategoryProvider _categoryProvider;

  SearchResult<DoctorSpecialty>? result;
  SearchResult<Doctor>? doctors;
  SearchResult<ServiceCategory>? categories;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _provider = context.read<DoctorSpecialtyProvider>();
    _doctorProvider = context.read<DoctorProvider>();
    _categoryProvider = context.read<ServiceCategoryProvider>();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _provider.get(filter: {});
      final d = await _doctorProvider.get(filter: {});
      final c = await _categoryProvider.get(filter: {});
      setState(() {
        result = data;
        doctors = d;
        categories = c;
        isLoading = false;
      });
    } on Exception catch (e) {
      alertBox(context, 'Greška', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: "Specijalnosti doktora",
      currentSection: AppSection.doctorSpecialties,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: isLoading ? null : _openAddDialog,
                child: const Text("Dodaj specijalnost"),
              ),
            ),
            const SizedBox(height: 8),
            isLoading
                ? const Expanded(
                    child: Center(child: CircularProgressIndicator()))
                : _buildTable(),
          ],
        ),
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
              DataColumn(label: Text("Doktor")),
              DataColumn(label: Text("Kategorija usluge")),
              DataColumn(label: Text("Obriši")),
            ],
            rows: result?.items
                    ?.map(
                      (e) => DataRow(cells: [
                        DataCell(Text(e.doctorName ?? '')),
                        DataCell(Text(e.serviceCategoryName ?? '')),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _confirmDelete(e),
                          ),
                        ),
                      ]),
                    )
                    .toList() ??
                List.empty(),
          ),
        ),
      ),
    );
  }

  void _openAddDialog() {
    int? doctorId;
    int? categoryId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Nova specijalnost"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: "Doktor"),
                items: doctors?.items
                        ?.map((d) => DropdownMenuItem(
                            value: d.id,
                            child: Text("${d.firstName} ${d.lastName}")))
                        .toList() ??
                    [],
                onChanged: (v) => setDialogState(() => doctorId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: "Kategorija usluge"),
                items: categories?.items
                        ?.map((c) => DropdownMenuItem(
                            value: c.id, child: Text(c.name ?? '')))
                        .toList() ??
                    [],
                onChanged: (v) => setDialogState(() => categoryId = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Odustani"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (doctorId == null || categoryId == null) return;
                try {
                  await _provider.insert({
                    "doctorId": doctorId,
                    "serviceCategoryId": categoryId,
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                  _load();
                } on Exception catch (e) {
                  alertBox(context, "Greška", e.toString());
                }
              },
              child: const Text("Dodaj"),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(DoctorSpecialty e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Brisanje"),
        content: const Text("Ukloniti ovu specijalnost?"),
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
                Navigator.pop(context);
                _load();
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
