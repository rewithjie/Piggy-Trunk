import 'package:flutter/material.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import 'package:piggytrunk/theme/app_text_styles.dart';

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
      title: 'Tulong sa Pagpapalaki',
      description:
          'Mag-iinvest ang mga investor sa iyong farm para matulungan ka sa mga pangangailangan ng iyong mga baboy tulad ng pagkain, bakuna, at tirahan.',
      imagePath: 'assets/onboarding_invest.png',
    ),
    OnboardingData(
      title: 'Salu-salong Kita',
      description:
          'Sa bawat matagumpay na pagpapalaki at benta ng baboy, parehong kikita ang hog raiser at ang investor. Isang patas na tulungan!',
      imagePath: 'assets/onboarding_profit.png',
    ),
    OnboardingData(
      title: 'Simulan ang Iyong Negosyo',
      description:
          'Ikaw ba ay handa nang kumonekta sa mga investors at palaguin ang iyong pagbababuyan? Magsimula na ngayon!',
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
            // Top Bar (Skip Button)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: _currentPage == _slides.length - 1 ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: _currentPage == _slides.length - 1,
                    child: TextButton(
                      onPressed: () {
                        _pageController.animateToPage(
                          _slides.length - 1,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                      child: Text(
                        'Skip',
                        style: AppTextStyles.button(
                          const Color(0xFF18314F),
                        ).copyWith(fontSize: 15, fontWeight: FontWeight.w600),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => buildIndicator(index),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Actions Buttons
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _currentPage == _slides.length - 1
                        ? Column(
                            key: const ValueKey('actions_start'),
                            children: [
                              // Sign Up Button (Primary)
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/signup');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF18314F),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    'Mag-Sign Up Bilang Raiser',
                                    style: AppTextStyles.button(
                                      Colors.white,
                                    ).copyWith(fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Login Button (Secondary)
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/login');
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFF18314F),
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    'May Account na? Mag-Login',
                                    style: AppTextStyles.button(
                                      const Color(0xFF18314F),
                                    ).copyWith(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : SizedBox(
                            key: const ValueKey('action_next'),
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PiggyTrunkTheme.ptPrimary,
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
                                    'Susunod',
                                    style: AppTextStyles.button(
                                      Colors.white,
                                    ).copyWith(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 20),
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
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF18314F) : PiggyTrunkTheme.ptBorder,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Graphic Image Container with soft shadow and rounded borders
          Container(
            height: screenHeight * 0.35,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(data.imagePath, fit: BoxFit.contain),
            ),
          ),
          SizedBox(height: screenHeight * 0.05),

          // Slide Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.pageTitle(
              PiggyTrunkTheme.ptText,
            ).copyWith(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),

          // Slide Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              data.description,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(
                PiggyTrunkTheme.ptMuted,
              ).copyWith(fontSize: 15, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
