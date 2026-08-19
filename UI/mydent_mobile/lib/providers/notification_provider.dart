import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_notification.dart';
import 'base_provider.dart';

class NotificationProvider extends BaseProvider<AppNotification> {
  NotificationProvider() : super("Notifications");

  @override
  AppNotification fromJson(data) =>
      AppNotification.fromJson(data as Map<String, dynamic>);

  Future<AppNotification> markAsRead(int id) async {
    final uri = Uri.parse("$baseUrl$endpoint/$id/markAsRead");
    final response = await http.post(uri, headers: createHeaders());
    validateResponse(response);
    return fromJson(jsonDecode(response.body));
  }
}
