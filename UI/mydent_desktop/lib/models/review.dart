import 'package:json_annotation/json_annotation.dart';

part 'review.g.dart';

@JsonSerializable()
class Review {
  final int? id;
  final int? appointmentId;
  final String? doctorName;
  final String? dentalServiceName;
  final String? patientName;
  final int? rating;
  final String? comment;
  final bool? isApproved;
  final DateTime? createdAt;

  Review({
    this.id,
    this.appointmentId,
    this.doctorName,
    this.dentalServiceName,
    this.patientName,
    this.rating,
    this.comment,
    this.isApproved,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) =>
      _$ReviewFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewToJson(this);
}
