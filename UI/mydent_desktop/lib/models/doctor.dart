import 'package:json_annotation/json_annotation.dart';

part 'doctor.g.dart';

@JsonSerializable()
class Doctor {
  final int? id;
  final String? firstName;
  final String? lastName;
  final String? bio;
  final bool? isActive;
  final DateTime? createdAt;
  final int? photoAssetId;

  Doctor({
    this.id,
    this.firstName,
    this.lastName,
    this.bio,
    this.isActive,
    this.createdAt,
    this.photoAssetId,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) =>
      _$DoctorFromJson(json);

  Map<String, dynamic> toJson() => _$DoctorToJson(this);
}
