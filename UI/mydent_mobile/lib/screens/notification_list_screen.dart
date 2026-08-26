import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_notification.dart';
import '../models/enums.dart';
import '../models/search_result.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import '../utils/utils_widgets.dart';

/// Ported from the Figma reference: notifications differentiated by
/// icon/color per type, plus a "Označi sve pročitano" bulk action. Previously
/// every notification used the same generic mail icon and there was no way
/// to mark everything read at once (only per-item, on tap).
class NotificationListScreen extends StatefulWidget {
  /// Bumped by `ContainerScreen` every time the Obavještenja tab is switched
  /// to — `IndexedStack` keeps this screen's State alive across tab
  /// switches, so without this, `_load()` only ever ran once in `initState`
  /// (same staleness `HomeScreen` had — see its `refreshTick` doc comment).
  final int refreshTick;

  const NotificationListScreen({super.key, this.refreshTick = 0});

  @override
  State<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  SearchResult<AppNotification>? result;
  bool isLoading = true;
  bool _markingAll = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant NotificationListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTick != oldWidget.refreshTick) _load();
  }

  Future<void> _load() async {
    try {
      final data = await context.read<NotificationProvider>().get(filter: {"pageSize": 200});
      if (!mounted) return;
      setState(() {
        result = data;
        isLoading = false;
      });
    } on Exception catch (e) {
      if (mounted) alertBox(context, 'Greška', e.toString());
    }
  }

  Future<void> _markAllRead(List<AppNotification> unread) async {
    setState(() => _markingAll = true);
    final provider = context.read<NotificationProvider>();
    // No bulk "mark all read" endpoint on the backend — fire the per-id
    // markAsRead calls concurrently instead of one at a time.
    await Future.wait(unread.map((n) async {
      try {
        await provider.markAsRead(n.id!);
      } catch (_) {
        // One failing item shouldn't block the rest — _load() below reflects
        // whatever actually got through.
      }
    }));
    if (!mounted) return;
    setState(() => _markingAll = false);
    _load();
  }

  // Figma never colors reminders amber/warning — both reminder_2h and
  // reminder_24h use the same violet accent as everything else, reserving
  // warning/danger colors for cancellation specifically.
  (IconData, Color) _visualFor(NotificationType type) => switch (type) {
        NotificationType.appointmentConfirmed => (Icons.event_available_outlined, AppColors.success),
        NotificationType.appointmentCancelled => (Icons.event_busy_outlined, AppColors.danger),
        NotificationType.appointmentReminder => (Icons.alarm_outlined, AppColors.primary),
        NotificationType.recurringServiceReminder => (Icons.repeat_outlined, AppColors.primary),
        NotificationType.paymentSucceeded => (Icons.payment_outlined, AppColors.success),
        NotificationType.paymentRefunded => (Icons.replay_outlined, AppColors.primary),
        NotificationType.general => (Icons.notifications_outlined, AppColors.primary),
      };

  @override
  Widget build(BuildContext context) {
    final items = result?.items ?? [];
    final unread = items.where((n) => n.isRead != true).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (unread.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${unread.length} nepročitano',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        TextButton(
                          onPressed: _markingAll ? null : () => _markAllRead(unread),
                          child: _markingAll
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Označi sve'),
                        ),
                      ],
                    ),
                  ),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 120),
                    child: Center(child: Text('Nemate obavještenja')),
                  )
                else
                  ...items.map((n) {
                    final (icon, color) = _visualFor(NotificationTypeX.fromInt(n.type));
                    final isRead = n.isRead == true;
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (isRead ? Colors.grey : color).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 20, color: isRead ? Colors.grey : color),
                      ),
                      title: Text(n.title ?? '',
                          style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                      subtitle: Text(n.message ?? ''),
                      onTap: () async {
                        if (n.isRead != true) {
                          try {
                            await context.read<NotificationProvider>().markAsRead(n.id!);
                            _load();
                          } catch (_) {
                            // Non-critical — leave it unread rather than blocking the tap.
                          }
                        }
                      },
                    );
                  }),
              ],
            ),
    );
  }
}
