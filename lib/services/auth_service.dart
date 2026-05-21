import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/mock_auth_data.dart';

class AuthService {
  static const String _baseUrl = 'http://your-laravel-api-url.com/api';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  final _secureStorage = const FlutterSecureStorage();

  /// Login with email and password
  /// Uses mock authentication for development (no Laravel backend needed)
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock authentication - validate against demo credentials
      if (MockAuthData.validateCredentials(email, password)) {
        final user = MockAuthData.getMockUser();
        final token = MockAuthData.mockToken;

        // Store token securely
        await _secureStorage.write(
          key: _tokenKey,
          value: token,
        );

        // Store user data
        await _secureStorage.write(
          key: _userKey,
          value: jsonEncode({
            'id': user.id,
            'name': user.name,
            'email': user.email,
            'role': user.role,
            'is_active': user.isActive,
          }),
        );

        return {
          'success': true,
          'message': 'Login successful! Welcome back, ${user.name}',
          'token': token,
          'user': {
            'id': user.id,
            'name': user.name,
            'email': user.email,
            'role': user.role,
            'is_active': user.isActive,
          },
        };
      } else {
        return {
          'success': false,
          'message': 'Invalid email or password. Try admin@piggytrunk / password123',
        };
      }
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
      // Clear stored data
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
