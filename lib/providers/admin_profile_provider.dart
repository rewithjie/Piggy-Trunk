import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Admin Profile State
class AdminProfile {
  final String adminName;
  final String email;
  final String role;
  final String? profilePictureUrl;

  AdminProfile({
    required this.adminName,
    required this.email,
    required this.role,
    this.profilePictureUrl,
  });

  AdminProfile copyWith({
    String? adminName,
    String? email,
    String? role,
    String? profilePictureUrl,
  }) {
    return AdminProfile(
      adminName: adminName ?? this.adminName,
      email: email ?? this.email,
      role: role ?? this.role,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }
}

/// Admin Profile Notifier
class AdminProfileNotifier extends StateNotifier<AdminProfile> {
  AdminProfileNotifier()
      : super(
          AdminProfile(
            adminName: 'Admin',
            email: '',
            role: 'System Administrator',
            profilePictureUrl: null,
          ),
        );

  void updateProfile({
    String? adminName,
    String? email,
    String? role,
    String? profilePictureUrl,
  }) {
    state = state.copyWith(
      adminName: adminName,
      email: email,
      role: role,
      profilePictureUrl: profilePictureUrl,
    );
  }

  void setEmail(String email) {
    state = state.copyWith(email: email);
  }

  void setProfilePictureUrl(String url) {
    state = state.copyWith(profilePictureUrl: url);
  }
}

/// Admin Profile Provider
final adminProfileProvider =
    StateNotifierProvider<AdminProfileNotifier, AdminProfile>((ref) {
  return AdminProfileNotifier();
});
