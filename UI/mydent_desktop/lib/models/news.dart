import 'package:json_annotation/json_annotation.dart';

part 'news.g.dart';

@JsonSerializable()
class News {
  final int? id;
  final String? title;
  final String? content;
  final int? imageAssetId;
  final bool? isPublished;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final int? createdByUserId;
  final String? createdByUserName;

  News({
    this.id,
    this.title,
    this.content,
    this.imageAssetId,
    this.isPublished,
    this.publishedAt,
    this.createdAt,
    this.createdByUserId,
    this.createdByUserName,
  });

  factory News.fromJson(Map<String, dynamic> json) => _$NewsFromJson(json);

  Map<String, dynamic> toJson() => _$NewsToJson(this);
}
