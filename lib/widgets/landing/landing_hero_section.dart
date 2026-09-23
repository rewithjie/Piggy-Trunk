import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import 'scroll_reveal.dart';

class LandingHeroSection extends StatefulWidget {
  final VoidCallback? onContactTap;
  final VoidCallback? onLearnMoreTap;

  const LandingHeroSection({
    super.key,
    this.onContactTap,
    this.onLearnMoreTap,
  });

  @override
  State<LandingHeroSection> createState() => _LandingHeroSectionState();
}

class _LandingHeroSectionState extends State<LandingHeroSection> {
  // Active showcase tab: 0: Full Ecosystem, 1: Hog Raiser, 2: Cashier, 3: Partner Investor, 4: Admin Web
  int _activeTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    final titleColor = isDark ? PiggyTrunkTheme.ptTextDark : PiggyTrunkTheme.ptText;
    final subtitleColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;
    final pillBg = isDark ? PiggyTrunkTheme.ptSurfaceSoftDark : PiggyTrunkTheme.ptSurfaceSoft;
    final pillBorder = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isDesktop = availableWidth >= 1024;
        final horizontalPadding = availableWidth >= 1200
            ? 48.0
            : (availableWidth >= 768 ? 28.0 : 16.0);
        final verticalPadding = isMobile ? 32.0 : 54.0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // LEFT: HERO COPY
                        Expanded(
                          flex: 5,
                          child: _buildHeroCopy(
                            context,
                            titleColor: titleColor,
                            subtitleColor: subtitleColor,
                            pillBg: pillBg,
                            pillBorder: pillBorder,
                            isDark: isDark,
                            availableWidth: availableWidth,
                            isCentered: false,
                          ),
                        ),
                        const SizedBox(width: 40),

