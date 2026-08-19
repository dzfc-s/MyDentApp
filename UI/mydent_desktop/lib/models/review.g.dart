// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Review _$ReviewFromJson(Map<String, dynamic> json) => Review(
  id: (json['id'] as num?)?.toInt(),
  appointmentId: (json['appointmentId'] as num?)?.toInt(),
  doctorName: json['doctorName'] as String?,
  dentalServiceName: json['dentalServiceName'] as String?,
  patientName: json['patientName'] as String?,
  rating: (json['rating'] as num?)?.toInt(),
  comment: json['comment'] as String?,
  isApproved: json['isApproved'] as bool?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ReviewToJson(Review instance) => <String, dynamic>{
  'id': instance.id,
  'appointmentId': instance.appointmentId,
  'doctorName': instance.doctorName,
  'dentalServiceName': instance.dentalServiceName,
  'patientName': instance.patientName,
  'rating': instance.rating,
  'comment': instance.comment,
  'isApproved': instance.isApproved,
  'createdAt': instance.createdAt?.toIso8601String(),
};
