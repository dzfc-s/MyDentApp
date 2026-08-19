import 'package:json_annotation/json_annotation.dart';

part 'payment.g.dart';

@JsonSerializable()
class Payment {
  final int? id;
  final int? appointmentId;
  final String? patientName;
  final String? doctorName;
  final double? amount;

  // Raw int matching PaymentStatus (see enums.dart).
  final int? status;
  final String? providerTransactionId;
  final DateTime? paidAt;
  final double? refundedAmount;
  final DateTime? refundedAt;
  final DateTime? createdAt;

  Payment({
    this.id,
    this.appointmentId,
    this.patientName,
    this.doctorName,
    this.amount,
    this.status,
    this.providerTransactionId,
    this.paidAt,
    this.refundedAmount,
    this.refundedAt,
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentToJson(this);
}
