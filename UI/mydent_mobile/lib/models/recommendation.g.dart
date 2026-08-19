// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Recommendation _$RecommendationFromJson(Map<String, dynamic> json) =>
    Recommendation(
      dentalServiceId: (json['dentalServiceId'] as num?)?.toInt(),
      dentalServiceName: json['dentalServiceName'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      serviceCategoryId: (json['serviceCategoryId'] as num?)?.toInt(),
      serviceCategoryName: json['serviceCategoryName'] as String?,
      reason: (json['reason'] as num?)?.toInt(),
      reasonDetail: json['reasonDetail'] as String?,
    );

Map<String, dynamic> _$RecommendationToJson(Recommendation instance) =>
    <String, dynamic>{
      'dentalServiceId': instance.dentalServiceId,
      'dentalServiceName': instance.dentalServiceName,
      'price': instance.price,
      'durationMinutes': instance.durationMinutes,
      'serviceCategoryId': instance.serviceCategoryId,
      'serviceCategoryName': instance.serviceCategoryName,
      'reason': instance.reason,
      'reasonDetail': instance.reasonDetail,
    };
