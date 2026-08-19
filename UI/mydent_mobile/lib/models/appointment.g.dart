// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Appointment _$AppointmentFromJson(Map<String, dynamic> json) => Appointment(
  id: (json['id'] as num?)?.toInt(),
  patientId: (json['patientId'] as num?)?.toInt(),
  patientName: json['patientName'] as String?,
  doctorId: (json['doctorId'] as num?)?.toInt(),
  doctorName: json['doctorName'] as String?,
  dentalServiceId: (json['dentalServiceId'] as num?)?.toInt(),
  dentalServiceName: json['dentalServiceName'] as String?,
  scheduledAt: json['scheduledAt'] == null
      ? null
      : DateTime.parse(json['scheduledAt'] as String),
  durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
  price: (json['price'] as num?)?.toDouble(),
  status: (json['status'] as num?)?.toInt(),
  cancellationReason: json['cancellationReason'] as String?,
  cancelledByUserId: (json['cancelledByUserId'] as num?)?.toInt(),
  cancelledAt: json['cancelledAt'] == null
      ? null
      : DateTime.parse(json['cancelledAt'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$AppointmentToJson(Appointment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patientId': instance.patientId,
      'patientName': instance.patientName,
      'doctorId': instance.doctorId,
      'doctorName': instance.doctorName,
      'dentalServiceId': instance.dentalServiceId,
      'dentalServiceName': instance.dentalServiceName,
      'scheduledAt': instance.scheduledAt?.toIso8601String(),
      'durationMinutes': instance.durationMinutes,
      'price': instance.price,
      'status': instance.status,
      'cancellationReason': instance.cancellationReason,
      'cancelledByUserId': instance.cancelledByUserId,
      'cancelledAt': instance.cancelledAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };
