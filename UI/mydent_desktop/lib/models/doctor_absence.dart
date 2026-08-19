import 'package:json_annotation/json_annotation.dart';

part 'doctor_absence.g.dart';

@JsonSerializable()
class DoctorAbsence {
  final int? id;
  final int? doctorId;
  final String? doctorName;

  // DateOnly serializes as "yyyy-MM-dd" — kept as raw string, parsed where needed.
  final String? startDate;
  final String? endDate;
  final String? reason;
  final DateTime? createdAt;

  DoctorAbsence({
    this.id,
    this.doctorId,
    this.doctorName,
    this.startDate,
    this.endDate,
    this.reason,
    this.createdAt,
  });

  factory DoctorAbsence.fromJson(Map<String, dynamic> json) =>
      _$DoctorAbsenceFromJson(json);

  Map<String, dynamic> toJson() => _$DoctorAbsenceToJson(this);
}
