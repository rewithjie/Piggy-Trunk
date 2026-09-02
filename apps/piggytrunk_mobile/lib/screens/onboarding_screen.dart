import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _slides = [
    OnboardingData(
      title: 'Farm Growth & Support',
      description:
          'Connect with investors who provide essential resources for your pigs—including feeds, vitamins, vaccines, and housing support.',
      imagePath: 'assets/onboarding_invest.png',
    ),
    OnboardingData(
      title: 'Shared Profit & Success',
      description:
          'Every successful harvest creates mutual value. Hog raisers and investors share transparent, fair returns with real-time tracking.',
      imagePath: 'assets/onboarding_profit.png',
    ),
    OnboardingData(
      title: 'Ready to Get Started?',
      description:
          'Join our growing network of dedicated raisers, investors, and agribusiness partners today.',
      imagePath: 'assets/onboarding_start.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: PiggyTrunkTheme.ptBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Skip Action
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 12.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: _currentPage == _slides.length - 1 ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: _currentPage == _slides.length - 1,
                    child: InkWell(
                      onTap: () {
                        _pageController.animateToPage(
                          _slides.length - 1,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Skip',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF18314F),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: Color(0xFF18314F),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Page Slider
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return OnboardingPageContent(
                    data: _slides[index],
                    screenHeight: screenHeight,
                  );
                },
              ),
            ),

            // Bottom Navigation and Controls
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: screenHeight < 740 ? 12.0 : 20.0,
              ),
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => buildIndicator(index),
                    ),
                  ),
                  SizedBox(height: screenHeight < 740 ? 14.0 : 22.0),

                  // Action Button
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _currentPage == _slides.length - 1
                        ? SizedBox(
                            key: const ValueKey('actions_continue'),
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushReplacementNamed(context, '/signup');
                                },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF18314F),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Get Started',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                            ),
                          )
                        : SizedBox(
                            key: const ValueKey('action_next'),
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeInOut,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF18314F),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Next',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                            ),
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

  Widget buildIndicator(int index) {
    final bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 7.0,
      width: isActive ? 22.0 : 7.0,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF18314F) : const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String imagePath;

  OnboardingData({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

class OnboardingPageContent extends StatelessWidget {
  final OnboardingData data;
  final double screenHeight;

  const OnboardingPageContent({
    super.key,
    required this.data,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = screenHeight < 740;
    final double imageHeight = isSmallScreen ? (screenHeight * 0.28).clamp(150.0, 210.0) : (screenHeight * 0.33);
    final double titleFontSize = isSmallScreen ? 19.0 : 23.0;
    final double descriptionFontSize = isSmallScreen ? 13.0 : 14.5;
    final double gapHeight = isSmallScreen ? 12.0 : 20.0;

    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Graphic Image Container
            Container(
              height: imageHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(data.imagePath, fit: BoxFit.contain),
              ),
            ),
            SizedBox(height: gapHeight),

            // Slide Title
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF18314F),
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: isSmallScreen ? 6.0 : 10.0),

            // Slide Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                data.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: descriptionFontSize,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
