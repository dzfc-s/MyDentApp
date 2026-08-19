// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Payment _$PaymentFromJson(Map<String, dynamic> json) => Payment(
  id: (json['id'] as num?)?.toInt(),
  appointmentId: (json['appointmentId'] as num?)?.toInt(),
  patientName: json['patientName'] as String?,
  doctorName: json['doctorName'] as String?,
  amount: (json['amount'] as num?)?.toDouble(),
  status: (json['status'] as num?)?.toInt(),
  providerTransactionId: json['providerTransactionId'] as String?,
  paidAt: json['paidAt'] == null
      ? null
      : DateTime.parse(json['paidAt'] as String),
  refundedAmount: (json['refundedAmount'] as num?)?.toDouble(),
  refundedAt: json['refundedAt'] == null
      ? null
      : DateTime.parse(json['refundedAt'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$PaymentToJson(Payment instance) => <String, dynamic>{
  'id': instance.id,
  'appointmentId': instance.appointmentId,
  'patientName': instance.patientName,
  'doctorName': instance.doctorName,
  'amount': instance.amount,
  'status': instance.status,
  'providerTransactionId': instance.providerTransactionId,
  'paidAt': instance.paidAt?.toIso8601String(),
  'refundedAmount': instance.refundedAmount,
  'refundedAt': instance.refundedAt?.toIso8601String(),
  'createdAt': instance.createdAt?.toIso8601String(),
};
