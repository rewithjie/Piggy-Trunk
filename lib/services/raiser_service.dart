import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class RaiserService {
  final SupabaseClient _supabase;
  final http.Client _httpClient;

  RaiserService({SupabaseClient? supabase, http.Client? httpClient})
      : _supabase = supabase ?? Supabase.instance.client,
        _httpClient = httpClient ?? http.Client();

  Future<Map<String, dynamic>> createRaiser({
    required String name,
    String? email,
    required String phone,
    required String address,
    required String lifecycleStage,
    required String status,
  }) async {
    final supabaseUrl =
        dotenv.env['SUPABASE_URL']?.trim() ?? 'https://ywwwrshblzyqmxkbkxsp.supabase.co';

    final session = _supabase.auth.currentSession;
    String? accessToken = session?.accessToken;

    // Fallback: if Supabase client session is not available (app restart),
    // try reading stored token from AuthService secure storage.
    if (accessToken == null || accessToken.isEmpty) {
      try {
        final stored = await AuthService().getToken();
        if (stored != null && stored.isNotEmpty) {
          accessToken = stored;
        }
      } catch (_) {}
    }

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Admin session is not available. Please sign in again.');
    }

    final uri = Uri.parse('$supabaseUrl/functions/v1/create-raiser');
    // Debug: show masked token presence for diagnosis
    try {
      debugPrint('RaiserService: using access token ${accessToken.substring(0, 8)}...');
    } catch (_) {}

    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        'phone': phone,
        'address': address,
        'lifecycle_stage': lifecycleStage,
        'status': status,
      }),
    );

    // Debug: print response body for diagnosis on failure
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final responseBody = response.body.isNotEmpty ? response.body : 'empty response';
      debugPrint('RaiserService: create-raiser failed ${response.statusCode}: $responseBody');
      throw Exception('Unable to create raiser. ${response.statusCode}: $responseBody');
    } else {
      try {
        debugPrint('RaiserService: create-raiser success body: ${response.body}');
      } catch (_) {}
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Create raiser function failed.');
    }

    return body;
  }
}
