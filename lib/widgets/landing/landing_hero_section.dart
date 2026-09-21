import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';

class LandingHeroSection extends StatefulWidget {
  final VoidCallback onContactTap;
  final VoidCallback onLearnMoreTap;

  const LandingHeroSection({
    super.key,
    required this.onContactTap,
    required this.onLearnMoreTap,
  });

  @override
  State<LandingHeroSection> createState() => _LandingHeroSectionState();
}

class _LandingHeroSectionState extends State<LandingHeroSection> {
  // Mobile App screen index: 0: Raiser, 1: Partner, 2: Restock
  int _activePhoneScreenIndex = 0;

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
                          flex: 6,
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

                        // RIGHT: SPACIOUS DUAL-PLATFORM VISUAL (Phone + Admin Web)
                        Expanded(
                          flex: 6,
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
                        const SizedBox(height: 40),
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
  // LEFT: HERO COPY (Exact text from Image 1, NO PINK)
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
    final isMobile = Responsive.isMobile(context);
    final headlineSize = availableWidth >= 1200
        ? 38.0
        : (availableWidth >= 768 ? 30.0 : 25.0);
    final subtitleSize = availableWidth >= 1200
        ? 15.0
        : (availableWidth >= 768 ? 14.0 : 13.5);

    // Official PiggyTrunk Brand Navy (White in Dark Mode, Navy in Light Mode)
    final primaryButtonBg = isDark ? Colors.white : const Color(0xFF18314F);
    final primaryButtonFg = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Column(
      crossAxisAlignment:
          isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        // Tagline Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: pillBorder),
          ),
          child: Text(
            'HOG RAISING MANAGEMENT & MONITORING SYSTEM',
            textAlign: isCentered ? TextAlign.center : TextAlign.left,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isDark ? PiggyTrunkTheme.ptPrimaryDark : const Color(0xFF18314F),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Headline
        Text(
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
        const SizedBox(height: 16),

        // Paragraph 1
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

        // Paragraph 2
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
        const SizedBox(height: 26),

        // Action Buttons: [ Contact Us ]  [ Learn More ]
        Wrap(
          alignment: isCentered ? WrapAlignment.center : WrapAlignment.start,
          spacing: 14,
          runSpacing: 12,
          children: [
            // Contact Us
            FilledButton.icon(
              onPressed: widget.onContactTap,
              style: FilledButton.styleFrom(
                backgroundColor: primaryButtonBg,
                foregroundColor: primaryButtonFg,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 22 : 28,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.mail_outline_rounded, size: 17),
              label: Text(
                'Contact Us',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Learn More
            OutlinedButton.icon(
              onPressed: widget.onLearnMoreTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? PiggyTrunkTheme.ptTextDark : const Color(0xFF18314F),
                side: BorderSide(
                  color: isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder,
                  width: 1.2,
                ),
                backgroundColor: isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 26,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.arrow_downward_rounded, size: 17),
              label: Text(
                'Learn More',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? PiggyTrunkTheme.ptTextDark : const Color(0xFF18314F),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // RIGHT: SPACIOUS DUAL-PLATFORM VISUAL (Admin Web + Phone)
  // -------------------------------------------------------------
  Widget _buildRightSideVisual(
    BuildContext context, {
    required bool isDark,
    required double availableWidth,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stageWidth = constraints.maxWidth;
            final isWideStage = stageWidth >= 520;

            if (isWideStage) {
              return SizedBox(
                height: 480,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  clipBehavior: Clip.none,
                  children: [
                    // Admin Web Browser Mock (Backdrop, left)
                    Positioned(
                      left: 0,
                      top: 10,
                      child: SizedBox(
                        width: stageWidth * 0.72,
                        child: _buildWebBrowserCard(isDark, width: stageWidth * 0.72, height: 420),
                      ),
                    ),

                    // Mobile Phone Mockup (Front, right overlapping with depth)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildPhoneSubTabs(isDark),
                          const SizedBox(height: 8),
                          _buildPhoneMockup(
                            isDark,
                            width: 225,
                            height: 430,
                            hasShadow: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // Narrow screens: Stacked smoothly
              return Column(
                children: [
                  _buildWebBrowserCard(isDark, width: double.infinity, height: 360),
                  const SizedBox(height: 24),
                  _buildPhoneSubTabs(isDark),
                  const SizedBox(height: 10),
                  _buildPhoneMockup(isDark, width: 250, height: 480),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildPhoneSubTabs(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPhonePillItem(0, '🐷 Raiser', isDark),
          _buildPhonePillItem(1, '💼 Partner', isDark),
          _buildPhonePillItem(2, '📦 Stock', isDark),
        ],
      ),
    );
  }

  Widget _buildPhonePillItem(int index, String label, bool isDark) {
    final isSelected = _activePhoneScreenIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activePhoneScreenIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2563EB) : const Color(0xFF18314F))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // ADMIN WEB BROWSER CARD
  // -------------------------------------------------------------
  Widget _buildWebBrowserCard(bool isDark, {required double width, required double height}) {
    final browserFrameBg = isDark ? const Color(0xFF151F2E) : const Color(0xFFE2E8F0);
    final browserBorder = isDark ? const Color(0xFF28354A) : const Color(0xFFCBD5E1);
    final canvasBg = isDark ? const Color(0xFF0F1724) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textDark = isDark ? Colors.white : const Color(0xFF18314F);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: browserFrameBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: browserBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Browser Window Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: browserFrameBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              border: Border(bottom: BorderSide(color: browserBorder)),
            ),
            child: Row(
              children: [
                Row(
                  children: [
                    Container(width: 8.5, height: 8.5, decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Container(width: 8.5, height: 8.5, decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Container(width: 8.5, height: 8.5, decoration: const BoxDecoration(color: Color(0xFF27C93F), shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0B1320) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: browserBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, size: 11, color: isDark ? Colors.white70 : const Color(0xFF18314F)),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'https://piggytrunk.ph/admin/dashboard',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'WEB ADMIN',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Browser Body
          Expanded(
            child: Container(
              color: canvasBg,
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dashboard Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Piggy Trunk Admin Portal',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: textDark,
                              ),
                            ),
                            Text(
                              'Executive Farm Operations & POS Analytics',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE0E7FF),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'Cloud Active',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Metrics Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricMini(
                            'Live Herd',
                            '1,280 Hogs',
                            '4 Active Batches',
                            Icons.inventory_2_outlined,
                            const Color(0xFF0284C7),
                            cardBg,
                            cardBorder,
                            textDark,
                            textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricMini(
                            'POS Sales',
                            '₱148,250',
                            '38 Transactions',
                            Icons.point_of_sale_rounded,
                            const Color(0xFF10B981),
                            cardBg,
                            cardBorder,
                            textDark,
                            textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricMini(
                            'Farm Output',
                            '₱2.45M',
                            '+22.4% vs last mo',
                            Icons.trending_up_rounded,
                            const Color(0xFF8B5CF6),
                            cardBg,
                            cardBorder,
                            textDark,
                            textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Batch Progress Card
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Batch Lifecycle Status • Batch 2026-B',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Finisher Stage (Day 112 • 92.5 kg avg)', style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: textMuted)),
                              Text('84% Complete', style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700, color: textDark)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: 0.84,
                              minHeight: 5,
                              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Feed Stock (Grower Mash): 520 bags', style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: textMuted)),
                              Text('Adequate', style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700, color: const Color(0xFF10B981))),
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
    );
  }

  Widget _buildMetricMini(
    String label,
    String value,
    String sub,
    IconData icon,
    Color iconColor,
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
          Row(
            children: [
              Icon(icon, size: 12, color: iconColor),
              const SizedBox(width: 4),
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 9, color: textMuted, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 3),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: textDark)),
          Text(sub, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 8, color: textMuted)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SMARTPHONE FRAME MOCKUP
  // -------------------------------------------------------------
  Widget _buildPhoneMockup(
    bool isDark, {
    required double width,
    required double height,
    bool hasShadow = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFF1E293B),
          width: 5,
        ),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.2),
                  blurRadius: 24,
                  offset: const Offset(-4, 10),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Container(
          color: const Color(0xFFF4F7FB),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Speaker Notch
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(top: 5, bottom: 3),
                child: Center(
                  child: Container(
                    width: 42,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              // Screen Content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _buildPhoneScreen(_activePhoneScreenIndex),
                ),
              ),

              // Bottom Phone Navigation Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Icon(
                      Icons.home_filled,
                      size: 15,
                      color: _activePhoneScreenIndex == 0
                          ? const Color(0xFF18314F)
                          : const Color(0xFF94A3B8),
                    ),
                    Icon(
                      Icons.trending_up_rounded,
                      size: 15,
                      color: _activePhoneScreenIndex == 1
                          ? const Color(0xFF18314F)
                          : const Color(0xFF94A3B8),
                    ),
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 15,
                      color: _activePhoneScreenIndex == 2
                          ? const Color(0xFF18314F)
                          : const Color(0xFF94A3B8),
                    ),
                    const Icon(Icons.person_outline_rounded, size: 15, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneScreen(int index) {
    switch (index) {
      case 1:
        return _buildPartnerMock();
      case 2:
        return _buildRestockMock();
      default:
        return _buildRaiserMock();
    }
  }

  Widget _buildRaiserMock() {
    return KeyedSubtree(
      key: const ValueKey(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF18314F),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.person_rounded, size: 12, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pedro Farm',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF18314F)),
                        ),
                        Text(
                          'Hog Raiser • Batch 04',
                          style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('LIVE', style: GoogleFonts.plusJakartaSans(fontSize: 7.5, fontWeight: FontWeight.w800, color: const Color(0xFF10B981))),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(7),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF18314F), Color(0xFF243B53)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Batch #04 • Grower Stage', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMiniText('Herd', '120 Hogs'),
                            _buildMiniText('Avg Weight', '48.2 kg'),
                            _buildMiniText('Health', '100%'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Daily Feed Log', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFF18314F))),
                        const SizedBox(height: 4),
                        _buildFeedItem('Morning Feed: 420 kg logged', Icons.check_circle_rounded, const Color(0xFF10B981)),
                        const SizedBox(height: 3),
                        _buildFeedItem('Afternoon Feed: Scheduled', Icons.schedule_rounded, const Color(0xFF0284C7)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerMock() {
    return KeyedSubtree(
      key: const ValueKey(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Partner Portfolio', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF18314F))),
                Text('+22.4% ROI', style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w800, color: const Color(0xFF10B981))),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(7),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18314F),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Allocated Capital', style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 8)),
                        Text('₱250,000.00', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMiniText('Est. Value', '₱306,000'),
                            _buildMiniText('Net Profit', '+₱56,000'),
                            _buildMiniText('Harvest', 'Nov 2026'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestockMock() {
    return KeyedSubtree(
      key: const ValueKey(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Stock Requests', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF18314F))),
                Text('2 Approved', style: GoogleFonts.plusJakartaSans(fontSize: 8.5, fontWeight: FontWeight.w800, color: const Color(0xFF10B981))),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(7),
              child: Column(
                children: [
                  _buildStockTile('Grower Mash - 20 Bags', 'Req #9042 • Approved', const Color(0xFF10B981)),
                  const SizedBox(height: 5),
                  _buildStockTile('Vitamin Supplements', 'Req #9043 • In Transit', const Color(0xFF0284C7)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniText(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontSize: 7)),
        Text(val, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildFeedItem(String title, IconData icon, Color col) {
    return Row(
      children: [
        Icon(icon, size: 11, color: col),
        const SizedBox(width: 4),
        Expanded(
          child: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 8.5, color: const Color(0xFF334155), fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildStockTile(String title, String sub, Color dot) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 8.5, fontWeight: FontWeight.w700, color: const Color(0xFF18314F))),
                Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 7.5, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
        ],
      ),
    );
  }
}
