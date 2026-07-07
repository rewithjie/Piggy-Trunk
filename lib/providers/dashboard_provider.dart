import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_model.dart';
import '../services/auth_service.dart';

final dashboardProvider = FutureProvider<DashboardData?>((ref) async {
  final authService = AuthService();
  final result = await authService.getDashboardData();

  if (result['success'] == true && result['data'] != null) {
    try {
      return DashboardData.fromJson(result['data']);
    } catch (e) {
      throw Exception('Failed to parse dashboard data: $e');
    }
  } else {
    throw Exception(result['message'] ?? 'Unknown error');
  }
});
