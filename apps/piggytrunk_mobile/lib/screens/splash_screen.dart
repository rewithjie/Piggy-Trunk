import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:piggytrunk/theme/app_text_styles.dart';
import 'package:piggytrunk/widgets/piggy_trunk_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.05)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_animationController);

    _animationController.repeat();

    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();
    String targetRoute = '/onboarding';

    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;

      if (session != null) {
        final user = session.user;
        Map<String, dynamic>? userData;

        try {
          final userEmail = user.email;
          if (userEmail != null && userEmail.isNotEmpty) {
            userData = await supabase
                .from('app_users')
                .select('status, role, user_id')
                .or('supabase_user_id.eq.${user.id},email.eq.$userEmail')
                .maybeSingle();
          } else {
            userData = await supabase
                .from('app_users')
                .select('status, role, user_id')
                .eq('supabase_user_id', user.id)
                .maybeSingle();
          }
        } catch (dbErr) {
          debugPrint('Notice during app_users check: $dbErr');
        }

        // Fallback: check specific role tables if app_users not found
        if (userData == null && user.email != null) {
          try {
            final raiser = await supabase
                .from('hog_raisers')
                .select('account_status, status')
                .eq('email', user.email!)
                .maybeSingle();
            if (raiser != null) {
              userData = {
                'role': 'hog_raiser',
                'status': raiser['account_status'] ?? raiser['status'] ?? 'Active',
              };
            }
          } catch (_) {}
        }

        if (userData != null) {
          final String rawStatus = (userData['status'] ?? 'Active').toString();
          final String statusLower = rawStatus.toLowerCase();
          final String role = (userData['role'] ?? 'hog_raiser').toString();

          if (statusLower == 'active') {
            switch (role) {
              case 'hog_raiser':
              case 'raiser':
                targetRoute = '/raiser_dashboard';
                break;
              case 'partner':
              case 'investor':
                targetRoute = '/partner_dashboard';
                break;
              case 'cashier':
                targetRoute = '/cashier_dashboard';
                break;
              case 'admin':
                targetRoute = '/admin_dashboard';
                break;
              default:
                targetRoute = '/raiser_dashboard';
            }
          } else if (statusLower == 'pending') {
            // Still pending approval
            targetRoute = '/onboarding';
          }
        } else {
          // If session exists and user metadata has role, route directly
          final userMetaRole = user.userMetadata?['role']?.toString().toLowerCase() ?? 'hog_raiser';
          if (userMetaRole.contains('partner')) {
            targetRoute = '/partner_dashboard';
          } else if (userMetaRole.contains('cashier')) {
            targetRoute = '/cashier_dashboard';
          } else if (userMetaRole.contains('admin')) {
            targetRoute = '/admin_dashboard';
          } else {
            targetRoute = '/raiser_dashboard';
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking session: $e');
    }

    final elapsedTime = DateTime.now().difference(startTime);
    const minDuration = Duration(milliseconds: 1200);
    if (elapsedTime < minDuration) {
      await Future<void>.delayed(minDuration - elapsedTime);
    }

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(targetRoute, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandColor = Color(0xFF18314F);
    const Color backgroundBg = Color(0xFFE0E6EF);

    return Scaffold(
      backgroundColor: backgroundBg,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: const PiggyTrunkLogo(
                      size: 140,
                      withBorder: false,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Piggy Trunk',
                    style: AppTextStyles.jakarta(
                      size: 32,
                      weight: FontWeight.w800,
                      color: brandColor,
                      letterSpacing: -0.6,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation<Color>(brandColor),
                      strokeWidth: 3.5,
                      backgroundColor: brandColor.withValues(alpha: 0.1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: AppTextStyles.jakarta(
                      size: 12,
                      weight: FontWeight.w600,
                      color: brandColor.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
