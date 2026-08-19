import 'package:json_annotation/json_annotation.dart';

part 'app_notification.g.dart';

// Named AppNotification (not Notification) to avoid colliding with Flutter's own
// widgets.dart Notification class (used by NotificationListener/ScrollNotification etc.).
@JsonSerializable()
class AppNotification {
  final int? id;
  final int? userId;
  final String? userName;
  final String? title;
  final String? message;

  // Raw int matching NotificationType (see enums.dart).
  final int? type;
  final bool? isRead;
  final int? appointmentId;
  final int? serviceCategoryId;
  final String? serviceCategoryName;
  final DateTime? createdAt;

  AppNotification({
    this.id,
    this.userId,
    this.userName,
    this.title,
    this.message,
    this.type,
    this.isRead,
    this.appointmentId,
    this.serviceCategoryId,
    this.serviceCategoryName,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);

  Map<String, dynamic> toJson() => _$AppNotificationToJson(this);
}
