import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/admin_login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/hog_raiser_screen.dart';
import 'screens/investments_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/pos_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/user_approvals_screen.dart';

import 'screens/mobile_app_distribution_screen.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
bool isInitialLaunch = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Ignore missing env file during web deployment.
  }

  const defaultSupabaseUrl = 'https://ywwwrshblzyqmxkbkxsp.supabase.co';
  const defaultSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3d3dyc2hibHp5cW14a2JreHNwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc3MjU2MDMsImV4cCI6MjA5MzMwMTYwM30.ceKymQgbjU3IAbHxS2OUiOV9Mf5DxVxf9eBgzRuCHXo';

  final envUrl = dotenv.env['SUPABASE_URL']?.trim();
  final envKey = dotenv.env['SUPABASE_ANON_KEY']?.trim();

  final supabaseUrl = (envUrl != null && envUrl.isNotEmpty)
      ? envUrl
      : const String.fromEnvironment('SUPABASE_URL', defaultValue: defaultSupabaseUrl);
  final supabaseAnonKey = (envKey != null && envKey.isNotEmpty)
      ? envKey
      : const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: defaultSupabaseAnonKey);

  try {
    await Supabase.initialize(
      url: supabaseUrl.isNotEmpty ? supabaseUrl : defaultSupabaseUrl,
      anonKey: supabaseAnonKey.isNotEmpty ? supabaseAnonKey : defaultSupabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase init warning: $e');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'PiggyTrunk Admin',
      theme: PiggyTrunkTheme.lightTheme,
      darkTheme: PiggyTrunkTheme.darkTheme,
      themeMode: themeMode,
      themeAnimationDuration: Duration.zero,
      themeAnimationCurve: Curves.linear,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const AdminLoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/raisers': (context) => const HogRaiserScreen(),
        '/investments': (context) => const InvestmentsScreen(),
        '/inventory': (context) => const InventoryScreen(),
        '/pos': (context) => const POSScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/users': (context) => const UserApprovalsScreen(),
        '/mobile-app': (context) => const MobileAppDistributionScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
