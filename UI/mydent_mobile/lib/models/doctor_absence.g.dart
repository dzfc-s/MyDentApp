// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doctor_absence.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DoctorAbsence _$DoctorAbsenceFromJson(Map<String, dynamic> json) =>
    DoctorAbsence(
      id: (json['id'] as num?)?.toInt(),
      doctorId: (json['doctorId'] as num?)?.toInt(),
      doctorName: json['doctorName'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      reason: json['reason'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$DoctorAbsenceToJson(DoctorAbsence instance) =>
    <String, dynamic>{
      'id': instance.id,
      'doctorId': instance.doctorId,
      'doctorName': instance.doctorName,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'reason': instance.reason,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
