import 'package:json_annotation/json_annotation.dart';

part 'available_slot.g.dart';

@JsonSerializable()
class AvailableSlot {
  final DateTime? startTime;
  final DateTime? endTime;

  AvailableSlot({this.startTime, this.endTime});

  factory AvailableSlot.fromJson(Map<String, dynamic> json) =>
      _$AvailableSlotFromJson(json);

  Map<String, dynamic> toJson() => _$AvailableSlotToJson(this);
}
