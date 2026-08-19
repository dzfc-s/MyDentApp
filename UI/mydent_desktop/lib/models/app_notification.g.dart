// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    AppNotification(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      userName: json['userName'] as String?,
      title: json['title'] as String?,
      message: json['message'] as String?,
      type: (json['type'] as num?)?.toInt(),
      isRead: json['isRead'] as bool?,
      appointmentId: (json['appointmentId'] as num?)?.toInt(),
      serviceCategoryId: (json['serviceCategoryId'] as num?)?.toInt(),
      serviceCategoryName: json['serviceCategoryName'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$AppNotificationToJson(AppNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'userName': instance.userName,
      'title': instance.title,
      'message': instance.message,
      'type': instance.type,
      'isRead': instance.isRead,
      'appointmentId': instance.appointmentId,
      'serviceCategoryId': instance.serviceCategoryId,
      'serviceCategoryName': instance.serviceCategoryName,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
