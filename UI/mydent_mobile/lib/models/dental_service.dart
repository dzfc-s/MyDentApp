import 'package:json_annotation/json_annotation.dart';

part 'dental_service.g.dart';

@JsonSerializable()
class DentalService {
  final int? id;
  final String? name;
  final String? description;
  final double? price;
  final int? durationMinutes;
  final bool? isActive;
  final DateTime? createdAt;
  final int? serviceCategoryId;
  final String? serviceCategoryName;
  final int? imageAssetId;

  DentalService({
    this.id,
    this.name,
    this.description,
    this.price,
    this.durationMinutes,
    this.isActive,
    this.createdAt,
    this.serviceCategoryId,
    this.serviceCategoryName,
    this.imageAssetId,
  });

  factory DentalService.fromJson(Map<String, dynamic> json) =>
      _$DentalServiceFromJson(json);

  Map<String, dynamic> toJson() => _$DentalServiceToJson(this);
}
