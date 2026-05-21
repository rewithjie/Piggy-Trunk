import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

// Auth service provider
final authServiceProvider = Provider((ref) => AuthService());

// Authentication state
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? errorMessage;
  final String? successMessage;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
    this.successMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    String? errorMessage,
    String? successMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState());

  Future<void> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    state = state.copyWith(isLoading: true);
    
    final result = await _authService.login(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );

    if (result['success']) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: result['user'],
        successMessage: result['message'],
        errorMessage: null,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: result['message'],
        successMessage: null,
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    
    await _authService.logout();
    
    state = AuthState();
  }

  Future<void> checkAuthStatus() async {
    final isAuthenticated = await _authService.isAuthenticated();
    
    if (isAuthenticated) {
      final user = await _authService.getUser();
      state = state.copyWith(
        isAuthenticated: true,
        user: user != null ? User.fromJson(user) : null,
      );
    } else {
      state = state.copyWith(isAuthenticated: false);
    }
  }

  void clearMessages() {
    state = state.copyWith(
      errorMessage: null,
      successMessage: null,
    );
  }
}

// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

// Selected user provider (for easy access)
final currentUserProvider = Provider((ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});

// Auth status provider
final isAuthenticatedProvider = Provider((ref) {
  final authState = ref.watch(authProvider);
  return authState.isAuthenticated;
});
