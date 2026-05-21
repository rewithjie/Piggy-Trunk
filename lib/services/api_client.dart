import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiClient extends http.BaseClient {
  final http.Client _inner;
  final AuthService _authService;

  ApiClient(this._authService) : _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Add authorization token if available
    final token = await _authService.getToken();
    
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add default headers
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });

    try {
      final response = await _inner.send(request).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timeout after 30 seconds');
        },
      );

      // Handle 401 - Token expired
      if (response.statusCode == 401) {
        final refreshed = await _authService.refreshToken();
        
        if (refreshed) {
          // Retry the original request with new token
          final newToken = await _authService.getToken();
          
          if (newToken != null) {
            request.headers['Authorization'] = 'Bearer $newToken';
            return _inner.send(request);
          }
        } else {
          // Token refresh failed - user needs to re-login
          await _authService.logout();
          throw UnauthorizedException('Session expired. Please login again.');
        }
      }

      return response;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}
