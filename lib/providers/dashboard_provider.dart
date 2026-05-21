import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/dashboard_model.dart';
import '../data/mock_dashboard_data.dart';

final dashboardProvider = FutureProvider<DashboardData?>((ref) async {
  // For development: Use mock data
  // In production, uncomment the code below to call the actual API
  
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 500));
  return MockDashboardData.generateMockData();

  /* Production code - uncomment when Laravel backend is ready:
  final authService = AuthService();
  final result = await authService.getDashboardData();
  
  if (result['success'] == true && result['data'] != null) {
    try {
      return DashboardData.fromJson(result['data']);
    } catch (e) {
      print('Error parsing dashboard: $e');
      throw Exception('Failed to parse dashboard data: $e');
    }
  } else {
    throw Exception(result['message'] ?? 'Unknown error');
  }
  */
});
