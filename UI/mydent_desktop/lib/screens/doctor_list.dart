import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/doctor.dart';
import '../models/search_result.dart';
import '../providers/doctor_provider.dart';
import '../utils/utils_widgets.dart';
import '../widgets/asset_thumbnail.dart';
import '../widgets/stat_card.dart';
import 'doctor_details_screen.dart';

class DoctorList extends StatefulWidget {
  const DoctorList({super.key});

  @override
  State<DoctorList> createState() => _DoctorListState();
}

class _DoctorListState extends State<DoctorList> {
  late DoctorProvider _provider;
  SearchResult<Doctor>? result;
  bool isLoading = true;

  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider = context.read<DoctorProvider>();
    initTable();
  }

  Future<void> initTable() async {
    try {
      var data =
          await _provider.get(filter: {"firstName": _nameController.text});
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
    final theme = Theme.of(context);
    return MasterScreen(
      title: "Doktori",
      currentSection: AppSection.doctors,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(theme),
            const SizedBox(height: 20),
            _buildStats(theme),
            const SizedBox(height: 20),
            _buildSearch(theme),
            const SizedBox(height: 16),
            if (isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              _buildGrid(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.medical_services_outlined,
                  color: theme.colorScheme.onPrimaryContainer, size: 28),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Doktori',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('Upravljajte timom doktora klinike',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: () async {
            var refresh = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const DoctorDetailsScreen(doctor: null),
              ),
            );
            if (refresh == "reload") initTable();
          },
          icon: const Icon(Icons.person_add_outlined),
          label: const Text("Novi doktor"),
        ),
      ],
    );
  }

  Widget _buildStats(ThemeData theme) {
    final doctors = result?.items ?? [];
    final active = doctors.where((d) => d.isActive == true).length;
    return Row(
      children: [
        StatCard(
          icon: Icons.groups_outlined,
          label: "Ukupno doktora",
          value: doctors.length.toString(),
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.check_circle_outline,
          label: "Aktivni",
          value: active.toString(),
          color: theme.colorScheme.tertiary,
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.pause_circle_outlined,
          label: "Neaktivni",
          value: (doctors.length - active).toString(),
          color: theme.colorScheme.error,
        ),
      ],
    );
  }

  Widget _buildSearch(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Pretraga po imenu",
                  prefixIcon: const Icon(Icons.search),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
                onSubmitted: (_) => initTable(),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: initTable,
              icon: const Icon(Icons.search),
              label: const Text("Pretraga"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(ThemeData theme) {
    final doctors = result?.items ?? [];

    if (doctors.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.medical_services_outlined,
                  size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              Text('Nema pronađenih doktora',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.outline)),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.only(top: 4),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 260,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.78,
        ),
        itemCount: doctors.length,
        itemBuilder: (context, index) => _DoctorCard(
          doctor: doctors[index],
          onTap: () async {
            var refresh = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    DoctorDetailsScreen(doctor: doctors[index]),
              ),
            );
            if (refresh == "reload") initTable();
          },
          onDelete: () => _confirmDelete(doctors[index]),
        ),
      ),
    );
  }

  void _confirmDelete(Doctor e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Brisanje"),
        content: Text(
            "Deaktivirati doktora '${e.firstName} ${e.lastName}'? Budući zakazani termini kod ovog doktora će biti automatski otkazani."),
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
                  const SnackBar(content: Text("Doktor obrisan")),
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

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DoctorCard({
    required this.doctor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = doctor.isActive ?? false;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.3,
              child: AssetThumbnail(
                assetId: doctor.photoAssetId,
                size: double.infinity,
                placeholderIcon: Icons.person_outline,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${doctor.firstName ?? ''} ${doctor.lastName ?? ''}'
                              .trim(),
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.bio?.isNotEmpty == true
                        ? doctor.bio!
                        : 'Nema biografije',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: "Obriši",
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.delete_outline,
                          color: theme.colorScheme.error, size: 20),
                      onPressed: onDelete,
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
