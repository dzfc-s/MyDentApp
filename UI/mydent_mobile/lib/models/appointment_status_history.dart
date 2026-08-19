import 'package:json_annotation/json_annotation.dart';

part 'appointment_status_history.g.dart';

@JsonSerializable()
class AppointmentStatusHistory {
  final int? id;
  final int? appointmentId;

  // Raw ints matching AppointmentStatus (see enums.dart).
  final int? fromStatus;
  final int? toStatus;
  final int? changedByUserId;
  final String? changedByUserName;
  final String? reason;
  final DateTime? changedAt;

  AppointmentStatusHistory({
    this.id,
    this.appointmentId,
    this.fromStatus,
    this.toStatus,
    this.changedByUserId,
    this.changedByUserName,
    this.reason,
    this.changedAt,
  });

  factory AppointmentStatusHistory.fromJson(Map<String, dynamic> json) =>
      _$AppointmentStatusHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$AppointmentStatusHistoryToJson(this);
}
