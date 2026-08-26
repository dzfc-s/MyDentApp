import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/payment.dart';
import '../models/payment_intent.dart';
import 'base_provider.dart';

class PaymentProvider extends BaseProvider<Payment> {
  PaymentProvider() : super("Payments");

  @override
  Payment fromJson(data) => Payment.fromJson(data as Map<String, dynamic>);

  Future<PaymentIntent> createIntent(int appointmentId) async {
    final uri = Uri.parse("$baseUrl$endpoint/create-intent");
    final response = await http.post(
      uri,
      headers: createHeaders(),
      body: jsonEncode({"appointmentId": appointmentId}),
    );
    validateResponse(response);
    return PaymentIntent.fromJson(jsonDecode(response.body));
  }

  Future<Payment> confirm(int id) async {
    final uri = Uri.parse("$baseUrl$endpoint/$id/confirm");
    final response = await http.post(uri, headers: createHeaders());
    validateResponse(response);
    return fromJson(jsonDecode(response.body));
  }

  Future<Payment> cancel(int id) async {
    final uri = Uri.parse("$baseUrl$endpoint/$id/cancel");
    final response = await http.post(uri, headers: createHeaders());
    validateResponse(response);
    return fromJson(jsonDecode(response.body));
  }

  // Admin-only server-side (see PaymentsController.Refund) — a non-Admin caller gets 403.
  Future<Payment> refund(int id) async {
    final uri = Uri.parse("$baseUrl$endpoint/$id/refund");
    final response = await http.post(uri, headers: createHeaders());
    validateResponse(response);
    return fromJson(jsonDecode(response.body));
  }
}
