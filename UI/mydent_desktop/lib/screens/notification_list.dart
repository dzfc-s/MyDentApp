import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/app_notification.dart';
import '../models/search_result.dart';
import '../models/user.dart';
import '../providers/notification_provider.dart';
import '../providers/user_provider.dart';
import '../utils/utils_widgets.dart';

class NotificationList extends StatefulWidget {
  const NotificationList({super.key});

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  late NotificationProvider _provider;
  late UserProvider _userProvider;
  SearchResult<AppNotification>? result;
  SearchResult<User>? users;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _provider = context.read<NotificationProvider>();
    _userProvider = context.read<UserProvider>();
    initTable();
  }

  Future<void> initTable() async {
    try {
      var data = await _provider.get(filter: {});
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
      title: "Obavještenja",
      currentSection: AppSection.notifications,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _openCreateDialog,
                child: const Text("Novo obavještenje"),
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

  Widget _buildTable() {
    return Expanded(
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text("Korisnik")),
              DataColumn(label: Text("Naslov")),
              DataColumn(label: Text("Poruka")),
              DataColumn(label: Text("Pročitano")),
              DataColumn(label: Text("Akcije")),
            ],
            rows: result?.items
                    ?.map(
                      (e) => DataRow(cells: [
                        DataCell(Text(e.userName ?? '')),
                        DataCell(Text(e.title ?? '')),
                        DataCell(SizedBox(
                            width: 250,
                            child: Text(e.message ?? '',
                                overflow: TextOverflow.ellipsis))),
                        DataCell(Text(e.isRead == true ? "Da" : "Ne")),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (e.isRead != true)
                              IconButton(
                                tooltip: "Označi kao pročitano",
                                icon: const Icon(Icons.mark_email_read_outlined),
                                onPressed: () async {
                                  try {
                                    await _provider.markAsRead(e.id!);
                                    initTable();
                                  } on Exception catch (ex) {
                                    alertBox(context, "Greška", ex.toString());
                                  }
                                },
                              ),
                            IconButton(
                              tooltip: "Obriši",
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                try {
                                  await _provider.remove(e.id!);
                                  initTable();
                                } on Exception catch (ex) {
                                  alertBox(context, "Greška", ex.toString());
                                }
                              },
                            ),
                          ],
                        )),
                      ]),
                    )
                    .toList() ??
                List.empty(),
          ),
        ),
      ),
    );
  }

  Future _openCreateDialog() async {
    if (users == null) {
      try {
        users = await _userProvider.get(filter: {});
      } on Exception catch (e) {
        if (!mounted) return;
        alertBox(context, "Greška", e.toString());
        return;
      }
    }
    if (!mounted) return;

    int? userId;
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Novo obavještenje"),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: "Korisnik"),
                  items: users?.items
                          ?.map((u) => DropdownMenuItem(
                              value: u.id,
                              child: Text(
                                  "${u.firstName} ${u.lastName} (${u.username})")))
                          .toList() ??
                      [],
                  onChanged: (v) => setDialogState(() => userId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Naslov"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(labelText: "Poruka"),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Odustani"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (userId == null || titleController.text.isEmpty) return;
                try {
                  await _provider.insert({
                    "userId": userId,
                    "title": titleController.text,
                    "message": messageController.text,
                    "type": 0,
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                  initTable();
                } on Exception catch (e) {
                  alertBox(context, "Greška", e.toString());
                }
              },
              child: const Text("Pošalji"),
            ),
          ],
        ),
      ),
    );
  }
}
