// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doctor_working_hours.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DoctorWorkingHours _$DoctorWorkingHoursFromJson(Map<String, dynamic> json) =>
    DoctorWorkingHours(
      id: (json['id'] as num?)?.toInt(),
      doctorId: (json['doctorId'] as num?)?.toInt(),
      doctorName: json['doctorName'] as String?,
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt(),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
    );

Map<String, dynamic> _$DoctorWorkingHoursToJson(DoctorWorkingHours instance) =>
    <String, dynamic>{
      'id': instance.id,
      'doctorId': instance.doctorId,
      'doctorName': instance.doctorName,
      'dayOfWeek': instance.dayOfWeek,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
    };
