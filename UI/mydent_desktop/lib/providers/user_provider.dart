import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user.dart';
import 'base_provider.dart';

class UserProvider extends BaseProvider<User> {
  UserProvider() : super("Users");

  @override
  User fromJson(data) {
    return User.fromJson(data);
  }

  Future<void> changePassword(dynamic request) async {
    var uri = Uri.parse("$baseUrl$endpoint/ChangePassword");
    var response = await http.put(
      uri,
      headers: createHeaders(),
      body: jsonEncode(request),
    );
    validateResponse(response);
  }
}
