import 'package:json_annotation/json_annotation.dart';

part 'service_category.g.dart';

@JsonSerializable()
class ServiceCategory {
  final int? id;
  final String? name;
  final String? description;
  final bool? isActive;
  final int? recommendedRecallMonths;

  ServiceCategory({
    this.id,
    this.name,
    this.description,
    this.isActive,
    this.recommendedRecallMonths,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) =>
      _$ServiceCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceCategoryToJson(this);
}
