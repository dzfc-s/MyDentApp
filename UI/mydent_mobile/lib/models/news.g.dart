// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

News _$NewsFromJson(Map<String, dynamic> json) => News(
  id: (json['id'] as num?)?.toInt(),
  title: json['title'] as String?,
  content: json['content'] as String?,
  imageAssetId: (json['imageAssetId'] as num?)?.toInt(),
  isPublished: json['isPublished'] as bool?,
  publishedAt: json['publishedAt'] == null
      ? null
      : DateTime.parse(json['publishedAt'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  createdByUserId: (json['createdByUserId'] as num?)?.toInt(),
  createdByUserName: json['createdByUserName'] as String?,
);

Map<String, dynamic> _$NewsToJson(News instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'content': instance.content,
  'imageAssetId': instance.imageAssetId,
  'isPublished': instance.isPublished,
  'publishedAt': instance.publishedAt?.toIso8601String(),
  'createdAt': instance.createdAt?.toIso8601String(),
  'createdByUserId': instance.createdByUserId,
  'createdByUserName': instance.createdByUserName,
};
