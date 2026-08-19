import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/recommendation.dart';
import '../utils/api_client_exception.dart';
import 'auth_provider.dart';

// Not a CRUD resource — RecommendationsController.Get returns a plain List<RecommendationResponse>,
// not the {items, totalCount} shape BaseProvider.get() expects — so this doesn't extend BaseProvider.
class RecommendationProvider extends ChangeNotifier {
  final String _baseUrl = const String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "http://localhost:5126/",
  );

  // patientId only matters when the caller is Admin (RecommendationsController lets Admin pass
  // it to view any patient's recommendations); everyone else always gets their own regardless.
  Future<List<Recommendation>> getRecommendations({int? patientId}) async {
    var url = "${_baseUrl}Recommendations";
    if (patientId != null) {
      url = "$url?patientId=$patientId";
    }

    final response = await http.get(Uri.parse(url), headers: _createHeaders());
    _validateResponse(response);

    final data = jsonDecode(response.body) as List;
    return data
        .map((e) => Recommendation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Map<String, String> _createHeaders() {
    final token = AuthProvider.accesstoken ?? "";
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  void _validateResponse(http.Response response) {
    if (response.statusCode < 299) return;
    if (response.statusCode == 401) {
      throw ApiClientException(
        'Your session has expired. Please sign in again.',
      );
    }
    final parsed = ApiErrorParser.messageFromBody(response.body);
    throw ApiClientException(
      parsed ?? 'Request could not be completed. Please try again.',
    );
  }
}
