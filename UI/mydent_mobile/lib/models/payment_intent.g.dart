// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_intent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentIntent _$PaymentIntentFromJson(Map<String, dynamic> json) =>
    PaymentIntent(
      paymentId: (json['paymentId'] as num?)?.toInt(),
      clientSecret: json['clientSecret'] as String?,
      ephemeralKey: json['ephemeralKey'] as String?,
      customerId: json['customerId'] as String?,
    );

Map<String, dynamic> _$PaymentIntentToJson(PaymentIntent instance) =>
    <String, dynamic>{
      'paymentId': instance.paymentId,
      'clientSecret': instance.clientSecret,
      'ephemeralKey': instance.ephemeralKey,
      'customerId': instance.customerId,
    };
