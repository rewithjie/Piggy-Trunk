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
    bool hasValidSession = false;
    String targetRoute = '/onboarding';

    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;

      if (session != null) {
        // Fetch profile status and role to verify eligibility
        final userData = await supabase
            .from('app_users')
            .select('status, role')
            .eq('supabase_user_id', session.user.id)
            .maybeSingle();

        if (userData != null) {
          final status = userData['status'] as String;
          final role = userData['role'] as String;

          final allowedRoles = ['hog_raiser', 'partner', 'cashier', 'admin'];
          if (allowedRoles.contains(role) && status == 'active') {
            hasValidSession = true;
            switch (role) {
              case 'hog_raiser':
                targetRoute = '/raiser_dashboard';
                break;
              case 'partner':
                targetRoute = '/partner_dashboard';
                break;
              case 'cashier':
                targetRoute = '/cashier_dashboard';
                break;
              case 'admin':
                targetRoute = '/admin_dashboard';
                break;
              default:
                targetRoute = '/onboarding';
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking session: $e');
    }

    if (!hasValidSession) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
    }

    final elapsedTime = DateTime.now().difference(startTime);
    const minDuration = Duration(seconds: 2);
    if (elapsedTime < minDuration) {
      await Future<void>.delayed(minDuration - elapsedTime);
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, targetRoute);
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
