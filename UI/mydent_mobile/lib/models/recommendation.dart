import 'package:json_annotation/json_annotation.dart';

part 'recommendation.g.dart';

@JsonSerializable()
class Recommendation {
  final int? dentalServiceId;
  final String? dentalServiceName;
  final double? price;
  final int? durationMinutes;
  final int? serviceCategoryId;
  final String? serviceCategoryName;

  // Raw int matching RecommendationReason (see enums.dart).
  final int? reason;
  final String? reasonDetail;

  Recommendation({
    this.dentalServiceId,
    this.dentalServiceName,
    this.price,
    this.durationMinutes,
    this.serviceCategoryId,
    this.serviceCategoryName,
    this.reason,
    this.reasonDetail,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) =>
      _$RecommendationFromJson(json);

  Map<String, dynamic> toJson() => _$RecommendationToJson(this);
}
