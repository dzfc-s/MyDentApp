import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_notification.dart';
import 'base_provider.dart';

class NotificationProvider extends BaseProvider<AppNotification> {
  NotificationProvider() : super("Notifications");

  int unreadCount = 0;

  /// Cheap count-only fetch (pageSize:1, IncludeTotalCount) — every mutating
  /// method below calls this so any widget watching this provider (bottom-nav
  /// badge) updates the moment something is read, without each screen having
  /// to remember to refresh it manually.
  Future<void> refreshUnreadCount() async {
    try {
      final result = await get(filter: {"isRead": false, "includeTotalCount": true, "pageSize": 1});
      unreadCount = result.totalCount ?? 0;
      notifyListeners();
    } catch (_) {
      // Leave the last known count on failure — a stale badge beats a crash.
    }
  }

  @override
  AppNotification fromJson(data) =>
      AppNotification.fromJson(data as Map<String, dynamic>);

  Future<AppNotification> markAsRead(int id) async {
    final uri = Uri.parse("$baseUrl$endpoint/$id/markAsRead");
    final response = await http.post(uri, headers: createHeaders());
    validateResponse(response);
    final result = fromJson(jsonDecode(response.body));
    await refreshUnreadCount();
    return result;
  }
}
