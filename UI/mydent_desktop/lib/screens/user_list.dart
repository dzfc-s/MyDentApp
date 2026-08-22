import 'package:MyDent_desktop/layouts/master_screen.dart';
import 'package:MyDent_desktop/models/search_result.dart';
import 'package:MyDent_desktop/models/user.dart';
import 'package:MyDent_desktop/providers/user_provider.dart';
import 'package:MyDent_desktop/screens/patient_health_record_screen.dart';
import 'package:MyDent_desktop/screens/user_details_screen.dart';
import 'package:MyDent_desktop/utils/utils_widgets.dart';
import 'package:MyDent_desktop/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserList extends StatefulWidget {
  const UserList({super.key});

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  late UserProvider _userProvider;
  SearchResult<User>? result;
  bool isLoading = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userProvider = context.read<UserProvider>();
    initTable();
  }

  Future<void> _search() async {
    try {
      setState(() => isLoading = true);
      var data = await _userProvider.get(filter: {
        "name": _nameController.text,
        "username": _usernameController.text,
        "pageSize": 200,
      });
      if (!mounted) return;
      setState(() {
        result = data;
        isLoading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      alertBox(context, 'Greška', e.toString());
    }
  }

  Future<void> initTable() async {
    try {
      var data = await _userProvider.get(filter: {"pageSize": 200});
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
      title: "Korisnici",
      currentSection: AppSection.users,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(theme),
            const SizedBox(height: 20),
            if (!isLoading) ...[
              _buildStats(theme),
              const SizedBox(height: 20),
            ],
            _buildSearchCard(theme),
            const SizedBox(height: 16),
            if (isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              _buildTable(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(ThemeData theme) {
    final users = result?.items ?? [];
    final active = users.where((u) => u.isActive == true).length;
    return Row(
      children: [
        StatCard(
          icon: Icons.people_alt_outlined,
          label: "Ukupno korisnika",
          value: users.length.toString(),
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
          icon: Icons.block_outlined,
          label: "Neaktivni",
          value: (users.length - active).toString(),
          color: theme.colorScheme.error,
        ),
      ],
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
              child: Icon(Icons.people_alt_outlined,
                  color: theme.colorScheme.onPrimaryContainer, size: 28),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Upravljanje korisnicima',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('Upravljajte korisnicima sistema i njihovim pristupom',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: () async {
            final refresh = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const UserDetailsScreen(user: null),
              ),
            );
            if (refresh == "reload") initTable();
          },
          icon: const Icon(Icons.person_add_outlined),
          label: const Text("Dodaj korisnika"),
        ),
      ],
    );
  }

  Widget _buildSearchCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Pretraga po imenu",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: "Pretraga po korisničkom imenu",
                  prefixIcon: const Icon(Icons.alternate_email),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _search,
              icon: const Icon(Icons.search),
              label: const Text("Pretraga"),
            ),
          ],
        ),
      ),
    );
  }

  Expanded _buildTable(ThemeData theme) {
    final users = result?.items ?? [];

    if (users.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline,
                  size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              Text('Nema pronađenih korisnika',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.outline)),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: DataTable(
            showCheckboxColumn: false,
            headingRowColor: WidgetStateProperty.all(
                theme.colorScheme.primaryContainer.withValues(alpha: 0.5)),
            headingTextStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface),
            dataRowMinHeight: 56,
            dataRowMaxHeight: 56,
            dividerThickness: 0.5,
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text("Korisnik")),
              DataColumn(label: Text("Korisničko ime")),
              DataColumn(label: Text("Email")),
              DataColumn(label: Text("Rola")),
              DataColumn(label: Text("Status")),
              DataColumn(label: Text("Akcije")),
            ],
            rows: users.map((e) {
              final fullName =
                  '${e.firstName ?? ''} ${e.lastName ?? ''}'.trim();
              final initials = _initials(e.firstName, e.lastName);
              return DataRow(
                onSelectChanged: (value) async {
                  final refresh = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UserDetailsScreen(user: e),
                    ),
                  );
                  if (refresh == "reload") initTable();
                },
                cells: [
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              theme.colorScheme.primaryContainer,
                          child: Text(
                            initials,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(fullName.isEmpty ? '—' : fullName),
                      ],
                    ),
                  ),
                  DataCell(Text(e.username ?? '—')),
                  DataCell(Text(e.email ?? '—')),
                  DataCell(_buildRoleChip(e.role, theme)),
                  DataCell(_buildStatusChip(e.isActive, theme)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: "Zdravstveni karton",
                          icon: Icon(Icons.medical_information_outlined,
                              color: theme.colorScheme.tertiary),
                          onPressed: () async {
                            final refresh =
                                await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    PatientHealthRecordScreen(patient: e),
                              ),
                            );
                            if (refresh == "reload") initTable();
                          },
                        ),
                        IconButton(
                          tooltip: "Uredi",
                          icon: Icon(Icons.edit_outlined,
                              color: theme.colorScheme.primary),
                          onPressed: () async {
                            final refresh =
                                await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserDetailsScreen(user: e),
                              ),
                            );
                            if (refresh == "reload") initTable();
                          },
                        ),
                        IconButton(
                          tooltip: "Obriši",
                          icon: Icon(Icons.delete_outline,
                              color: theme.colorScheme.error),
                          onPressed: () => _confirmDelete(e, theme),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(String? role, ThemeData theme) {
    if (role == null || role.isEmpty) return const Text('—');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool? isActive, ThemeData theme) {
    final active = isActive ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? Colors.green.shade100
            : theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 14,
            color: active ? Colors.green.shade700 : theme.colorScheme.error,
          ),
          const SizedBox(width: 4),
          Text(
            active ? 'Aktivan' : 'Neaktivan',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active
                  ? Colors.green.shade700
                  : theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(User e, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: theme.colorScheme.error),
            const SizedBox(width: 8),
            const Text("Brisanje korisnika"),
          ],
        ),
        content: Text(
            "Da li ste sigurni da želite obrisati korisnika ${e.firstName ?? 'ovog korisnika'}? Ova radnja se ne može poništiti."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Odustani"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error),
            onPressed: () async {
              try {
                await _userProvider.remove(e.id!);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Korisnik uspješno obrisan")),
                );
                Navigator.pop(context);
                initTable();
              } on Exception catch (ex) {
                alertBoxMoveBack(context, "Greška", ex.toString());
              }
            },
            child: const Text("Obriši"),
          ),
        ],
      ),
    );
  }

  String _initials(String? first, String? last) {
    final f = (first?.isNotEmpty == true) ? first![0].toUpperCase() : '';
    final l = (last?.isNotEmpty == true) ? last![0].toUpperCase() : '';
    return '$f$l';
  }
}
