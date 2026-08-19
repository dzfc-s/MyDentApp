// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'available_slot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AvailableSlot _$AvailableSlotFromJson(Map<String, dynamic> json) =>
    AvailableSlot(
      startTime: json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
    );

Map<String, dynamic> _$AvailableSlotToJson(AvailableSlot instance) =>
    <String, dynamic>{
      'startTime': instance.startTime?.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
    };
