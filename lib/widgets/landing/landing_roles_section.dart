import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import 'scroll_reveal.dart';

class LandingRolesSection extends StatelessWidget {
  const LandingRolesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    final titleColor = isDark ? PiggyTrunkTheme.ptTextDark : PiggyTrunkTheme.ptText;
    final subtitleColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final horizontalPadding = availableWidth >= 1200
            ? 64.0
            : (availableWidth >= 768 ? 32.0 : 16.0);
        final verticalPadding = isMobile ? 36.0 : 60.0;
        final isThreeColumn = availableWidth >= 1050;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Section Category Badge
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
                      'ROLE-BASED PLATFORM',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark
                            ? PiggyTrunkTheme.ptTextDark
                            : PiggyTrunkTheme.ptPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Section Headline
                  Text(
                    'One App, Purpose-Built for Every Stakeholder',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 24 : 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Section Subtitle
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Text(
                      'Sign in with your verified credentials and the mobile interface dynamically adapts to your specific role in the swine farm ecosystem.',
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

                  // Roles Bento Cards (Fluid 3-column or Stacked with staggered reveal)
                  if (isThreeColumn)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ScrollReveal(
                            delay: const Duration(milliseconds: 100),
                            child: _buildRaiserCard(context, isDark),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: ScrollReveal(
                            delay: const Duration(milliseconds: 200),
                            child: _buildPartnerCard(context, isDark),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: ScrollReveal(
                            delay: const Duration(milliseconds: 300),
                            child: _buildCashierCard(context, isDark),
                          ),
                        ),
                      ],
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Column(
                        children: [
                          ScrollReveal(
                            delay: const Duration(milliseconds: 100),
                            child: _buildRaiserCard(context, isDark),
                          ),
                          const SizedBox(height: 18),
                          ScrollReveal(
                            delay: const Duration(milliseconds: 200),
                            child: _buildPartnerCard(context, isDark),
                          ),
                          const SizedBox(height: 18),
                          ScrollReveal(
                            delay: const Duration(milliseconds: 300),
                            child: _buildCashierCard(context, isDark),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRaiserCard(BuildContext context, bool isDark) {
    return _RoleCard(
      badgeLabel: 'HOG RAISERS',
      icon: Icons.pets_rounded,
      title: 'Hog Raiser Portal',
      description:
          'Log feeds, medications, and pig weights directly from the pens using your Android phone.',
      features: const [
        'Daily feed consumption & sack usage tracking',
        'Mortality, disease signs, & vaccination alerts',
        'Average Daily Gain (ADG) & weight progress logs',
        'One-tap supply restock requests to farm manager',
      ],
      isDark: isDark,
    );
  }

  Widget _buildPartnerCard(BuildContext context, bool isDark) {
    return _RoleCard(
      badgeLabel: 'FARM PARTNERS',
      icon: Icons.trending_up_rounded,
      title: 'Farm Partner Portal',
      description:
          '100% transparent tracking of funded batches with real-time audit trails and harvest return computations.',
      features: const [
        'Real-time batch capital deployment & live ROI',
        'Itemized feed & medical disbursement tracking',
        'Projected harvest yield and net payout breakdown',
        'Direct progress photos & batch milestone alerts',
      ],
      isDark: isDark,
    );
  }

  Widget _buildCashierCard(BuildContext context, bool isDark) {
    return _RoleCard(
      badgeLabel: 'POINT OF SALE (POS)',
      icon: Icons.point_of_sale_rounded,
      title: 'Cashier & Store POS',
      description:
          'Fast sales checkout for feeds, vitamins, medicines, and livestock with automatic inventory deductions.',
      features: const [
        'Quick order checkout & digital receipt generation',
        'Instant warehouse inventory deduction & restock alerts',
        'Daily sales balancing & collection reporting',
        'Customer purchase history & account records',
      ],
      isDark: isDark,
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String badgeLabel;
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;
  final bool isDark;

  const _RoleCard({
    required this.badgeLabel,
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final cardBg = isDark ? PiggyTrunkTheme.ptSurfaceDark : PiggyTrunkTheme.ptSurface;
    final cardBorder = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
    final titleColor = isDark ? PiggyTrunkTheme.ptTextDark : PiggyTrunkTheme.ptText;
    final descColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;
    final itemTextColor = isDark ? PiggyTrunkTheme.ptTextDark : PiggyTrunkTheme.ptText;

    // System dark and white mode aligned colors
    final iconColor = isDark ? Colors.white : const Color(0xFF18314F);
    final iconBgColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFF18314F).withValues(alpha: 0.08);
    final iconBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : const Color(0xFF18314F).withValues(alpha: 0.15);
    final badgeBgColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFF18314F).withValues(alpha: 0.06);
    final badgeBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : const Color(0xFF18314F).withValues(alpha: 0.12);
    final checkmarkBgColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFF18314F).withValues(alpha: 0.08);

    return HoverCard(
      translateY: -8.0,
      duration: const Duration(milliseconds: 220),
      child: Container(
        constraints: BoxConstraints(minHeight: isMobile ? 0 : 480),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: EdgeInsets.all(isMobile ? 18 : 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Top Icon & Badge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: iconBorderColor),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: badgeBorderColor),
                ),
                child: Text(
                  badgeLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.45,
              color: descColor,
            ),
          ),
          const SizedBox(height: 16),

          Divider(color: cardBorder, height: 1),
          const SizedBox(height: 14),

          // Feature list
          ...features.map((feature) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: checkmarkBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded, size: 12, color: iconColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: itemTextColor,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ),
  );
}
}
