import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/raiser/dashboard_screen.dart';
import 'screens/partner/partner_dashboard_screen.dart';
import 'screens/cashier/cashier_dashboard_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Ignore missing env file during local development.
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim();
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim();

  if (supabaseUrl != null && supabaseUrl.isNotEmpty && supabaseAnonKey != null && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  runApp(const HogRaiserMobileApp());
}

class HogRaiserMobileApp extends StatelessWidget {
  const HogRaiserMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PiggyTrunk',
      debugShowCheckedModeBanner: false,
      theme: PiggyTrunkTheme.lightTheme.copyWith(
        snackBarTheme: SnackBarThemeData(
          contentTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      darkTheme: PiggyTrunkTheme.darkTheme.copyWith(
        snackBarTheme: SnackBarThemeData(
          contentTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      themeMode: ThemeMode.light,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/raiser_dashboard': (context) => const MobileDashboardScreen(),
        '/partner_dashboard': (context) => const PartnerDashboardScreen(),
        '/cashier_dashboard': (context) => const CashierDashboardScreen(),
        '/admin_dashboard': (context) => const AdminMobileDashboardScreen(),
      },
    );
  }
}
