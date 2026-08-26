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

/// Formerly split out of a "Korisnici" screen that mixed every account type
/// (Admin, Patient) in one table with a "Zdravstveni karton" action that only
/// ever made sense for patients. "Korisnici" itself was later removed
/// entirely — every account created through this app is a Patient (see
/// UserService.InsertAsync, which always assigns that role server-side;
/// there's no admin-account-creation flow anywhere), so a generic "Users"
/// section only ever listed the handful of seeded Admin accounts with no way
/// to add to them. This is that account management, scoped to Role=Patient,
/// with the health record as the primary action.
class PatientList extends StatefulWidget {
  const PatientList({super.key});

  @override
  State<PatientList> createState() => _PatientListState();
}

class _PatientListState extends State<PatientList> {
  late UserProvider _userProvider;
  SearchResult<User>? result;
  bool isLoading = true;

  final TextEditingController _nameController = TextEditingController();

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
        "role": "Patient",
        "name": _nameController.text,
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
      var data = await _userProvider.get(filter: {"role": "Patient", "pageSize": 200});
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MasterScreen(
      title: "Pacijenti",
      currentSection: AppSection.patients,
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
    final patients = result?.items ?? [];
    final active = patients.where((u) => u.isActive == true).length;
    return Row(
      children: [
        StatCard(
          icon: Icons.medical_information_outlined,
          label: "Ukupno pacijenata",
          value: patients.length.toString(),
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
          value: (patients.length - active).toString(),
          color: theme.colorScheme.error,
        ),
      ],
    );
  }

  Widget _buildPageHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.medical_information_outlined,
              color: theme.colorScheme.onPrimaryContainer, size: 28),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pacijenti',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text('Pregled pacijenata i pristup zdravstvenim kartonima',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: _openAddPatientDialog,
          icon: const Icon(Icons.person_add_outlined),
          label: const Text("Dodaj pacijenta"),
        ),
      ],
    );
  }

  Future<void> _openAddPatientDialog() async {
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final usernameController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    bool saving = false;

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Dodaj pacijenta"),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: firstNameController,
                            decoration: const InputDecoration(labelText: "Ime"),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? "Obavezno polje" : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: lastNameController,
                            decoration: const InputDecoration(labelText: "Prezime"),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? "Obavezno polje" : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: "Email"),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "Obavezno polje";
                        if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(v.trim())) {
                          return "Neispravan email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: "Korisničko ime"),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "Obavezno polje";
                        if (v.trim().length < 3) return "Minimalno 3 karaktera";
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: "Telefon"),
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (!RegExp(r'^\+?[0-9\s\-()]{6,20}$').hasMatch(v.trim())) {
                          return "Neispravan format telefona";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: "Lozinka"),
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Obavezno polje";
                        if (v.length < 6) return "Minimalno 6 karaktera";
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text("Odustani"),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() => saving = true);
                      try {
                        await _userProvider.insert({
                          "firstName": firstNameController.text.trim(),
                          "lastName": lastNameController.text.trim(),
                          "email": emailController.text.trim(),
                          "username": usernameController.text.trim(),
                          "phoneNumber": phoneController.text.trim(),
                          "password": passwordController.text,
                          "isActive": true,
                        });
                        if (!context.mounted) return;
                        Navigator.pop(context, true);
                      } on Exception catch (e) {
                        setDialogState(() => saving = false);
                        if (!context.mounted) return;
                        alertBox(context, "Greška", e.toString());
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Kreiraj"),
            ),
          ],
        ),
      ),
    );

    if (created == true) initTable();
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
    final patients = result?.items ?? [];

    if (patients.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.medical_information_outlined,
                  size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              Text('Nema pronađenih pacijenata',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.outline)),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: DataTable(
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text("Pacijent")),
              DataColumn(label: Text("Korisničko ime")),
              DataColumn(label: Text("Email")),
              DataColumn(label: Text("Status")),
              DataColumn(label: Text("Akcije")),
            ],
            rows: patients.map((e) {
              final fullName =
                  '${e.firstName ?? ''} ${e.lastName ?? ''}'.trim();
              final initials = _initials(e.firstName, e.lastName);
              final active = e.isActive ?? false;
              return DataRow(
                onSelectChanged: (value) async {
                  final refresh = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PatientHealthRecordScreen(patient: e),
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
                          // Editing an already-deactivated patient's data doesn't make sense —
                          // reactivate them first (same pattern as Doktori/Usluge).
                          tooltip: active ? "Uredi" : "Reaktivirajte pacijenta da biste uredili",
                          icon: Icon(Icons.edit_outlined,
                              color: active
                                  ? theme.colorScheme.primary
                                  : theme.disabledColor),
                          onPressed: active
                              ? () async {
                                  final refresh =
                                      await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          UserDetailsScreen(user: e),
                                    ),
                                  );
                                  if (refresh == "reload") initTable();
                                }
                              : null,
                        ),
                        if (active)
                          IconButton(
                            tooltip: "Obriši",
                            icon: Icon(Icons.delete_outline,
                                color: theme.colorScheme.error),
                            onPressed: () => _confirmDelete(e, theme),
                          )
                        else
                          IconButton(
                            tooltip: "Aktiviraj",
                            icon: const Icon(Icons.restore, color: Colors.green),
                            onPressed: () => _reactivate(e),
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

  Future<void> _reactivate(User e) async {
    try {
      // UserUpdateRequest's other fields are nullable and get written as-is — send the
      // patient's existing values back rather than an isActive-only diff that would null them out.
      await _userProvider.update(e.id!, {
        "firstName": e.firstName,
        "lastName": e.lastName,
        "email": e.email,
        "username": e.username,
        "phoneNumber": e.phoneNumber,
        "isActive": true,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Pacijent aktiviran")));
      initTable();
    } on Exception catch (ex) {
      if (mounted) alertBox(context, "Greška", ex.toString());
    }
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
            const Text("Brisanje pacijenta"),
          ],
        ),
        content: Text(
            "Da li ste sigurni da želite obrisati pacijenta ${e.firstName ?? 'ovog pacijenta'}? Ova radnja se ne može poništiti."),
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
                      content: Text("Pacijent uspješno obrisan")),
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
