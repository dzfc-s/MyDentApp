// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_status_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppointmentStatusHistory _$AppointmentStatusHistoryFromJson(
  Map<String, dynamic> json,
) => AppointmentStatusHistory(
  id: (json['id'] as num?)?.toInt(),
  appointmentId: (json['appointmentId'] as num?)?.toInt(),
  fromStatus: (json['fromStatus'] as num?)?.toInt(),
  toStatus: (json['toStatus'] as num?)?.toInt(),
  changedByUserId: (json['changedByUserId'] as num?)?.toInt(),
  changedByUserName: json['changedByUserName'] as String?,
  reason: json['reason'] as String?,
  changedAt: json['changedAt'] == null
      ? null
      : DateTime.parse(json['changedAt'] as String),
);

Map<String, dynamic> _$AppointmentStatusHistoryToJson(
  AppointmentStatusHistory instance,
) => <String, dynamic>{
  'id': instance.id,
  'appointmentId': instance.appointmentId,
  'fromStatus': instance.fromStatus,
  'toStatus': instance.toStatus,
  'changedByUserId': instance.changedByUserId,
  'changedByUserName': instance.changedByUserName,
  'reason': instance.reason,
  'changedAt': instance.changedAt?.toIso8601String(),
};
