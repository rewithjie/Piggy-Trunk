import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';

class LandingHowItWorksSection extends StatelessWidget {
  final VoidCallback onContactTap;

  const LandingHowItWorksSection({
    super.key,
    required this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    final titleColor = isDark ? PiggyTrunkTheme.ptTextDark : PiggyTrunkTheme.ptText;
    final subtitleColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;
    final sectionBg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
    final borderColor = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: sectionBg,
        border: Border.symmetric(
          horizontal: BorderSide(color: borderColor, width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 36,
        vertical: isMobile ? 48 : 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Eyebrow Badge
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
                child: Text(
                  'HOW TO GET STARTED',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: isDark
                        ? PiggyTrunkTheme.ptPrimaryDark
                        : PiggyTrunkTheme.ptPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Section Headline
              Text(
                'Get Started with PIGGY TRUNK',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 26 : 36,
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
                  'PIGGY TRUNK uses a controlled account registration process to ensure that only authorized users can access the system.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 14 : 16,
                    height: 1.5,
                    color: subtitleColor,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // 3 Steps Pipeline Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  if (isWide) {
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildStepCard(
                              context,
                              stepNumber: '01',
                              stepTitle: 'CONTACT US',
                              arrowSubtext: 'Send us your business details',
                              bodyText:
                                  'Interested businesses can contact the PIGGY TRUNK development team to request system access and provide the necessary business information.',
                              icon: Icons.mail_outline_rounded,
                              isDark: isDark,
                            ),
                          ),
                          _buildHorizontalConnector(isDark),
                          Expanded(
                            child: _buildStepCard(
                              context,
                              stepNumber: '02',
                              stepTitle: 'ACCOUNT SETUP',
                              arrowSubtext:
                                  'Our developers create/seed your organization account',
                              bodyText:
                                  'The development team creates and seeds the initial business account and administrator access. The administrator can then manage the organization\'s authorized users and assigned roles.',
                              icon: Icons.verified_user_outlined,
                              isDark: isDark,
                            ),
                          ),
                          _buildHorizontalConnector(isDark),
                          Expanded(
                            child: _buildStepCard(
                              context,
                              stepNumber: '03',
                              stepTitle: 'ACCESS SYSTEM',
                              arrowSubtext: 'Receive your account access',
                              bodyText:
                                  'Once the account has been set up, authorized users can access the features assigned to their roles through the appropriate platform.',
                              icon: Icons.devices_rounded,
                              isDark: isDark,
                              platformBreakdown: true,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Column(
                      children: [
                        _buildStepCard(
                          context,
                          stepNumber: '01',
                          stepTitle: 'CONTACT US',
                          arrowSubtext: 'Send us your business details',
                          bodyText:
                              'Interested businesses can contact the PIGGY TRUNK development team to request system access and provide the necessary business information.',
                          icon: Icons.mail_outline_rounded,
                          isDark: isDark,
                        ),
                        _buildVerticalConnector(isDark),
                        _buildStepCard(
                          context,
                          stepNumber: '02',
                          stepTitle: 'ACCOUNT SETUP',
                          arrowSubtext:
                              'Our developers create/seed your organization account',
                          bodyText:
                              'The development team creates and seeds the initial business account and administrator access. The administrator can then manage the organization\'s authorized users and assigned roles.',
                          icon: Icons.verified_user_outlined,
                          isDark: isDark,
                        ),
                        _buildVerticalConnector(isDark),
                        _buildStepCard(
                          context,
                          stepNumber: '03',
                          stepTitle: 'ACCESS SYSTEM',
                          arrowSubtext: 'Receive your account access',
                          bodyText:
                              'Once the account has been set up, authorized users can access the features assigned to their roles through the appropriate platform.',
                          icon: Icons.devices_rounded,
                          isDark: isDark,
                          platformBreakdown: true,
                        ),
                      ],
                    );
                  }
                },
              ),

              const SizedBox(height: 48),

              // Bottom Call to Action Button
              FilledButton.icon(
                onPressed: onContactTap,
                style: FilledButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.white
                      : const Color(0xFF18314F),
                  foregroundColor: isDark
                      ? const Color(0xFF0F172A)
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.mail_outline_rounded, size: 20),
                label: Text(
                  'Contact Us to Get Started',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context, {
    required String stepNumber,
    required String stepTitle,
    required String arrowSubtext,
    required String bodyText,
    required IconData icon,
    required bool isDark,
    bool platformBreakdown = false,
  }) {
    final cardBg = isDark ? PiggyTrunkTheme.ptSurfaceSoftDark : PiggyTrunkTheme.ptSurfaceSoft;
    final borderColor = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
    final textColor = isDark ? PiggyTrunkTheme.ptTextDark : PiggyTrunkTheme.ptText;
    final mutedColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header with Number & Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFF18314F).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  stepNumber,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF18314F),
                  ),
                ),
              ),
              Icon(
                icon,
                size: 20,
                color: isDark ? Colors.white : const Color(0xFF18314F),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            stepTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),

          // Visual Flow Indicator (like in user's mockup Image 2)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.arrow_downward_rounded,
                  size: 14,
                  color: isDark ? Colors.white : const Color(0xFF18314F),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    arrowSubtext,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Explanatory Paragraph
          Text(
            bodyText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.55,
              color: mutedColor,
            ),
          ),

          // Platform breakdown in Step 03
          if (platformBreakdown) ...[
            const SizedBox(height: 16),
            Divider(color: borderColor, height: 1),
            const SizedBox(height: 14),
            _buildPlatformItem(
              title: 'Admin Portal',
              description: 'Available through a web browser for business administration and management.',
              badge: 'WEB',
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _buildPlatformItem(
              title: 'Mobile Application',
              description: 'Available for Farm Partners, Hog Raisers, and Cashiers to access their assigned functions.',
              badge: 'ANDROID / IOS',
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlatformItem({
    required String title,
    required String description,
    required String badge,
    required bool isDark,
  }) {
    final textColor = isDark ? PiggyTrunkTheme.ptTextDark : PiggyTrunkTheme.ptText;
    final mutedColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? PiggyTrunkTheme.ptSurfaceDark
                    : PiggyTrunkTheme.ptBorder,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          description,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            height: 1.4,
            color: mutedColor,
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalConnector(bool isDark) {
    return SizedBox(
      width: 32,
      child: Center(
        child: Icon(
          Icons.arrow_forward_rounded,
          size: 20,
          color: isDark ? Colors.white : const Color(0xFF18314F),
        ),
      ),
    );
  }

  Widget _buildVerticalConnector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Icon(
        Icons.arrow_downward_rounded,
        size: 20,
        color: isDark ? Colors.white : const Color(0xFF18314F),
      ),
    );
  }
}
