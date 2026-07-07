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

  /// Load dashboard payload.
  ///
  /// Currently returns a local mock payload until a real admin dashboard
  /// endpoint is implemented on the backend.
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'No authenticated session found. Please sign in again.',
        };
      }

      return {
        'success': true,
        'data': {
          'raisers': [
            {
              'id': 1,
              'name': 'Raiser Alpha',
              'code': 'RA-001',
              'location': 'Farm A - Building 1',
              'status': 'Active',
              'pig_type': {'id': 1, 'name': 'Fattening'},
            },
            {
              'id': 2,
              'name': 'Raiser Beta',
              'code': 'RA-002',
              'location': 'Farm A - Building 2',
              'status': 'Active',
              'pig_type': {'id': 1, 'name': 'Fattening'},
            },
            {
              'id': 3,
              'name': 'Raiser Gamma',
              'code': 'RA-003',
              'location': 'Farm B - Building 1',
              'status': 'Active',
              'pig_type': {'id': 2, 'name': 'Sow'},
            },
          ],
          'raiserLifecycles': {
            '1': {
              'name': 'Raiser Alpha',
              'status': 'Active',
              'categories': [
                {'label': 'Booster', 'duration': 'Initial boost', 'status': 'completed'},
                {'label': 'Pre-Starter', 'duration': '1 month & 2 weeks', 'status': 'completed'},
                {'label': 'Starter', 'duration': '2 months & 2 weeks', 'status': 'completed'},
                {'label': 'Grower', 'duration': '2 months & 2 weeks', 'status': 'in-progress'},
                {'label': 'Finisher', 'duration': 'Final growth stage', 'status': 'pending'},
                {'label': 'Selling', 'duration': 'Final Stage', 'status': 'pending'},
              ],
            },
            '2': {
              'name': 'Raiser Beta',
              'status': 'Active',
              'categories': [
                {'label': 'Booster', 'duration': 'Initial boost', 'status': 'completed'},
                {'label': 'Pre-Starter', 'duration': '1 month & 2 weeks', 'status': 'completed'},
                {'label': 'Starter', 'duration': '2 months & 2 weeks', 'status': 'completed'},
                {'label': 'Grower', 'duration': '2 months & 2 weeks', 'status': 'in-progress'},
                {'label': 'Finisher', 'duration': 'Final growth stage', 'status': 'pending'},
                {'label': 'Selling', 'duration': 'Final Stage', 'status': 'pending'},
              ],
            },
            '3': {
              'name': 'Raiser Gamma',
              'status': 'Active',
              'categories': [
                {'label': 'Booster', 'duration': 'Initial boost', 'status': 'completed'},
                {'label': 'Pre-Starter', 'duration': '1 month & 2 weeks', 'status': 'completed'},
                {'label': 'Starter', 'duration': '2 months & 2 weeks', 'status': 'completed'},
                {'label': 'Grower', 'duration': '4 months - 8 months', 'status': 'in-progress'},
                {'label': 'Gilt Developer', 'duration': 'Development stage', 'status': 'pending'},
                {'label': 'Gestation Feed', 'duration': 'Pregnancy period', 'status': 'pending'},
                {'label': 'Lactation Feed', 'duration': 'Nursing stage', 'status': 'pending'},
                {'label': 'Separation', 'duration': 'Final Stage', 'status': 'pending'},
              ],
            },
          },
          'investmentSummary': {
            'totalActive': 5,
            'batchCount': 3,
            'allocation': {
              'fattening': 2500000.0,
              'sow': 1500000.0,
            },
            'totalCapital': 4000000.0,
            'expectedProfit': 850000.0,
          },
          'user': {
            'name': 'Admin User',
            'role': 'System Administrator',
            'initials': 'AU',
          },
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error while loading dashboard data: ${e.toString()}',
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
