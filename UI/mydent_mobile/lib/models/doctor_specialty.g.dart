// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doctor_specialty.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DoctorSpecialty _$DoctorSpecialtyFromJson(Map<String, dynamic> json) =>
    DoctorSpecialty(
      id: (json['id'] as num?)?.toInt(),
      doctorId: (json['doctorId'] as num?)?.toInt(),
      doctorName: json['doctorName'] as String?,
      serviceCategoryId: (json['serviceCategoryId'] as num?)?.toInt(),
      serviceCategoryName: json['serviceCategoryName'] as String?,
    );

Map<String, dynamic> _$DoctorSpecialtyToJson(DoctorSpecialty instance) =>
    <String, dynamic>{
      'id': instance.id,
      'doctorId': instance.doctorId,
      'doctorName': instance.doctorName,
      'serviceCategoryId': instance.serviceCategoryId,
      'serviceCategoryName': instance.serviceCategoryName,
    };
