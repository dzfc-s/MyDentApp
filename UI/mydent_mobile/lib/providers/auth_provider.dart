import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

import '../utils/api_client_exception.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  static String? _accesstoken;
  String? _refreshtoken;
  static Map<String, dynamic>? _accessTokenDecoded;

  static String? get accesstoken => _accesstoken;
  String? get refreshtoken => _refreshtoken;
  static Map<String, dynamic>? get accessTokenDecoded => _accessTokenDecoded;

  // Claim names match MyDent.WebAPI ClaimNames — plain string keys, not ClaimTypes URIs.
  static String? get role => _accessTokenDecoded?['Role'] as String?;
  static int? get userId {
    final id = _accessTokenDecoded?['Id'];
    return id == null ? null : int.tryParse(id.toString());
  }

  final String _baseUrl;

  AuthProvider()
      : _baseUrl = const String.fromEnvironment(
          "API_BASE_URL",
          defaultValue: "http://10.0.2.2:5126/",
        );

  bool get isAuthenticated => _isAuthenticated;

  Future login(String username, String password) async {
    var uri = Uri.parse("${_baseUrl}Access/Login");
    var headers = createHeaders();
    var body = jsonEncode({"username": username, "password": password});

    http.Response response =
        await http.post(uri, headers: headers, body: body);

    validateResponse(response);
    var data = jsonDecode(response.body);
    _accesstoken = data['accesstoken'];
    _refreshtoken = data['refreshtoken'];
    _accessTokenDecoded = JwtDecoder.decode(_accesstoken ?? "");
    _isAuthenticated = true;
    notifyListeners();
  }

  Future register(Map<String, dynamic> data) async {
    var uri = Uri.parse("${_baseUrl}Access/Register");
    var headers = createHeaders();
    var body = jsonEncode(data);

    http.Response response =
        await http.post(uri, headers: headers, body: body);

    validateResponse(response);
  }

  Future logoutRemote() async {
    if (_accesstoken == null) return;
    var uri = Uri.parse("${_baseUrl}Access/Logout");
    try {
      await http.post(uri, headers: createHeaders());
    } catch (_) {
      // Best-effort: still clear local session below even if the server call fails.
    }
  }

  void logout() {
    _isAuthenticated = false;
    _accesstoken = null;
    _refreshtoken = null;
    _accessTokenDecoded = null;
    notifyListeners();
  }

  /// Throws [ApiClientException] with a message from the API when status is not successful.
  void validateResponse(http.Response response) {
    if (response.statusCode < 299) {
      return;
    }
    if (response.statusCode == 401) {
      throw ApiClientException('Neispravno korisničko ime ili lozinka.');
    }

    final parsed = ApiErrorParser.messageFromBody(response.body);
    if (response.statusCode >= 500) {
      throw ApiClientException(
        parsed ?? 'Greška na serveru. Pokušajte ponovo kasnije.',
      );
    }

    throw ApiClientException(
      parsed ?? 'Zahtjev nije uspio. Pokušajte ponovo.',
    );
  }

  Map<String, String> createHeaders() {
    return {"Content-Type": "application/json"};
  }
}
