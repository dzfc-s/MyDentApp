import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

import '../utils/api_client_exception.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  static String? _accesstoken;
  static String? _refreshtoken;
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

  // Static (not a per-instance field) so tryRefreshAccessToken below — which has no
  // AuthProvider instance to call through, since BaseProvider only ever sees the static
  // token fields — can build the refresh request URL too.
  static const String _baseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "http://localhost:5126/",
  );

  AuthProvider();

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

  // Called by BaseProvider when an API call comes back 401 — tries to silently trade the
  // refresh token for a new access token instead of forcing the user to log back in every
  // time the (short-lived) access token expires mid-session. Static + no AuthProvider
  // instance involved, since BaseProvider only ever holds the static token fields, not a
  // reference to the AuthProvider widget in the provider tree.
  //
  // De-duplicated via _refreshInFlight: several requests can 401 around the same moment
  // (e.g. a screen firing off a few parallel fetches right as the token expires), and the
  // backend rotates the refresh token on every use — two concurrent refresh calls would
  // both present the same pre-rotation token, so the second one to arrive would be rejected
  // as already-used and log the user out even though the first one actually succeeded.
  static Future<bool>? _refreshInFlight;

  static Future<bool> tryRefreshAccessToken() {
    return _refreshInFlight ??= _performRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  static Future<bool> _performRefresh() async {
    final token = _refreshtoken;
    if (token == null) return false;

    try {
      var uri = Uri.parse("${_baseUrl}Access/LoginWithRefreshToken");
      var response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refreshToken": token}),
      );

      if (response.statusCode >= 300) {
        _clearSession();
        return false;
      }

      var data = jsonDecode(response.body);
      _accesstoken = data['accesstoken'];
      _refreshtoken = data['refreshtoken'];
      _accessTokenDecoded = JwtDecoder.decode(_accesstoken ?? "");
      return true;
    } catch (_) {
      // Network error during refresh — treat like a failed refresh rather than leaving
      // stale/half-updated tokens around.
      _clearSession();
      return false;
    }
  }

  static void _clearSession() {
    _accesstoken = null;
    _refreshtoken = null;
    _accessTokenDecoded = null;
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
    _clearSession();
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
