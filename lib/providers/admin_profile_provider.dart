import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Admin Profile State
class AdminProfile {
  final String adminName;
  final String email;
  final String role;
  final String? profilePictureUrl;
  final bool isHydrated;

  AdminProfile({
    required this.adminName,
    required this.email,
    required this.role,
    this.profilePictureUrl,
    this.isHydrated = false,
  });

  AdminProfile copyWith({
    String? adminName,
    String? email,
    String? role,
    String? profilePictureUrl,
    bool clearProfilePicture = false,
    bool? isHydrated,
  }) {
    return AdminProfile(
      adminName: adminName ?? this.adminName,
      email: email ?? this.email,
      role: role ?? this.role,
      profilePictureUrl: clearProfilePicture ? null : (profilePictureUrl ?? this.profilePictureUrl),
      isHydrated: isHydrated ?? this.isHydrated,
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
            isHydrated: false,
          ),
        );

  void updateProfile({
    String? adminName,
    String? email,
    String? role,
    String? profilePictureUrl,
    bool clearProfilePicture = false,
    bool? isHydrated,
  }) {
    state = state.copyWith(
      adminName: adminName,
      email: email,
      role: role,
      profilePictureUrl: profilePictureUrl,
      clearProfilePicture: clearProfilePicture,
      isHydrated: isHydrated ?? true,
    );
  }

  void setEmail(String email) {
    state = state.copyWith(email: email);
  }

  void setProfilePictureUrl(String url) {
    state = state.copyWith(profilePictureUrl: url, clearProfilePicture: false);
  }
}

/// Admin Profile Provider
final adminProfileProvider =
    StateNotifierProvider<AdminProfileNotifier, AdminProfile>((ref) {
  return AdminProfileNotifier();
});
