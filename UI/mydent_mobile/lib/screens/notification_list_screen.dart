import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_notification.dart';
import '../models/search_result.dart';
import '../providers/notification_provider.dart';
import '../utils/utils_widgets.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  SearchResult<AppNotification>? result;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await context.read<NotificationProvider>().get(filter: {});
      if (!mounted) return;
      setState(() {
        result = data;
        isLoading = false;
      });
    } on Exception catch (e) {
      if (mounted) alertBox(context, 'Greška', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = result?.items ?? [];
    return RefreshIndicator(
      onRefresh: _load,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Center(child: Text('Nemate obavještenja')),
                  ],
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final n = items[index];
                    return ListTile(
                      leading: Icon(
                        n.isRead == true
                            ? Icons.mark_email_read_outlined
                            : Icons.mark_email_unread,
                        color: n.isRead == true ? Colors.grey : Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(n.title ?? '',
                          style: TextStyle(
                              fontWeight: n.isRead == true
                                  ? FontWeight.normal
                                  : FontWeight.bold)),
                      subtitle: Text(n.message ?? ''),
                      onTap: () async {
                        if (n.isRead != true) {
                          try {
                            await context
                                .read<NotificationProvider>()
                                .markAsRead(n.id!);
                            _load();
                          } catch (_) {
                            // Non-critical — leave it unread rather than blocking the tap.
                          }
                        }
                      },
                    );
                  },
                ),
    );
  }
}
