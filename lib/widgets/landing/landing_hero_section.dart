import 'dart:ui' show ImageFilter;
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
  // RIGHT: MULTI-PLATFORM ECOSYSTEM VISUAL (Image 2 Mockup: Windows Dark Chrome Admin + 3 Theme-Synced Phones)
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
        final stageHeight = (stageWidth / 1.34).clamp(320.0, 520.0);

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
                        ? Colors.black.withValues(alpha: 0.65)
                        : const Color(0xFF18314F).withValues(alpha: 0.16),
                    blurRadius: 36,
                    offset: const Offset(0, 16),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // LAYER 0: AMBIENT VIBRANT GLOW MESH (Seen through the admin web opacity)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    const Color(0xFF0369A1).withValues(alpha: 0.20),
                                    const Color(0xFF0F172A),
                                    const Color(0xFF0D9488).withValues(alpha: 0.14),
                                  ]
                                : [
                                    const Color(0xFFBAE6FD).withValues(alpha: 0.40),
                                    const Color(0xFFF0F9FF),
                                    const Color(0xFFBBF7D0).withValues(alpha: 0.25),
                                  ],
                          ),
                        ),
                      ),
                    ),

                    // Ambient highlight circles for glassmorphic depth
                    Positioned(
                      top: 40,
                      right: 30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.18 : 0.25),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 60,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.14 : 0.18),
                        ),
                      ),
                    ),

                    // LAYER 1: ADMIN WEB DASHBOARD (Translucent Opacity + Windows Dark Chrome)
                    Positioned.fill(
                      child: _buildAdminWebWidget(isDark, stageWidth, stageHeight),
                    ),

                    // LAYER 2: 3 FLOATING PHONES (Left: Partner, Center: Cashier, Right: Raiser)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -stageHeight * 0.08,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeInOut,
                        opacity: _isPeekingAdmin ? 0.15 : 1.0,
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
                        opacity: _isPeekingAdmin ? 0.95 : 0.80,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F1724).withValues(alpha: 0.92)
                                : Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF28354A)
                                  : const Color(0xFFCBD5E1),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
                              const SizedBox(width: 4.5),
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
  // LAYER 1: ADMIN WEB DASHBOARD (Windows Dark Chrome + Translucent Body)
  // -------------------------------------------------------------
  Widget _buildAdminWebWidget(bool isDark, double stageWidth, double stageHeight) {
    // Opacity on admin web so the background context shines through
    final canvasBg = isDark
        ? const Color(0xFF0A101D).withValues(alpha: 0.84)
        : const Color(0xFFF8FAFC).withValues(alpha: 0.86);
    final sidebarBg = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.88)
        : Colors.white.withValues(alpha: 0.90);
    final cardBg = isDark
        ? const Color(0xFF152238).withValues(alpha: 0.84)
        : Colors.white.withValues(alpha: 0.88);
    final cardBorder = isDark
        ? const Color(0xFF24364F).withValues(alpha: 0.9)
        : const Color(0xFFE2E8F0);
    final textDark = isDark ? const Color(0xFFECF2FF) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final activeNavBg = isDark ? const Color(0xFF0369A1).withValues(alpha: 0.25) : const Color(0xFFE0F2FE);

    final isCompact = stageWidth < 460;
    final sidebarWidth = isCompact ? 36.0 : 132.0;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        color: canvasBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. WINDOWS / BRAVE STYLE DARK BROWSER BAR (Matching Image 2)
            _buildWindowsBrowserBar(isDark),

            // 2. WEB APP HEADER BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sidebarBg,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.menu_rounded, size: 14, color: textDark),
                      const SizedBox(width: 8),
                      Image.asset(
                        'assets/piggytrunk_logo.png',
                        width: 14,
                        height: 14,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.pets_rounded,
                          size: 13,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'PiggyTrunk',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.notifications_none_rounded, size: 14, color: textMuted),
                      const SizedBox(width: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: activeNavBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                            width: 0.6,
                          ),
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
                              const SizedBox(width: 4.5),
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
                                      fontSize: 5.5,
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

            // 3. WEB APP BODY (Sidebar + Dashboard Canvas)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Sidebar (Matching Image 2 with Mobile App, Theme, Settings, Sign Out)
                  Container(
                    width: sidebarWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
                    decoration: BoxDecoration(
                      color: sidebarBg,
                      border: Border(
                        right: BorderSide(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          width: 0.8,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSidebarItem(Icons.grid_view_rounded, 'Dashboard', true, activeNavBg, textDark, textMuted, isCompact),
                        _buildSidebarItem(Icons.pets_rounded, 'Hog Raiser', false, activeNavBg, textDark, textMuted, isCompact),
                        _buildSidebarItem(Icons.people_outline_rounded, 'User Approvals', false, activeNavBg, textDark, textMuted, isCompact),
                        _buildSidebarItem(Icons.layers_outlined, 'Batch Management', false, activeNavBg, textDark, textMuted, isCompact),
                        _buildSidebarItem(Icons.trending_up_rounded, 'Investment Management', false, activeNavBg, textDark, textMuted, isCompact),
                        _buildSidebarItem(Icons.inventory_2_outlined, 'Inventory', false, activeNavBg, textDark, textMuted, isCompact),
                        _buildSidebarItem(Icons.point_of_sale_rounded, 'POS', false, activeNavBg, textDark, textMuted, isCompact),
                        _buildSidebarItem(Icons.phone_android_rounded, 'Mobile App', false, activeNavBg, textDark, textMuted, isCompact),
                        const Spacer(),
                        _buildSidebarItem(Icons.wb_sunny_outlined, 'Theme', false, activeNavBg, textDark, textMuted, isCompact),
                        _buildSidebarItem(Icons.settings_outlined, 'Settings', false, activeNavBg, textDark, textMuted, isCompact),
                        _buildSidebarItem(Icons.logout_rounded, 'Sign out', false, activeNavBg, textDark, textMuted, isCompact),
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
                                    fontSize: 16,
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
                                          isDark
                                              ? const Color(0xFF111C2E).withValues(alpha: 0.8)
                                              : const Color(0xFFF1F5F9).withValues(alpha: 0.9),
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
                                          isDark
                                              ? const Color(0xFF111C2E).withValues(alpha: 0.8)
                                              : const Color(0xFFF1F5F9).withValues(alpha: 0.9),
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
      ),
    );
  }

  // -------------------------------------------------------------
  // WINDOWS / BRAVE DARK BROWSER BAR (Matching Image 2)
  // -------------------------------------------------------------
  Widget _buildWindowsBrowserBar(bool isDark) {
    const barDarkBg = Color(0xFF151821);
    const navDarkBg = Color(0xFF11131A);
    const tabActiveBg = Color(0xFF222735);
    const urlPillBg = Color(0xFF1C202C);

    return Container(
      decoration: const BoxDecoration(
        color: barDarkBg,
        border: Border(bottom: BorderSide(color: Color(0xFF242B3B), width: 0.8)),
      ),
      child: Column(
        children: [
          // Row 1: Tab + Window Controls (Minimize, Maximize, Close)
          Padding(
            padding: const EdgeInsets.only(left: 6, right: 6, top: 4, bottom: 2),
            child: Row(
              children: [
                // Active Tab: Piggy Trunk Admin
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: tabActiveBg,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/piggytrunk_logo.png',
                        width: 11,
                        height: 11,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.pets_rounded,
                          size: 10,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Piggy Trunk Admin',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Icon(Icons.close_rounded, size: 9, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.add_rounded, size: 12, color: Color(0xFF64748B)),

                const Spacer(),

                // Windows Window Controls: Minimise, Maximise, Close
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 14,
                      alignment: Alignment.center,
                      child: Container(
                        width: 7,
                        height: 1.2,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 18,
                      height: 14,
                      alignment: Alignment.center,
                      child: Container(
                        width: 7.5,
                        height: 7.5,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF94A3B8), width: 1.1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const SizedBox(
                      width: 18,
                      height: 14,
                      child: Center(
                        child: Icon(Icons.close_rounded, size: 10.5, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Row 2: Nav arrows, URL Bar, Extensions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            color: navDarkBg,
            child: Row(
              children: [
                const Icon(Icons.arrow_back_rounded, size: 10.5, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, size: 10.5, color: Color(0xFF475569)),
                const SizedBox(width: 6),
                const Icon(Icons.refresh_rounded, size: 10.5, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),

                // Address Bar
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: urlPillBg,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFF283144), width: 0.6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_rounded, size: 8.5, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'admin.piggytrunk.site/dashboard',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.shield_outlined, size: 9, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Browser Extensions & Menu
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.extension_outlined, size: 10, color: Color(0xFF94A3B8)),
                    SizedBox(width: 6),
                    Icon(Icons.more_vert_rounded, size: 10, color: Color(0xFF94A3B8)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // LAYER 2: 3 FLOATING PHONES (Left: Partner, Center: Cashier, Right: Raiser)
  // -------------------------------------------------------------
  Widget _buildThreePhonesRow(double stageWidth, double stageHeight, bool isDark) {
    final phoneHeight = (stageHeight * 0.77).clamp(240.0, 385.0);
    // Standard mobile aspect ratio
    final phoneWidth = phoneHeight * (225.0 / 460.0);

    return SizedBox(
      height: phoneHeight + 24,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // 1. LEFT PHONE: Partner Investor ("rej") - Tilted Counter-Clockwise
          Positioned(
            left: (stageWidth * 0.5) - (phoneWidth * 1.34),
            bottom: 4,
            child: _buildPhoneFrame(
              width: phoneWidth,
              height: phoneHeight,
              isDark: isDark,
              rotation: -0.09,
              child: _buildPhonePartnerInvestor(isDark),
            ),
          ),

          // 2. RIGHT PHONE: Hog Raiser ("Just Rejie") - Tilted Clockwise
          Positioned(
            right: (stageWidth * 0.5) - (phoneWidth * 1.34),
            bottom: 4,
            child: _buildPhoneFrame(
              width: phoneWidth,
              height: phoneHeight,
              isDark: isDark,
              rotation: 0.09,
              child: _buildPhoneHogRaiser(isDark),
            ),
          ),

          // 3. CENTER PHONE: Cashier ("maryazxc") - Upright & In Front
          Positioned(
            bottom: 12,
            child: _buildPhoneFrame(
              width: phoneWidth * 1.05,
              height: phoneHeight * 1.05,
              isDark: isDark,
              rotation: 0.0,
              isCenter: true,
              child: _buildPhoneCashier(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // Universal Phone Device Frame (With FittedBox for Vector Scalability)
  Widget _buildPhoneFrame({
    required Widget child,
    required double width,
    required double height,
    required bool isDark,
    double rotation = 0,
    bool isCenter = false,
  }) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(width * 0.12),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 2.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.22),
              blurRadius: isCenter ? 30 : 20,
              offset: Offset(0, isCenter ? 14 : 9),
              spreadRadius: isCenter ? 2 : 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(width * 0.11),
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 225,
              height: 460,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  // Universal Smartphone Status Bar
  Widget _buildPhoneStatusBar(bool isDark, String time) {
    final textColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            time,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          // Front camera punch-hole
          Container(
            width: 7.5,
            height: 7.5,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B132B) : const Color(0xFF1E293B),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFF475569),
                width: 0.8,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.signal_cellular_alt_rounded, size: 8.5, color: textColor),
              const SizedBox(width: 3),
              Icon(Icons.wifi_rounded, size: 8.5, color: textColor),
              const SizedBox(width: 3),
              Icon(Icons.battery_5_bar_rounded, size: 9, color: textColor),
            ],
          ),
        ],
      ),
    );
  }

  // Universal Smartphone App Header
  Widget _buildPhoneHeader({
    required String greeting,
    required String name,
    required bool isDark,
  }) {
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final bellBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final bellBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                ),
              ),
              Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
            ],
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: bellBg,
              shape: BoxShape.circle,
              border: Border.all(color: bellBorder, width: 0.6),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 12,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // PHONE 1: PARTNER INVESTOR ("rej")
  // -------------------------------------------------------------
  Widget _buildPhonePartnerInvestor(bool isDark) {
    final bg = isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC);

    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPhoneStatusBar(isDark, '01:38'),
          _buildPhoneHeader(
            greeting: 'Hello Partner Investor,',
            name: 'rej',
            isDark: isDark,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPartnerPortfolioCard(isDark),
                  const SizedBox(height: 8),
                  _buildPartnerQuickActions(isDark),
                  const SizedBox(height: 10),
                  _buildSectionHeader('Investment Opportunities', 'See All >', isDark),
                  const SizedBox(height: 6),
                  _buildPartnerOpportunityCard(
                    batch: 'BATCH-2026-3',
                    raiser: 'Raiser: ... • Fattening',
                    stage: 'N/A Stage',
                    stageColor: const Color(0xFF10B981),
                    hogs: '0 Hogs Assigned',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 5),
                  _buildPartnerOpportunityCard(
                    batch: 'BATCH-2026-4',
                    raiser: 'Raiser: Elisa De Vera • Fattening',
                    stage: 'Booster Stage',
                    stageColor: const Color(0xFF0284C7),
                    hogs: '3 Hogs Assigned',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildSectionHeader('Recent Activities', 'See All >', isDark),
                ],
              ),
            ),
          ),
          _buildPartnerBottomNav(isDark),
        ],
      ),
    );
  }

  Widget _buildPartnerPortfolioCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C192E), Color(0xFF172C4C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bar_chart_rounded, size: 9, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 3),
                  Text(
                    'PORTFOLIO VALUE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Ready to Invest',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 6,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6EE7B7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '₱ 0.00',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Start funding raisers & earn passive returns',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 6.5,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 7),
          Container(
            height: 0.6,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPartnerMiniMetric(Icons.layers_outlined, 'Batches', '0'),
              _buildPartnerMiniMetric(Icons.people_outline, 'Raisers', '04'),
              _buildPartnerMiniMetric(Icons.pets_rounded, 'Hogs Funded', '9'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerMiniMetric(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 8.5, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 6,
                color: const Color(0xFF94A3B8),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPartnerQuickActions(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Row(
      children: [
        Expanded(
          child: _buildPartnerActionItem(
            icon: Icons.add_card_rounded,
            iconColor: const Color(0xFF10B981),
            title: 'Fund Batch',
            subtitle: 'Invest Now',
            bg: cardBg,
            border: border,
            textDark: textDark,
            textMuted: textMuted,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _buildPartnerActionItem(
            icon: Icons.history_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: 'Recent Act...',
            subtitle: 'Live updates',
            bg: cardBg,
            border: border,
            textDark: textDark,
            textMuted: textMuted,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _buildPartnerActionItem(
            icon: Icons.person_outline_rounded,
            iconColor: const Color(0xFF0284C7),
            title: 'Profile',
            subtitle: 'Account Info',
            bg: cardBg,
            border: border,
            textDark: textDark,
            textMuted: textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerActionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color bg,
    required Color border,
    required Color textDark,
    required Color textMuted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 6,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerOpportunityCard({
    required String batch,
    required String raiser,
    required String stage,
    required Color stageColor,
    required String hogs,
    required bool isDark,
  }) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.pets_rounded, size: 9, color: stageColor),
                  const SizedBox(width: 3),
                  Text(
                    batch,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: BoxDecoration(
                  color: stageColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  stage,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 6,
                    fontWeight: FontWeight.w700,
                    color: stageColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            raiser,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 6.5,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hogs,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 6.5,
                  color: textMuted,
                ),
              ),
              Text(
                'View Details >',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 6.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0284C7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerBottomNav(bool isDark) {
    final navBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final border = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final activeColor = const Color(0xFF0284C7);
    final inactiveColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: border, width: 0.6)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPhoneNavItem(Icons.home_filled, 'Home', true, activeColor, inactiveColor),
              _buildPhoneNavItem(Icons.trending_up_rounded, 'Investment', false, activeColor, inactiveColor),
              _buildPhoneNavItem(Icons.receipt_long_rounded, 'Activities', false, activeColor, inactiveColor),
              _buildPhoneNavItem(Icons.person_outline_rounded, 'Profile', false, activeColor, inactiveColor),
            ],
          ),
          const SizedBox(height: 2),
          Container(
            width: 36,
            height: 2.2,
            decoration: BoxDecoration(
              color: inactiveColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // PHONE 2: CASHIER ("maryazxc")
  // -------------------------------------------------------------
  Widget _buildPhoneCashier(bool isDark) {
    final bg = isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC);

    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPhoneStatusBar(isDark, '01:38'),
          _buildPhoneHeader(
            greeting: 'Hello Cashier,',
            name: 'maryazxc',
            isDark: isDark,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCashierStatsGrid(isDark),
                  const SizedBox(height: 8),
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF18314F),
                    ),
                  ),
                  const SizedBox(height: 5),
                  _buildCashierQuickActions(isDark),
                  const SizedBox(height: 9),
                  _buildCashierAlertHeader(isDark),
                  const SizedBox(height: 5),
                  _buildCashierAlertItem('BEXAN Sp', '1 units left • Vitamins', Colors.red, isDark),
                  const SizedBox(height: 4),
                  _buildCashierAlertItem('PIGROLAC Early Wean SUPERSTART', '6 units left • Feeds', Colors.amber.shade700, isDark),
                  const SizedBox(height: 8),
                  _buildSectionHeader('Fast-Moving Products', 'Point of Sale (POS) ->', isDark),
                  const SizedBox(height: 5),
                  _buildCashierProductsRow(isDark),
                ],
              ),
            ),
          ),
          _buildCashierBottomNav(isDark),
        ],
      ),
    );
  }

  Widget _buildCashierStatsGrid(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCashierStatTile(
                icon: Icons.payments_outlined,
                iconColor: const Color(0xFF10B981),
                value: '₱0.00',
                label: "Today's Total Sales",
                bg: cardBg,
                border: border,
                textDark: textDark,
                textMuted: textMuted,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildCashierStatTile(
                icon: Icons.inventory_2_outlined,
                iconColor: const Color(0xFF0284C7),
                value: '12 Items',
                label: 'In Stock Items',
                bg: cardBg,
                border: border,
                textDark: textDark,
                textMuted: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildCashierStatTile(
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFEF4444),
                value: '2 Items',
                label: 'Low Stock Alerts',
                bg: cardBg,
                border: border,
                textDark: textDark,
                textMuted: textMuted,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildCashierStatTile(
                icon: Icons.hourglass_empty_rounded,
                iconColor: const Color(0xFFF59E0B),
                value: '1 Pending',
                label: 'Pending Requests',
                bg: cardBg,
                border: border,
                textDark: textDark,
                textMuted: textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCashierStatTile({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required Color bg,
    required Color border,
    required Color textDark,
    required Color textMuted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 11, color: iconColor),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 6,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashierQuickActions(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);

    return Row(
      children: [
        _buildCashierActionButton(Icons.point_of_sale_rounded, const Color(0xFF0284C7), 'Open POS', cardBg, border, textDark),
        const SizedBox(width: 4),
        _buildCashierActionButton(Icons.inventory_rounded, const Color(0xFF10B981), 'Manage Inv', cardBg, border, textDark),
        const SizedBox(width: 4),
        _buildCashierActionButton(Icons.alt_route_rounded, const Color(0xFFF59E0B), 'Stock Alloc', cardBg, border, textDark),
        const SizedBox(width: 4),
        _buildCashierActionButton(Icons.receipt_long_rounded, const Color(0xFF8B5CF6), 'Sales Act.', cardBg, border, textDark),
      ],
    );
  }

  Widget _buildCashierActionButton(
    IconData icon,
    Color iconColor,
    String label,
    Color bg,
    Color border,
    Color textDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border, width: 0.6),
        ),
        child: Column(
          children: [
            Icon(icon, size: 11, color: iconColor),
            const SizedBox(height: 2.5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 6,
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashierAlertHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Low Stock Alerts',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF18314F),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '2',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 6.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        Text(
          'Manage Inventory ->',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 6.5,
            color: const Color(0xFF0284C7),
          ),
        ),
      ],
    );
  }

  Widget _buildCashierAlertItem(String title, String subtitle, Color alertColor, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 0.6),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: alertColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.priority_high_rounded, size: 8, color: alertColor),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 5.5,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: border, width: 0.5),
            ),
            child: Text(
              'Restock',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 6,
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashierProductsRow(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Row(
      children: [
        _buildCashierProductCard('Apralyte', '₱20.00', Colors.red.shade400, cardBg, border, textDark, textMuted),
        const SizedBox(width: 5),
        _buildCashierProductCard('BEXAN Sp', '₱200.00', Colors.amber.shade600, cardBg, border, textDark, textMuted),
        const SizedBox(width: 5),
        _buildCashierProductCard('LATIGO-100', '₱20.00', Colors.deepOrange.shade400, cardBg, border, textDark, textMuted),
      ],
    );
  }

  Widget _buildCashierProductCard(
    String name,
    String price,
    Color placeholderColor,
    Color bg,
    Color border,
    Color textDark,
    Color textMuted,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border, width: 0.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 22,
              width: double.infinity,
              decoration: BoxDecoration(
                color: placeholderColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(Icons.medication_liquid_rounded, size: 12, color: placeholderColor),
            ),
            const SizedBox(height: 3),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 6.5,
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
            ),
            Text(
              price,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 6,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashierBottomNav(bool isDark) {
    final navBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final border = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final activeColor = const Color(0xFF0284C7);
    final inactiveColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: border, width: 0.6)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPhoneNavItem(Icons.home_filled, 'Home', true, activeColor, inactiveColor),
              _buildPhoneNavItem(Icons.assignment_outlined, 'Request', false, activeColor, inactiveColor),
              _buildPhoneNavItem(Icons.inventory_2_outlined, 'Inventory', false, activeColor, inactiveColor),
              _buildPhoneNavItem(Icons.point_of_sale_outlined, 'POS', false, activeColor, inactiveColor),
              _buildPhoneNavItem(Icons.person_outline_rounded, 'Profile', false, activeColor, inactiveColor),
            ],
          ),
          const SizedBox(height: 2),
          Container(
            width: 36,
            height: 2.2,
            decoration: BoxDecoration(
              color: inactiveColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // PHONE 3: HOG RAISER ("Just Rejie")
  // -------------------------------------------------------------
  Widget _buildPhoneHogRaiser(bool isDark) {
    final bg = isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC);

    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPhoneStatusBar(isDark, '01:35'),
          _buildPhoneHeader(
            greeting: 'Hello Hog Raiser,',
            name: 'Just Rejie',
            isDark: isDark,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHogRaiserInvestmentCard(isDark),
                  const SizedBox(height: 8),
                  _buildHogRaiserMetricsGrid(isDark),
                  const SizedBox(height: 8),
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF18314F),
                    ),
                  ),
                  const SizedBox(height: 5),
                  _buildHogRaiserQuickActions(isDark),
                  const SizedBox(height: 9),
                  _buildHogRaiserFeedsNotice(isDark),
                ],
              ),
            ),
          ),
          _buildHogRaiserBottomNav(isDark),
        ],
      ),
    );
  }

  Widget _buildHogRaiserInvestmentCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C192E), Color(0xFF172C4C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'NO BATCH ASSIGNED',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 6,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Pending Batch',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 6,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFCD34D),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL CURRENT INVESTMENT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 6.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              Text(
                'View Breakdown',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 6.5,
                  color: const Color(0xFF38BDF8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₱0',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.add_rounded, size: 13, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Container(
            height: 0.6,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPartnerMiniMetric(Icons.pets_rounded, 'Hogs', '0'),
              _buildPartnerMiniMetric(Icons.room_service_outlined, 'Stage', 'Unassigned'),
              _buildPartnerMiniMetric(Icons.hourglass_empty_rounded, 'Pending', '0'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHogRaiserMetricsGrid(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCashierStatTile(
                icon: Icons.pets_rounded,
                iconColor: const Color(0xFFEC4899),
                value: '0 Hogs',
                label: 'Total Hogs',
                bg: cardBg,
                border: border,
                textDark: textDark,
                textMuted: textMuted,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildCashierStatTile(
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFF10B981),
                value: '100% Good',
                label: 'Hog Health',
                bg: cardBg,
                border: border,
                textDark: textDark,
                textMuted: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildCashierStatTile(
                icon: Icons.assignment_outlined,
                iconColor: const Color(0xFFF59E0B),
                value: '0 Pending',
                label: 'Stock Requests',
                bg: cardBg,
                border: border,
                textDark: textDark,
                textMuted: textMuted,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildCashierStatTile(
                icon: Icons.restaurant_rounded,
                iconColor: const Color(0xFF0284C7),
                value: 'Unassigned',
                label: 'Current Feeds Stage',
                bg: cardBg,
                border: border,
                textDark: textDark,
                textMuted: textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHogRaiserQuickActions(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);

    return Row(
      children: [
        _buildCashierActionButton(Icons.assignment_outlined, const Color(0xFF0284C7), 'Request', cardBg, border, textDark),
        const SizedBox(width: 4),
        _buildCashierActionButton(Icons.report_problem_outlined, const Color(0xFFEF4444), 'Report', cardBg, border, textDark),
        const SizedBox(width: 4),
        _buildCashierActionButton(Icons.pets_rounded, const Color(0xFF10B981), 'My Hogs', cardBg, border, textDark),
        const SizedBox(width: 4),
        _buildCashierActionButton(Icons.history_rounded, const Color(0xFF8B5CF6), 'History', cardBg, border, textDark),
      ],
    );
  }

  Widget _buildHogRaiserFeedsNotice(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 0.6),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline_rounded, size: 10, color: textMuted),
            const SizedBox(width: 4),
            Text(
              'No feeds stage assigned.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 7,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHogRaiserBottomNav(bool isDark) {
    final navBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final border = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final activeColor = const Color(0xFF0284C7);
    final inactiveColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: border, width: 0.6)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPhoneNavItem(Icons.assignment_outlined, 'Request', false, activeColor, inactiveColor),
              _buildPhoneNavItem(Icons.home_filled, 'Home', true, activeColor, inactiveColor),
              _buildPhoneNavItem(Icons.person_outline_rounded, 'Profile', false, activeColor, inactiveColor),
            ],
          ),
          const SizedBox(height: 2),
          Container(
            width: 36,
            height: 2.2,
            decoration: BoxDecoration(
              color: inactiveColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // REUSABLE MICRO WIDGETS
  // -------------------------------------------------------------
  Widget _buildSectionHeader(String title, String action, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF18314F),
          ),
        ),
        Text(
          action,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 6.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0284C7),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneNavItem(
    IconData icon,
    String label,
    bool isActive,
    Color activeColor,
    Color inactiveColor,
  ) {
    final color = isActive ? activeColor : inactiveColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(height: 1.5),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 5.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
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
                  fontSize: 7.5,
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
