import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_models/shared_models.dart';

import 'api_config.dart';

class AuthApi {
  AuthApi(this._config, {http.Client? client}) : _client = client ?? http.Client();

  final ApiConfig _config;
  final http.Client _client;

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('${_config.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Login failed with status ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthUser.fromJson(body['user'] as Map<String, dynamic>);
  }
}
