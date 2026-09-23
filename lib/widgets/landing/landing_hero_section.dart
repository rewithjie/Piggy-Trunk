import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import 'scroll_reveal.dart';

class LandingHeroSection extends StatelessWidget {
  final VoidCallback? onContactTap;
  final VoidCallback? onLearnMoreTap;

  const LandingHeroSection({
    super.key,
    this.onContactTap,
    this.onLearnMoreTap,
  });

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
        final verticalPadding = isMobile ? 32.0 : 56.0;

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
                        const SizedBox(width: 48),

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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151F2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF243B53) : const Color(0xFFCBD5E1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.55)
                : const Color(0xFF18314F).withValues(alpha: 0.10),
            blurRadius: 32,
            offset: const Offset(0, 14),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.5),
        child: AspectRatio(
          aspectRatio: 1600 / 1128,
          child: Image.asset(
            'assets/landing/hero_ecosystem_showcase.webp',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
