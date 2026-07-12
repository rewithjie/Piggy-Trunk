import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import 'package:piggytrunk/theme/app_text_styles.dart';

class MobileDashboardScreen extends StatelessWidget {
  const MobileDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: PiggyTrunkTheme.ptBg,
      appBar: AppBar(
        title: const Text(
          'Hog Raiser Dashboard',
          style: TextStyle(color: Color(0xFF18314F), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            icon: const Icon(Icons.logout, color: Color(0xFF18314F)),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 80,
                color: PiggyTrunkTheme.ptSuccess,
              ),
              const SizedBox(height: 24),
              Text(
                'Maligayang Pagbabalik!',
                style: AppTextStyles.pageTitle(const Color(0xFF18314F)).copyWith(
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? '',
                style: AppTextStyles.body(PiggyTrunkTheme.ptMuted),
              ),
              const SizedBox(height: 32),
              Card(
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: PiggyTrunkTheme.ptBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'Hog Raiser Portal Active',
                        style: AppTextStyles.cardTitle(const Color(0xFF18314F)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aktibo na ang iyong account! Handa ka nang mag-manage ng iyong babuyan at makipag-ugnayan sa mga investors.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(PiggyTrunkTheme.ptMuted).copyWith(
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
