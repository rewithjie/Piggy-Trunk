import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _secureStorage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  /// Login with email and password using Supabase auth.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      final authResponse = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final session = authResponse.session;
      final user = authResponse.user;

      if (session == null || user == null) {
        return {
          'success': false,
          'message': 'Unable to sign in to Supabase. Please verify your credentials.',
        };
      }

      await _secureStorage.write(key: _tokenKey, value: session.accessToken);
      await _secureStorage.write(
        key: _userKey,
        value: jsonEncode({
          'id': user.id,
          'email': user.email,
          'role': 'admin',
        }),
      );

      return {
        'success': true,
        'message': 'Login successful! Welcome back, ${user.email}',
        'token': session.accessToken,
        'user': {
          'id': user.id,
          'email': user.email,
          'role': 'admin',
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Get stored authentication token
  Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout and clear stored data
  Future<void> logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _userKey);
    } catch (e) {
      // Silently fail
    }
  }

  /// Get stored user data
  Future<Map<String, dynamic>?> getUser() async {
    try {
      final userData = await _secureStorage.read(key: _userKey);
      if (userData != null) {
        return jsonDecode(userData) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check auth and return basic session info.
  /// The dashboard screen fetches its own live data directly from Supabase.
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'No authenticated session found. Please sign in again.',
        };
      }

      final user = Supabase.instance.client.auth.currentUser;
      return {
        'success': true,
        'data': {
          'user': {
            'id': user?.id ?? '',
            'email': user?.email ?? '',
            'role': 'admin',
          },
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// Refresh authentication token
  Future<bool> refreshToken() async {
    try {
      final token = await getToken();
      return token != null;
    } catch (e) {
      return false;
    }
  }
}