                        // RIGHT: MULTI-PLATFORM ECOSYSTEM VISUAL (Admin Web + 3 Phones)
                        Expanded(
                          flex: 7,
                          child: _buildRightSideVisual(
                            context,
                            isDark: isDark,
                            availableWidth: availableWidth / 2,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: _buildHeroCopy(
                            context,
                            titleColor: titleColor,
                            subtitleColor: subtitleColor,
                            pillBg: pillBg,
                            pillBorder: pillBorder,
                            isDark: isDark,
                            availableWidth: availableWidth,
                            isCentered: true,
                          ),
                        ),
                        const SizedBox(height: 36),
                        _buildRightSideVisual(
                          context,
                          isDark: isDark,
                          availableWidth: availableWidth,
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // LEFT: HERO COPY
  // -------------------------------------------------------------
  Widget _buildHeroCopy(
    BuildContext context, {
    required Color titleColor,
    required Color subtitleColor,
    required Color pillBg,
    required Color pillBorder,
    required bool isDark,
    required double availableWidth,
    required bool isCentered,
  }) {
    final headlineSize = availableWidth >= 1200
        ? 38.0
        : (availableWidth >= 768 ? 30.0 : 25.0);
    final subtitleSize = availableWidth >= 1200
        ? 15.0
        : (availableWidth >= 768 ? 14.0 : 13.5);

    return Column(
      crossAxisAlignment:
          isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        // Tagline Pill
        ScrollReveal(
          delay: const Duration(milliseconds: 60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: pillBorder),
            ),
            child: Text(
              'HOG RAISING MANAGEMENT MONITORING SYSTEM',
              textAlign: isCentered ? TextAlign.center : TextAlign.left,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isDark ? PiggyTrunkTheme.ptPrimaryDark : const Color(0xFF18314F),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Headline
        ScrollReveal(
          delay: const Duration(milliseconds: 140),
          child: Text(
            'Manage Your Retail Business and Hog-Raising Operations in One Place',
            textAlign: isCentered ? TextAlign.center : TextAlign.left,
            style: GoogleFonts.plusJakartaSans(
              fontSize: headlineSize,
              fontWeight: FontWeight.w800,
              height: 1.22,
              letterSpacing: -0.8,
              color: titleColor,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Paragraph 1 & 2
        ScrollReveal(
          delay: const Duration(milliseconds: 220),
          child: Column(
            crossAxisAlignment:
                isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Text(
                'PIGGY TRUNK helps business owners monitor inventory, stock distribution, retail sales, and hog-raising progress through one centralized system.',
                textAlign: isCentered ? TextAlign.center : TextAlign.left,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.w400,
                  height: 1.6,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Whether you manage your operation through the Admin Portal or access your assigned functions through the mobile application, PIGGY TRUNK keeps your business information organized and accessible.',
                textAlign: isCentered ? TextAlign.center : TextAlign.left,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.w400,
                  height: 1.6,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // RIGHT: MULTI-PLATFORM ECOSYSTEM VISUAL (Admin Web + 3 Mobile Phones)
  // -------------------------------------------------------------
  Widget _buildRightSideVisual(
    BuildContext context, {
    required bool isDark,
    required double availableWidth,
  }) {
    final cardBorder = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
    final cardBg = isDark ? const Color(0xFF151F2E) : Colors.white;
    final textDark = isDark ? PiggyTrunkTheme.ptTextDark : PiggyTrunkTheme.ptText;
    final textMuted = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Top Switcher Tabs (Responsive horizontally scrollable)
        _buildVisualTabs(isDark, availableWidth),
        const SizedBox(height: 16),

        // Display Area with Smooth Transitions
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: _buildSelectedDisplay(
            _activeTabIndex,
            isDark: isDark,
            cardBg: cardBg,
            cardBorder: cardBorder,
            textDark: textDark,
            textMuted: textMuted,
            availableWidth: availableWidth,
          ),
        ),
      ],
    );
  }

  Widget _buildVisualTabs(bool isDark, double availableWidth) {
    final tabs = [
      (0, '✨ Full Ecosystem'),
      (1, '🐷 Hog Raiser'),
      (2, '🏪 Cashier'),
      (3, '📈 Partner Investor'),
      (4, '🖥️ Web Admin'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151F2E) : const Color(0xFFEDF2F7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: tabs.map((t) => _buildTabPill(t.$1, t.$2, isDark)).toList(),
        ),
      ),
    );
  }

  Widget _buildTabPill(int index, String label, bool isDark) {
    final isSelected = _activeTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0284C7) : const Color(0xFF18314F))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF0284C7) : const Color(0xFF18314F))
                        .withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? PiggyTrunkTheme.ptMutedDark : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDisplay(
    int index, {
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color textDark,
    required Color textMuted,
    required double availableWidth,
  }) {
    switch (index) {
      case 1:
        return _buildSinglePhoneView(
          key: const ValueKey(1),
          imagePath: 'assets/landing/phone_hog_raiser.webp',
          badge: 'HOG RAISER MOBILE PORTAL',
          badgeColor: const Color(0xFF10B981),
          title: 'Direct Farm Operations',
          description:
              'Monitor pig growth batches, record daily feed logs, view health diagnostics, and submit stock requests right from the pigpen.',
          isDark: isDark,
          cardBg: cardBg,
          cardBorder: cardBorder,
          textDark: textDark,
          textMuted: textMuted,
        );
      case 2:
        return _buildSinglePhoneView(
          key: const ValueKey(2),
          imagePath: 'assets/landing/phone_cashier.webp',
          badge: 'CASHIER & POS INVENTORY',
          badgeColor: const Color(0xFFF59E0B),
          title: 'Store & Inventory Management',
          description:
              'Process walk-in feed purchases, check real-time stock levels, receive automated low-stock warnings, and track daily sales transactions.',
          isDark: isDark,
          cardBg: cardBg,
          cardBorder: cardBorder,
          textDark: textDark,
          textMuted: textMuted,
        );
      case 3:
        return _buildSinglePhoneView(
          key: const ValueKey(3),
          imagePath: 'assets/landing/phone_partner_investor.webp',
          badge: 'PARTNER INVESTOR APP',
          badgeColor: const Color(0xFF6366F1),
          title: 'Transparent Growth & Capital',
          description:
              'Browse available raising batches, monitor portfolio value and funded hogs, and track lifecycle ROI with full accountability.',
          isDark: isDark,
          cardBg: cardBg,
          cardBorder: cardBorder,
          textDark: textDark,
          textMuted: textMuted,
        );
      case 4:
        return _buildWebAdminView(
          key: const ValueKey(4),
          isDark: isDark,
          cardBg: cardBg,
          cardBorder: cardBorder,
          textDark: textDark,
          textMuted: textMuted,
        );
      default:
        return _buildFullEcosystemView(
          key: const ValueKey(0),
          isDark: isDark,
          cardBorder: cardBorder,
          availableWidth: availableWidth,
        );
    }
  }

  Widget _buildFullEcosystemView({
    required Key key,
    required bool isDark,
    required Color cardBorder,
    required double availableWidth,
  }) {
    return KeyedSubtree(
      key: key,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF243B53) : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.55)
                      : const Color(0xFF18314F).withValues(alpha: 0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 1600 / 1128,
                child: Image.asset(
                  'assets/landing/hero_ecosystem_showcase.webp',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Caption Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? PiggyTrunkTheme.ptSurfaceSoftDark
                  : PiggyTrunkTheme.ptSurfaceSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? PiggyTrunkTheme.ptBorderDark
                    : PiggyTrunkTheme.ptBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'Connected Cloud: Web Admin Portal & 3-Role Mobile Apps',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? PiggyTrunkTheme.ptTextDark
                        : const Color(0xFF18314F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinglePhoneView({
    required Key key,
    required String imagePath,
    required String badge,
    required Color badgeColor,
    required String title,
    required String description,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color textDark,
    required Color textMuted,
  }) {
    return KeyedSubtree(
      key: key,
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 460),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    height: 1.5,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebAdminView({
    required Key key,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color textDark,
    required Color textMuted,
  }) {
    return KeyedSubtree(
      key: key,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/landing/admin_web_showcase.webp',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'CENTRAL COMMAND',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0284C7),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PiggyTrunk Admin Web Portal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Web-based administration system for overall inventory oversight, hog raiser accounts, batch lifecycle management, and financial summaries.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    height: 1.5,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
