// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dental_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DentalService _$DentalServiceFromJson(Map<String, dynamic> json) =>
    DentalService(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      isActive: json['isActive'] as bool?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      serviceCategoryId: (json['serviceCategoryId'] as num?)?.toInt(),
      serviceCategoryName: json['serviceCategoryName'] as String?,
      imageAssetId: (json['imageAssetId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DentalServiceToJson(DentalService instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'durationMinutes': instance.durationMinutes,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt?.toIso8601String(),
      'serviceCategoryId': instance.serviceCategoryId,
      'serviceCategoryName': instance.serviceCategoryName,
      'imageAssetId': instance.imageAssetId,
    };
