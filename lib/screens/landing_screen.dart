import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/landing/landing_nav_bar.dart';
import '../widgets/landing/landing_hero_section.dart';
import '../widgets/landing/landing_how_it_works_section.dart';
import '../widgets/landing/landing_roles_section.dart';
import '../widgets/landing/landing_download_section.dart';
import '../widgets/landing/landing_contact_section.dart';
import '../widgets/landing/landing_footer.dart';
import '../widgets/landing/scroll_reveal.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _rolesKey = GlobalKey();
  final GlobalKey _downloadKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();

  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 400 && !_showBackToTop) {
      setState(() => _showBackToTop = true);
    } else if (_scrollController.offset <= 400 && _showBackToTop) {
      setState(() => _showBackToTop = false);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToKey(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _scrollToContact() {
    _scrollToKey(_contactKey);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? PiggyTrunkTheme.ptBgDark : PiggyTrunkTheme.ptBg;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Navigation Bar
            LandingNavBar(
              onScrollToOverview: () => _scrollToKey(_heroKey),
              onScrollToHowItWorks: () => _scrollToKey(_howItWorksKey),
              onScrollToPlatforms: () => _scrollToKey(_rolesKey),
              onScrollToDownload: () => _scrollToKey(_downloadKey),
              onContactTap: _scrollToContact,
            ),

            // Scrollable Landing Content
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Hero Section
                        Container(
                          key: _heroKey,
                          child: LandingHeroSection(
                            onContactTap: _scrollToContact,
                            onLearnMoreTap: () => _scrollToKey(_howItWorksKey),
                          ),
                        ),

                        // How to Get Started Section
                        ScrollReveal(
                          delay: const Duration(milliseconds: 60),
                          child: Container(
                            key: _howItWorksKey,
                            child: LandingHowItWorksSection(
                              onContactTap: _scrollToContact,
                            ),
                          ),
                        ),

                        // Role Breakdown Section
                        ScrollReveal(
                          delay: const Duration(milliseconds: 60),
                          child: Container(
                            key: _rolesKey,
                            child: const LandingRolesSection(),
                          ),
                        ),

                        // Download & Android Installation Guide Section
                        ScrollReveal(
                          delay: const Duration(milliseconds: 60),
                          child: LandingDownloadSection(
                            downloadSectionKey: _downloadKey,
                          ),
                        ),

                        // Dedicated In-Page Contact & Inquiries Section (Option 2)
                        ScrollReveal(
                          delay: const Duration(milliseconds: 60),
                          child: LandingContactSection(
                            contactSectionKey: _contactKey,
                          ),
                        ),

                        // Footer
                        ScrollReveal(
                          delay: const Duration(milliseconds: 60),
                          fadeOnly: true,
                          child: LandingFooter(
                            onScrollToOverview: () => _scrollToKey(_heroKey),
                            onScrollToHowItWorks: () => _scrollToKey(_howItWorksKey),
                            onScrollToPlatforms: () => _scrollToKey(_rolesKey),
                            onScrollToDownload: () => _scrollToKey(_downloadKey),
                            onContactTap: _scrollToContact,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Floating Back-to-Top Button
                  if (_showBackToTop)
                    Positioned(
                      bottom: 24,
                      right: 24,
                      child: FloatingActionButton.small(
                        backgroundColor: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                        foregroundColor: isDark
                            ? Colors.white
                            : PiggyTrunkTheme.ptPrimary,
                        elevation: 4,
                        onPressed: () {
                          _scrollController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOutCubic,
                          );
                        },
                        tooltip: 'Back to top',
                        child: const Icon(Icons.arrow_upward_rounded),
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
