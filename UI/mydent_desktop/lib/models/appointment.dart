import 'package:json_annotation/json_annotation.dart';

part 'appointment.g.dart';

@JsonSerializable()
class Appointment {
  final int? id;
  final int? patientId;
  final String? patientName;
  final int? doctorId;
  final String? doctorName;
  final int? dentalServiceId;
  final String? dentalServiceName;
  final DateTime? scheduledAt;
  final int? durationMinutes;
  final double? price;

  // Raw int matching AppointmentStatus (see enums.dart) — no JsonStringEnumConverter on the API.
  final int? status;
  final String? cancellationReason;
  final int? cancelledByUserId;
  final DateTime? cancelledAt;
  final DateTime? createdAt;

  Appointment({
    this.id,
    this.patientId,
    this.patientName,
    this.doctorId,
    this.doctorName,
    this.dentalServiceId,
    this.dentalServiceName,
    this.scheduledAt,
    this.durationMinutes,
    this.price,
    this.status,
    this.cancellationReason,
    this.cancelledByUserId,
    this.cancelledAt,
    this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) =>
      _$AppointmentFromJson(json);

  Map<String, dynamic> toJson() => _$AppointmentToJson(this);
}
