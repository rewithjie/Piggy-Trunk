import '../models/user_model.dart';

class MockAuthData {
  static const String mockToken = 'demo_token_12345abcde';
  
  static const String mockEmail = 'admin@piggytrunk';
  static const String mockPassword = 'password123';

  static UserModel getMockUser() {
    return UserModel(
      id: 1,
      name: 'Admin User',
      email: mockEmail,
      emailVerifiedAt: DateTime.now().subtract(const Duration(days: 30)).toString(),
      createdAt: DateTime.now().subtract(const Duration(days: 90)).toString(),
      updatedAt: DateTime.now().toString(),
      role: 'admin',
      isActive: true,
    );
  }

  static bool validateCredentials(String email, String password) {
    return email.toLowerCase() == mockEmail && password == mockPassword;
  }
}
