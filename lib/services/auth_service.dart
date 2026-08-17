import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _secureStorage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  /// Login with email or username and password using Supabase auth.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      String resolvedEmail = email.trim().toLowerCase();
      final cleanPassword = password.trim();

      // 1. Smart Username Resolver: If input doesn't contain '@', look up email from app_users
      if (!resolvedEmail.contains('@')) {
        try {
          final userRecord = await Supabase.instance.client
              .from('app_users')
              .select('email')
              .ilike('name', resolvedEmail)
              .maybeSingle();

          if (userRecord != null && userRecord['email'] != null) {
            resolvedEmail = userRecord['email'].toString().trim().toLowerCase();
          }
        } catch (_) {
          // If query fails, fall back to input as-is
        }
      }

      final authResponse = await Supabase.instance.client.auth.signInWithPassword(
        email: resolvedEmail,
        password: cleanPassword,
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

      // Handle Remember Me state persistence
      if (rememberMe) {
        await _secureStorage.write(key: 'remembered_email', value: email);
        await _secureStorage.write(key: 'remember_me', value: 'true');
      } else {
        await _secureStorage.delete(key: 'remembered_email');
        await _secureStorage.write(key: 'remember_me', value: 'false');
      }

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
      String errorMessage = 'An unexpected error occurred. Please try again.';
      if (e is AuthException) {
        final msg = e.message.toLowerCase();
        if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
          errorMessage = 'Invalid email/username or password. Please check your credentials.';
        } else if (msg.contains('email not confirmed')) {
          errorMessage = 'Email address has not been confirmed.';
        } else {
          errorMessage = e.message;
        }
      } else {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('invalid login credentials') || errStr.contains('invalid_credentials')) {
          errorMessage = 'Invalid email/username or password. Please check your credentials.';
        }
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  /// Register a new account with typed email/gmail and password with role & metadata
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanPassword = password.trim();
      final cleanName = name.trim();

      final res = await Supabase.instance.client.auth.signUp(
        email: cleanEmail,
        password: cleanPassword,
        data: {
          'name': cleanName,
          'full_name': cleanName,
          'role': role,
        },
      );

      final user = res.user;
      if (user != null) {
        return {
          'success': true,
          'message': 'Registration successful! Account is pending admin approval.',
          'user': user,
        };
      } else {
        return {
          'success': false,
          'message': 'Unable to complete registration. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e is AuthException ? e.message : e.toString(),
      };
    }
  }

  /// Update password for the currently authenticated account
  Future<bool> updatePassword(String newPassword) async {
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword.trim()),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get remembered email and remember me status
  Future<Map<String, dynamic>> getRememberedCredentials() async {
    try {
      final email = await _secureStorage.read(key: 'remembered_email');
      final rememberMeStr = await _secureStorage.read(key: 'remember_me');
      final rememberMe = rememberMeStr == 'true';
      return {
        'email': email ?? '',
        'rememberMe': rememberMe && (email != null && email.isNotEmpty),
      };
    } catch (e) {
      return {'email': '', 'rememberMe': false};
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
