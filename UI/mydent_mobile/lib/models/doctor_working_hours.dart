import 'package:json_annotation/json_annotation.dart';

part 'doctor_working_hours.g.dart';

@JsonSerializable()
class DoctorWorkingHours {
  final int? id;
  final int? doctorId;
  final String? doctorName;

  // C# System.DayOfWeek: Sunday=0 .. Saturday=6 (differs from Dart's DateTime.weekday).
  final int? dayOfWeek;

  // TimeSpan serializes as "hh:mm:ss" — kept as raw string, parsed where needed.
  final String? startTime;
  final String? endTime;

  DoctorWorkingHours({
    this.id,
    this.doctorId,
    this.doctorName,
    this.dayOfWeek,
    this.startTime,
    this.endTime,
  });

  factory DoctorWorkingHours.fromJson(Map<String, dynamic> json) =>
      _$DoctorWorkingHoursFromJson(json);

  Map<String, dynamic> toJson() => _$DoctorWorkingHoursToJson(this);
}
