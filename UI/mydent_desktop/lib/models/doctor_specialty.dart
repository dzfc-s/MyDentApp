import 'package:json_annotation/json_annotation.dart';

part 'doctor_specialty.g.dart';

@JsonSerializable()
class DoctorSpecialty {
  final int? id;
  final int? doctorId;
  final String? doctorName;
  final int? serviceCategoryId;
  final String? serviceCategoryName;

  DoctorSpecialty({
    this.id,
    this.doctorId,
    this.doctorName,
    this.serviceCategoryId,
    this.serviceCategoryName,
  });

  factory DoctorSpecialty.fromJson(Map<String, dynamic> json) =>
      _$DoctorSpecialtyFromJson(json);

  Map<String, dynamic> toJson() => _$DoctorSpecialtyToJson(this);
}
