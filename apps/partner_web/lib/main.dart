import 'package:flutter/material.dart';
import 'screens/partner_dashboard_screen.dart';
import 'screens/partner_login_screen.dart';

void main() {
  runApp(const PartnerWebApp());
}

class PartnerWebApp extends StatelessWidget {
  const PartnerWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PiggyTrunk Partner',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (_) => const PartnerLoginScreen(),
        '/dashboard': (_) => const PartnerDashboardScreen(),
      },
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => const PartnerLoginScreen(),
      ),
    );
  }
}
