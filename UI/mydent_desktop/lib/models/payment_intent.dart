import 'package:json_annotation/json_annotation.dart';

part 'payment_intent.g.dart';

// Everything flutter_stripe's PaymentSheet needs client-side — returned once at creation,
// never persisted, so this model is used directly from the response, not through BaseProvider.
@JsonSerializable()
class PaymentIntent {
  final int? paymentId;
  final String? clientSecret;
  final String? ephemeralKey;
  final String? customerId;

  PaymentIntent({
    this.paymentId,
    this.clientSecret,
    this.ephemeralKey,
    this.customerId,
  });

  factory PaymentIntent.fromJson(Map<String, dynamic> json) =>
      _$PaymentIntentFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentIntentToJson(this);
}
