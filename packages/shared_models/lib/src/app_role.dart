enum AppRole {
  admin,
  cashier,
  partner,
  hogRaiser,
}

extension AppRoleX on AppRole {
  String get value {
    switch (this) {
      case AppRole.admin:
        return 'admin';
      case AppRole.cashier:
        return 'cashier';
      case AppRole.partner:
        return 'partner';
      case AppRole.hogRaiser:
        return 'hog_raiser';
    }
  }

  static AppRole fromValue(String value) {
    switch (value) {
      case 'admin':
        return AppRole.admin;
      case 'cashier':
        return AppRole.cashier;
      case 'partner':
        return AppRole.partner;
      case 'hog_raiser':
        return AppRole.hogRaiser;
      default:
        throw ArgumentError('Unsupported role: $value');
    }
  }
}
