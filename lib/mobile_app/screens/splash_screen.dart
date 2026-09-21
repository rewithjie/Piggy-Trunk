import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_session_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _floatingController;
  late AnimationController _progressController;

  late Animation<double> _scaleSpringAnimation;
  late Animation<double> _fadeEntranceAnimation;
  late Animation<double> _titleSlideAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Spring Entrance Animation (0.6 -> 1.0 with natural bounce)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _scaleSpringAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeEntranceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _titleSlideAnimation = Tween<double>(begin: 18.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Continuous Floating / Levitation Animation (Ultra-smooth 2800ms easeInOutSine)
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _floatingController,
        curve: Curves.easeInOutSine,
      ),
    );

    // 3. Progress Bar Fill Animation (Synchronized with 10-second loading)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9600),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Start Entrance, then loop floating, then load app
    _entranceController.forward().then((_) {
      if (mounted) {
        _floatingController.repeat(reverse: true);
      }
    });
    _progressController.forward();

    _initializeApp();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatingController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();
    String targetRoute = '/onboarding';

    try {
      final authResult = await AuthSessionService().checkAndAttemptAutoLogin();
      if (authResult['canAutoLogin'] == true && authResult['targetRoute'] != null) {
        targetRoute = authResult['targetRoute'];
      } else if (authResult['targetRoute'] != null) {
        targetRoute = authResult['targetRoute'];
      }
    } catch (e) {
      debugPrint('Error during auto-login on SplashScreen: $e');
      targetRoute = '/onboarding';
    }

    final elapsedTime = DateTime.now().difference(startTime);
    // Adjusted to 10 seconds as requested by the user
    const minDuration = Duration(milliseconds: 10000);
    if (elapsedTime < minDuration) {
      await Future<void>.delayed(minDuration - elapsedTime);
    }

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(targetRoute, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandNavy = Color(0xFF18314F);
    const Color brandNavyDark = Color(0xFF0B1726);

    return Scaffold(
      backgroundColor: brandNavy,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A5F), // Rich Piggy Trunk Navy Top
              brandNavy,         // #18314F Core Brand Navy
              brandNavyDark,     // #0B1726 Deep Midnight Navy Base
            ],
          ),
        ),
        child: SafeArea(
          child: SizedBox.expand(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Animated Enlarged Spring & Floating PiggyTrunk Logo
                AnimatedBuilder(
                  animation: Listenable.merge([_entranceController, _floatingController]),
                  builder: (context, child) {
                    final floatY = _floatingController.isAnimating ? _floatAnimation.value : 0.0;
                    // Normalized t: 0.0 when top (-8px), 1.0 when bottom (+8px)
                    final double t = ((floatY + 8.0) / 16.0).clamp(0.0, 1.0);

                    return FadeTransition(
                      opacity: _fadeEntranceAnimation,
                      child: ScaleTransition(
                        scale: _scaleSpringAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Levitating Enlarged Logo (Height 165)
                            Transform.translate(
                              offset: Offset(0, floatY),
                              child: Image.asset(
                                'assets/piggytrunk_logo.png',
                                height: 165,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Photorealistic Soft Ambient Floor Shadow
                            Opacity(
                              opacity: (0.45 + 0.35 * t).clamp(0.25, 0.85),
                              child: Transform.scale(
                                scaleX: 0.88 + 0.24 * (1.0 - t),
                                scaleY: 0.85 + 0.20 * (1.0 - t),
                                child: Container(
                                  width: 125,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: const BorderRadius.all(Radius.elliptical(125, 18)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.75),
                                        blurRadius: 22,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Animated Brand Title "Piggy Trunk" (Pure White High Contrast)
                AnimatedBuilder(
                  animation: _entranceController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _titleSlideAnimation.value),
                      child: FadeTransition(
                        opacity: _fadeEntranceAnimation,
                        child: Text(
                          'Piggy Trunk',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            letterSpacing: -0.8,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // Raised & Enlarged Monochrome Silver-White Gradient Progress Bar
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    final progressVal = _progressAnimation.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Column(
                        children: [
                          Container(
                            height: 7.5,
                            width: 230,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D223B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                                width: 1,
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 230 * progressVal,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF94A3B8), // Silver slate
                                      Color(0xFFE2E8F0), // Platinum
                                      Colors.white,      // Pure White
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              progressVal < 0.30
                                  ? 'Connecting to PiggyTrunk network...'
                                  : progressVal < 0.65
                                      ? 'Syncing farm records & live stocks...'
                                      : progressVal < 0.90
                                          ? 'Securing session & permissions...'
                                          : 'Ready! Launching dashboard...',
                              key: ValueKey(
                                progressVal < 0.30
                                    ? 'p1'
                                    : progressVal < 0.65
                                        ? 'p2'
                                        : progressVal < 0.90
                                            ? 'p3'
                                            : 'p4',
                              ),
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFFCBD5E1),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const Spacer(flex: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
