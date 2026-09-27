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
  late AnimationController _dotsController;

  late Animation<double> _scaleSpringAnimation;
  late Animation<double> _fadeEntranceAnimation;
  late Animation<double> _titleSlideAnimation;
  late Animation<double> _floatAnimation;

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

    // 3. Continuous 4-Dot Wave Animation (Smooth 1400ms repeating loop)
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Start Entrance, then loop floating and dots, then load app
    _entranceController.forward().then((_) {
      if (mounted) {
        _floatingController.repeat(reverse: true);
        _dotsController.repeat();
      }
    });

    _initializeApp();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatingController.dispose();
    _dotsController.dispose();
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
    // Set display duration to 5 seconds as requested
    const minDuration = Duration(seconds: 5);
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF), // Clean bright soft white top
              Color(0xFFF8FAFC), // Calming soft slate-white body
              Color(0xFFF1F5F9), // Gentle ambient base
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
                            // Photorealistic Soft Ambient Floor Shadow (Recalibrated for soft white)
                            Opacity(
                              opacity: (0.16 + 0.14 * t).clamp(0.10, 0.35),
                              child: Transform.scale(
                                scaleX: 0.85 + 0.25 * (1.0 - t),
                                scaleY: 0.82 + 0.22 * (1.0 - t),
                                child: Container(
                                  width: 120,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF64748B).withValues(alpha: 0.25),
                                    borderRadius: const BorderRadius.all(Radius.elliptical(120, 14)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF475569).withValues(alpha: 0.20),
                                        blurRadius: 18,
                                        spreadRadius: 3,
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

                // Animated Brand Title "Piggy Trunk" (High Contrast Rich Navy)
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
                            color: brandNavy,
                            letterSpacing: -0.8,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              BoxShadow(
                                color: brandNavy.withValues(alpha: 0.08),
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

                // 4-Dot Sequential Wave Fade/Scale Loader
                FadeTransition(
                  opacity: _fadeEntranceAnimation,
                  child: DottedWaveLoader(
                    animation: _dotsController,
                    dotCount: 4,
                    dotSize: 9.0,
                    spacing: 11.0,
                    activeColor: brandNavy,
                    inactiveColor: const Color(0xFF94A3B8),
                  ),
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

/// 4-Dot Animated Wave Loader with Sequential Fade and Micro-Scale
class DottedWaveLoader extends StatelessWidget {
  final Animation<double> animation;
  final int dotCount;
  final double dotSize;
  final double spacing;
  final Color activeColor;
  final Color inactiveColor;

  const DottedWaveLoader({
    super.key,
    required this.animation,
    this.dotCount = 4,
    this.dotSize = 9.0,
    this.spacing = 11.0,
    this.activeColor = const Color(0xFF18314F),
    this.inactiveColor = const Color(0xFF94A3B8),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = animation.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(dotCount, (index) {
            // Target center for each dot in the [0.0, 1.0] cycle
            final double dotTarget = index / dotCount;
            double diff = (progress - dotTarget);

            // Handle wrap-around distance for infinite loop
            if (diff < -0.5) diff += 1.0;
            if (diff > 0.5) diff -= 1.0;

            // Liquid smooth bell curve around active dot
            final double rawIntensity = (1.0 - (diff.abs() / 0.30)).clamp(0.0, 1.0);
            final double intensity = Curves.easeInOutSine.transform(rawIntensity);

            // Subtle, sleek micro-scale from 0.90 to 1.14
            final double scale = 0.90 + (0.24 * intensity);

            // Refined opacity from 0.22 to 1.0
            final double opacity = 0.22 + (0.78 * intensity);

            // Color blend: soft slate to prominent deep brand navy
            final Color color = Color.lerp(inactiveColor, activeColor, intensity)!;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: intensity > 0.4
                          ? [
                              BoxShadow(
                                color: activeColor.withValues(alpha: 0.16 * intensity),
                                blurRadius: 4 * intensity,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
