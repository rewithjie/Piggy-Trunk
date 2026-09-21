import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';

class LandingFeaturesSection extends StatelessWidget {
  const LandingFeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    final titleColor = isDark ? PiggyTrunkTheme.ptTextDark : PiggyTrunkTheme.ptText;
    final subtitleColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;
    final sectionBg = isDark ? PiggyTrunkTheme.ptSurfaceDark : PiggyTrunkTheme.ptSurface;
    final borderDivider = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final horizontalPadding = availableWidth >= 1200
            ? 64.0
            : (availableWidth >= 768 ? 32.0 : 16.0);
        final verticalPadding = isMobile ? 36.0 : 64.0;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: sectionBg,
            border: Border.symmetric(
              horizontal: BorderSide(color: borderDivider, width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
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
                    child: Text(
                      'WHY PIGGY TRUNK?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? PiggyTrunkTheme.ptTextDark : PiggyTrunkTheme.ptPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    'Next-Generation Swine Farm Intelligence',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 24 : 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Text(
                      'We eliminate tedious paper records to deliver accurate, auditable, and data-driven swine farm operations at every stage.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 13.5 : 15.5,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        color: subtitleColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Fluid Feature Grid
                  LayoutBuilder(
                    builder: (context, gridConstraints) {
                      final isTwoColumn = gridConstraints.maxWidth >= 680;
                      final cardWidth = isTwoColumn
                          ? (gridConstraints.maxWidth - 20) / 2
                          : gridConstraints.maxWidth;

                      return Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          _buildFeatureCard(
                            context,
                            cardWidth: cardWidth,
                            icon: Icons.cloud_sync_rounded,
                            color: const Color(0xFF3B82F6),
                            title: 'Real-time Cloud Synchronization',
                            description:
                                'All feed records, medications, and mortality logs are instantly synchronized with our secure Supabase backend for immediate team oversight.',
                            isDark: isDark,
                          ),
                          _buildFeatureCard(
                            context,
                            cardWidth: cardWidth,
                            icon: Icons.account_balance_wallet_rounded,
                            color: const Color(0xFF10B981),
                            title: '100% Transparent Financial Ledger',
                            description:
                                'Every expense has an itemized audit trail and digital timestamp, giving farm owners and partners total confidence and zero guesswork during harvest payouts.',
                            isDark: isDark,
                          ),
                          _buildFeatureCard(
                            context,
                            cardWidth: cardWidth,
                            icon: Icons.health_and_safety_rounded,
                            color: const Color(0xFF0284C7),
                            title: 'Herd Health & Mortality Prevention',
                            description:
                                'Immediate alerts when swine display early illness symptoms so veterinary treatments and vaccines can be applied before diseases spread.',
                            isDark: isDark,
                          ),
                          _buildFeatureCard(
                            context,
                            cardWidth: cardWidth,
                            icon: Icons.speed_rounded,
                            color: const Color(0xFF8B5CF6),
                            title: 'Lightweight & Data-Efficient',
                            description:
                                'Optimized for everyday Android smartphones in rural farm environments. Fast load times with resilient caching even on low mobile bandwidth.',
                            isDark: isDark,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required double cardWidth,
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required bool isDark,
  }) {
    final cardBg = isDark ? PiggyTrunkTheme.ptSurfaceDark : PiggyTrunkTheme.ptSurface;
    final cardBorder = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
    final titleColor = isDark ? PiggyTrunkTheme.ptTextDark : PiggyTrunkTheme.ptText;
    final descColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    color: descColor,
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
