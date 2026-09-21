import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends StatefulWidget {
  final Widget child;

  const SettingsProvider({super.key, required this.child});

  static SettingsScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SettingsScope>();
  }

  @override
  State<SettingsProvider> createState() => _SettingsProviderState();
}

class _SettingsProviderState extends State<SettingsProvider> {
  static const String _localePrefKey = 'app_locale';
  static const String _themePrefKey = 'app_theme_mode';

  String _currentLocale = 'en'; // 'en' or 'fil'
  ThemeMode _themeMode = ThemeMode.light; // light or dark

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load locale
      final savedLocale = prefs.getString(_localePrefKey);
      if (savedLocale != null && (savedLocale == 'en' || savedLocale == 'fil')) {
        _currentLocale = savedLocale;
      }

      // Load theme mode
      final savedTheme = prefs.getString(_themePrefKey);
      if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Settings load error: $e');
    }
  }

  Future<void> setLocale(String newLocale) async {
    if (newLocale != 'en' && newLocale != 'fil') return;
    if (_currentLocale == newLocale) return;

    setState(() {
      _currentLocale = newLocale;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localePrefKey, newLocale);
    } catch (e) {
      debugPrint('Locale save error: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    setState(() {
      _themeMode = mode;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePrefKey, mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (e) {
      debugPrint('Theme save error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      currentLocale: _currentLocale,
      themeMode: _themeMode,
      setLocale: setLocale,
      setThemeMode: setThemeMode,
      child: widget.child,
    );
  }
}

class SettingsScope extends InheritedWidget {
  final String currentLocale;
  final ThemeMode themeMode;
  final Future<void> Function(String) setLocale;
  final Future<void> Function(ThemeMode) setThemeMode;

  const SettingsScope({
    super.key,
    required this.currentLocale,
    required this.themeMode,
    required this.setLocale,
    required this.setThemeMode,
    required super.child,
  });

  bool get isDarkMode => themeMode == ThemeMode.dark;

  @override
  bool updateShouldNotify(SettingsScope oldWidget) {
    return currentLocale != oldWidget.currentLocale ||
        themeMode != oldWidget.themeMode;
  }
}
