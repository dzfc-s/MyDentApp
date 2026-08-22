import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/appointment.dart';
import '../models/appointment_status_history.dart';
import '../models/available_slot.dart';
import 'base_provider.dart';

class AppointmentProvider extends BaseProvider<Appointment> {
  AppointmentProvider() : super("Appointments");

  @override
  Appointment fromJson(data) =>
      Appointment.fromJson(data as Map<String, dynamic>);

  Future<List<AvailableSlot>> getAvailableSlots({
    required int doctorId,
    required int dentalServiceId,
    required DateTime date,
  }) async {
    final dateOnly =
        "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    // Default prefix ('&') matches BaseProvider.get()'s own convention: the leading '&' right
    // after '?' parses as one harmless empty key/value pair that servers ignore.
    final query = getQueryString({
      "doctorId": doctorId,
      "dentalServiceId": dentalServiceId,
      "date": dateOnly,
    });

    final uri = Uri.parse("$baseUrl$endpoint/available-slots?$query");
    final response = await http.get(uri, headers: createHeaders());
    validateResponse(response);

    final data = jsonDecode(response.body) as List;
    return data
        .map((e) => AvailableSlot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Appointment> confirm(int id) async {
    final uri = Uri.parse("$baseUrl$endpoint/$id/confirm");
    final response = await http.post(uri, headers: createHeaders());
    validateResponse(response);
    return fromJson(jsonDecode(response.body));
  }

  Future<Appointment> cancel(int id, String cancellationReason) async {
    final uri = Uri.parse("$baseUrl$endpoint/$id/cancel");
    final response = await http.post(
      uri,
      headers: createHeaders(),
      body: jsonEncode({"cancellationReason": cancellationReason}),
    );
    validateResponse(response);
    return fromJson(jsonDecode(response.body));
  }

  Future<Appointment> reschedule(
    int id, {
    required int doctorId,
    required int dentalServiceId,
    required DateTime scheduledAt,
  }) async {
    final uri = Uri.parse("$baseUrl$endpoint/$id/reschedule");
    final response = await http.post(
      uri,
      headers: createHeaders(),
      body: jsonEncode({
        "doctorId": doctorId,
        "dentalServiceId": dentalServiceId,
        "scheduledAt": scheduledAt.toIso8601String(),
      }),
    );
    validateResponse(response);
    return fromJson(jsonDecode(response.body));
  }

  Future<Appointment> complete(int id) async {
    final uri = Uri.parse("$baseUrl$endpoint/$id/complete");
    final response = await http.post(uri, headers: createHeaders());
    validateResponse(response);
    return fromJson(jsonDecode(response.body));
  }

  Future<List<AppointmentStatusHistory>> history(int id) async {
    final uri = Uri.parse("$baseUrl$endpoint/$id/history");
    final response = await http.get(uri, headers: createHeaders());
    validateResponse(response);

    final data = jsonDecode(response.body) as List;
    return data
        .map((e) =>
            AppointmentStatusHistory.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
