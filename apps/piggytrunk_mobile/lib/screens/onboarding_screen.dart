import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import 'package:piggytrunk/theme/app_text_styles.dart';

const String raiserSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <!-- Hat crown -->
  <path d="M8 8 C8 4, 16 4, 16 8" />
  <!-- Hat brim -->
  <path d="M4 9 L20 9" />
  <!-- Face/Head -->
  <path d="M9 9 V12 C9 13.7, 10.3 15, 12 15 C13.7 15, 15 13.7, 15 12 V9" />
  <!-- Shoulders -->
  <path d="M5 20 C5 17, 8 16, 12 16 C16 16, 19 17, 19 20" />
</svg>
''';

const String partnerSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <!-- Coin circle -->
  <circle cx="12" cy="12" r="10" />
  <!-- Peso sign '₱' -->
  <path d="M9.5 7v10" />
  <path d="M9.5 7h3.5a2.5 2.5 0 0 1 0 5H9.5" />
  <path d="M8 9.5h6" />
  <path d="M8 11.5h6" />
</svg>
''';

const String cashierSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="9" cy="21" r="1" fill="currentColor" />
  <circle cx="20" cy="21" r="1" fill="currentColor" />
  <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6" />
</svg>
''';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedRole = 'hog_raiser';

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
      title: 'Magpatuloy',
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

  Widget _buildRoleCard(String role, String title, String subtitle, String svgString) {
    final bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? PiggyTrunkTheme.ptPrimary.withValues(alpha: 0.06) : PiggyTrunkTheme.ptSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? PiggyTrunkTheme.ptPrimary : PiggyTrunkTheme.ptBorder,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? PiggyTrunkTheme.ptPrimary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? PiggyTrunkTheme.ptPrimary.withValues(alpha: 0.12) : PiggyTrunkTheme.ptBg,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 24,
                height: 24,
                child: SvgPicture.string(
                  svgString,
                  colorFilter: ColorFilter.mode(
                    isSelected ? PiggyTrunkTheme.ptPrimary : PiggyTrunkTheme.ptMuted,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? PiggyTrunkTheme.ptPrimary : PiggyTrunkTheme.ptText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? PiggyTrunkTheme.ptPrimary.withValues(alpha: 0.8) : PiggyTrunkTheme.ptMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: PiggyTrunkTheme.ptPrimary,
                size: 20,
              ),
          ],
        ),
      ),
    );
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
                    child: InkWell(
                      onTap: () {
                        _pageController.animateToPage(
                          _slides.length - 1,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: PiggyTrunkTheme.ptSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: PiggyTrunkTheme.ptBorder,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Laktawan',
                              style: AppTextStyles.bodyStrong(const Color(0xFF18314F)).copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 13,
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
                  if (index == _slides.length - 1) {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: screenHeight * 0.01),
                            // Slide Title
                            Text(
                              _slides[index].title,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.pageTitle(
                                PiggyTrunkTheme.ptText,
                              ).copyWith(fontSize: 24, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            // Slide Description
                            Text(
                              'Piliin ang iyong gampanin sa PiggyTrunk upang magpatuloy:',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body(
                                PiggyTrunkTheme.ptMuted,
                              ).copyWith(fontSize: 14),
                            ),
                            const SizedBox(height: 20),
                            // Role Cards Selector
                            _buildRoleCard('hog_raiser', 'Hog Raiser', 'Nag-aalaga at nagpapatakbo ng babuyan', raiserSvg),
                            const SizedBox(height: 12),
                            _buildRoleCard('partner', 'Partner Investor', 'Sumusuporta sa farm sa pamamagitan ng puhunan', partnerSvg),
                            const SizedBox(height: 12),
                            _buildRoleCard('cashier', 'Cashier / POS Staff', 'Namamahala sa pag-release ng supply at feeds', cashierSvg),
                            SizedBox(height: screenHeight * 0.02),
                          ],
                        ),
                      ),
                    );
                  }
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
                                    Navigator.pushNamed(
                                      context, 
                                      '/signup',
                                      arguments: _selectedRole,
                                    );
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
                                    _selectedRole == 'hog_raiser'
                                        ? 'Mag-Sign Up Bilang Raiser'
                                        : _selectedRole == 'partner'
                                            ? 'Mag-Sign Up Bilang Partner'
                                            : 'Mag-Sign Up Bilang Cashier',
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
                                    Navigator.pushNamed(
                                      context, 
                                      '/login',
                                      arguments: _selectedRole,
                                    );
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
