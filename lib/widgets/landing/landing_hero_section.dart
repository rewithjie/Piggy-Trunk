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
  bool _isPeekingAdmin = false;

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
                        const SizedBox(width: 44),

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
  // RIGHT: MULTI-PLATFORM ECOSYSTEM VISUAL (Approach C: Full Admin Web + Floating Peek Phones)
  // -------------------------------------------------------------
  Widget _buildRightSideVisual(
    BuildContext context, {
    required bool isDark,
    required double availableWidth,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stageWidth = constraints.maxWidth;
        // Proportional stage height
        final stageHeight = (stageWidth / 1.34).clamp(320.0, 510.0);

        return MouseRegion(
          onEnter: (_) => setState(() => _isPeekingAdmin = true),
          onExit: (_) => setState(() => _isPeekingAdmin = false),
          child: GestureDetector(
            onTap: () => setState(() => _isPeekingAdmin = !_isPeekingAdmin),
            child: Container(
              width: stageWidth,
              height: stageHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.55)
                        : const Color(0xFF18314F).withValues(alpha: 0.12),
                    blurRadius: 32,
                    offset: const Offset(0, 14),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // LAYER 1: ADMIN WEB DASHBOARD (Vector Sharp, Light/Dark Synced, Fully Visible)
                    Positioned.fill(
                      child: _buildAdminWebWidget(isDark, stageWidth, stageHeight),
                    ),

                    // LAYER 2: 3 FLOATING PHONES (Lowered, Transparent on Hover/Peek)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -stageHeight * 0.10,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeInOut,
                        opacity: _isPeekingAdmin ? 0.18 : 1.0,
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          offset: _isPeekingAdmin
                              ? const Offset(0, 0.07)
                              : Offset.zero,
                          child: _buildThreePhonesRow(stageWidth, stageHeight, isDark),
                        ),
                      ),
                    ),

                    // LAYER 3: INTERACTIVE PEEK HINT CHIP
                    Positioned(
                      top: 10,
                      right: 12,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: _isPeekingAdmin ? 0.95 : 0.75,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F1724).withValues(alpha: 0.90)
                                : Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF28354A)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isPeekingAdmin
                                    ? Icons.visibility_rounded
                                    : Icons.touch_app_rounded,
                                size: 11,
                                color: const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isPeekingAdmin
                                    ? 'Admin Web Uncovered'
                                    : 'Hover / Tap to Peek',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? PiggyTrunkTheme.ptTextDark
                                      : const Color(0xFF18314F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // LAYER 1: ADMIN WEB DASHBOARD WIDGET (Light & Dark Synced)
  // -------------------------------------------------------------
  Widget _buildAdminWebWidget(bool isDark, double stageWidth, double stageHeight) {
    final browserFrameBg = isDark ? const Color(0xFF161F2E) : const Color(0xFFE2E8F0);
    final browserBorder = isDark ? const Color(0xFF28354A) : const Color(0xFFCBD5E1);
    final canvasBg = isDark ? const Color(0xFF0F1724) : const Color(0xFFF8FAFC);
    final sidebarBg = isDark ? const Color(0xFF151F2E) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1B2638) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF28354A) : const Color(0xFFE2E8F0);
    final textDark = isDark ? const Color(0xFFECF2FF) : const Color(0xFF18314F);
    final textMuted = isDark ? const Color(0xFF9CB0C9) : const Color(0xFF64748B);
    final activeNavBg = isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE8F1FA);

    final isCompact = stageWidth < 460;
    final sidebarWidth = isCompact ? 36.0 : 130.0;

    return Container(
      color: canvasBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Browser Tab & Address Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: browserFrameBg,
              border: Border(bottom: BorderSide(color: browserBorder, width: 0.8)),
            ),
            child: Row(
              children: [
                // Window Control Buttons (Red, Yellow, Green)
                Row(
                  children: [
                    Container(width: 7.5, height: 7.5, decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Container(width: 7.5, height: 7.5, decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Container(width: 7.5, height: 7.5, decoration: const BoxDecoration(color: Color(0xFF27C93F), shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(width: 10),

                // Browser Tab: Piggy Trunk Admin
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F1724) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: browserBorder, width: 0.6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/piggytrunk_logo.png',
                        width: 11,
                        height: 11,
                        errorBuilder: (_, _, _) => const Icon(Icons.pets_rounded, size: 10, color: Color(0xFF0284C7)),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Piggy Trunk Admin',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Address Bar: admin.piggytrunk.site/dashboard
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0A101A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, size: 9, color: isDark ? const Color(0xFF10B981) : const Color(0xFF18314F)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'admin.piggytrunk.site/dashboard',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Web App Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: sidebarBg,
              border: Border(bottom: BorderSide(color: browserBorder, width: 0.8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.menu_rounded, size: 13, color: textDark),
                    const SizedBox(width: 8),
                    Image.asset(
                      'assets/piggytrunk_logo.png',
                      width: 14,
                      height: 14,
                      errorBuilder: (_, _, _) => const Icon(Icons.pets_rounded, size: 12, color: Color(0xFF0284C7)),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'PiggyTrunk',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.notifications_none_rounded, size: 13, color: textMuted),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: activeNavBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0284C7),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.person_rounded, size: 9, color: Colors.white),
                            ),
                          ),
                          if (!isCompact) ...[
                            const SizedBox(width: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: textDark,
                                  ),
                                ),
                                Text(
                                  'SYSTEM ADMINISTRATOR',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 6,
                                    fontWeight: FontWeight.w700,
                                    color: textMuted,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Web App Body (Sidebar + Dashboard Canvas)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Sidebar
                Container(
                  width: sidebarWidth,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(
                    color: sidebarBg,
                    border: Border(right: BorderSide(color: browserBorder, width: 0.8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSidebarItem(Icons.grid_view_rounded, 'Dashboard', true, activeNavBg, textDark, textMuted, isCompact),
                      _buildSidebarItem(Icons.pets_rounded, 'Hog Raiser', false, activeNavBg, textDark, textMuted, isCompact),
                      _buildSidebarItem(Icons.people_outline_rounded, 'User Approvals', false, activeNavBg, textDark, textMuted, isCompact),
                      _buildSidebarItem(Icons.layers_outlined, 'Batch Mgmt', false, activeNavBg, textDark, textMuted, isCompact),
                      _buildSidebarItem(Icons.trending_up_rounded, 'Investment', false, activeNavBg, textDark, textMuted, isCompact),
                      _buildSidebarItem(Icons.inventory_2_outlined, 'Inventory', false, activeNavBg, textDark, textMuted, isCompact),
                      _buildSidebarItem(Icons.point_of_sale_rounded, 'POS', false, activeNavBg, textDark, textMuted, isCompact),
                    ],
                  ),
                ),

                // Main Dashboard Area
                Expanded(
                  child: Container(
                    color: canvasBg,
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Dashboard + Refresh icon
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Dashboard',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: textDark,
                                ),
                              ),
                              Icon(Icons.refresh_rounded, size: 14, color: textMuted),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Row of 2 Top KPI Cards
                          Row(
                            children: [
                              Expanded(
                                child: _buildKpiCard(
                                  'NUMBER OF HOG BATCH',
                                  '6',
                                  cardBg,
                                  cardBorder,
                                  textDark,
                                  textMuted,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildKpiCard(
                                  'TOTAL CURRENT INVESTMENT',
                                  '₱33,550',
                                  cardBg,
                                  cardBorder,
                                  textDark,
                                  textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Bottom Investment Allocation Card
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'INVESTMENT ALLOCATION',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w700,
                                            color: textMuted,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                        Text(
                                          '5 active raisers',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 7.5,
                                            color: textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Total: ₱33,550',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w700,
                                        color: textDark,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSubAllocationCard(
                                        'FATTENING',
                                        '₱30,550',
                                        isDark ? const Color(0xFF152233) : const Color(0xFFF1F5F9),
                                        cardBorder,
                                        textDark,
                                        textMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildSubAllocationCard(
                                        'SOW',
                                        '₱3,000',
                                        isDark ? const Color(0xFF152233) : const Color(0xFFF1F5F9),
                                        cardBorder,
                                        textDark,
                                        textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
    );
  }

  // -------------------------------------------------------------
  // LAYER 2: 3 FLOATING PHONES ROW (Lowered & Offset)
  // -------------------------------------------------------------
  Widget _buildThreePhonesRow(double stageWidth, double stageHeight, bool isDark) {
    final phoneHeight = (stageHeight * 0.74).clamp(230.0, 370.0);
    final phoneWidth = phoneHeight * (370.0 / 750.0);

    return SizedBox(
      height: phoneHeight + 20,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // 1. LEFT PHONE: Hog Raiser (1st, left)
          Positioned(
            left: (stageWidth * 0.18) - (phoneWidth * 0.5),
            bottom: 0,
            child: _buildPhoneCard(
              'assets/landing/phone_hog_raiser.webp',
              phoneWidth,
              phoneHeight,
              isDark,
            ),
          ),

          // 3. RIGHT PHONE: Partner Investor (3rd, right)
          Positioned(
            right: (stageWidth * 0.18) - (phoneWidth * 0.5),
            bottom: 0,
            child: _buildPhoneCard(
              'assets/landing/phone_partner_investor.webp',
              phoneWidth,
              phoneHeight,
              isDark,
            ),
          ),

          // 2. CENTER PHONE: Cashier (2nd, middle, slightly in front)
          Positioned(
            bottom: 10,
            child: _buildPhoneCard(
              'assets/landing/phone_cashier.webp',
              phoneWidth * 1.04,
              phoneHeight * 1.04,
              isDark,
              isCenter: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneCard(
    String assetPath,
    double width,
    double height,
    bool isDark, {
    bool isCenter = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.18),
            blurRadius: isCenter ? 26 : 18,
            offset: Offset(0, isCenter ? 12 : 8),
            spreadRadius: isCenter ? 1 : 0,
          ),
        ],
      ),
      child: Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildSidebarItem(
    IconData icon,
    String label,
    bool isActive,
    Color activeBg,
    Color textDark,
    Color textMuted,
    bool isCompact,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
      decoration: BoxDecoration(
        color: isActive ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 11,
            color: isActive ? const Color(0xFF0284C7) : textMuted,
          ),
          if (!isCompact) ...[
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? const Color(0xFF0284C7) : textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    String title,
    String value,
    Color bg,
    Color border,
    Color textDark,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
              color: textMuted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubAllocationCard(
    String title,
    String value,
    Color bg,
    Color border,
    Color textDark,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 7,
              fontWeight: FontWeight.w700,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }
}
