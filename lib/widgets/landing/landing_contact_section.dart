import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_toast.dart';
import '../../utils/responsive.dart';

class LandingContactSection extends StatefulWidget {
  final GlobalKey? contactSectionKey;

  const LandingContactSection({
    super.key,
    this.contactSectionKey,
  });

  static const String contactEmail = 'piggytrunk@gmail.com';

  @override
  State<LandingContactSection> createState() => _LandingContactSectionState();
}

class _LandingContactSectionState extends State<LandingContactSection> {
  bool _copied = false;
  Timer? _copiedTimer;

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  Future<void> _launchEmail(BuildContext context) async {
    const subject = 'Piggy Trunk Inquiry';
    const body =
        'Hello Piggy Trunk Team,\n\nI would like to inquire about system access for our farm.\n\nFarm / Business Name:\nContact Number:\nLocation:\n\nThank you!';

    final webGmailUrl = Uri.parse(
      'https://mail.google.com/mail/?view=cm&fs=1&to=${LandingContactSection.contactEmail}&su=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    await _copyEmail(showToast: false);

    try {
      if (await canLaunchUrl(webGmailUrl)) {
        await launchUrl(webGmailUrl, mode: LaunchMode.externalApplication);
      } else {
        final mailtoUri = Uri(
          scheme: 'mailto',
          path: LandingContactSection.contactEmail,
          queryParameters: {
            'subject': subject,
            'body': body,
          },
        );
        await launchUrl(mailtoUri);
      }
    } catch (_) {
      // Handled via clipboard fallback
    }

    if (context.mounted) {
      AppToast.success(
        context,
        'Opening email app. Email address copied to clipboard!',
        title: 'Contact Piggy Trunk',
      );
    }
  }

  Future<void> _copyEmail({bool showToast = true}) async {
    await Clipboard.setData(const ClipboardData(text: LandingContactSection.contactEmail));

    if (mounted) {
      setState(() => _copied = true);
      _copiedTimer?.cancel();
      _copiedTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    }

    if (showToast && mounted) {
      AppToast.success(
        context,
        '${LandingContactSection.contactEmail} copied to clipboard.',
        title: 'Copied to Clipboard',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = Responsive.isMobile(context);

    final titleColor = isDark ? PiggyTrunkTheme.ptTextDark : PiggyTrunkTheme.ptText;
    final subtitleColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;
    final cardBg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
    final cardBorder = isDark ? PiggyTrunkTheme.ptBorderDark : const Color(0xFFE2E8F0);
    final innerCardBg = isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC);
    final brandNavy = const Color(0xFF18314F);

    return Container(
      key: widget.contactSectionKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : (isDesktop ? 64 : 32),
        vertical: isMobile ? 48 : 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'GET IN TOUCH',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                'Contact Piggy Trunk',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 28 : 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Text(
                  'Have questions about onboarding, partnerships, or swine farm operations? Reach out directly to our team.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    color: subtitleColor,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Contact Main Card
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cardBorder, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(isMobile ? 20 : 36),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left Information
                          Expanded(
                            flex: 5,
                            child: _buildInfoColumn(isDark, titleColor, subtitleColor),
                          ),
                          const SizedBox(width: 48),
                          // Divider
                          Container(
                            width: 1,
                            height: 220,
                            color: cardBorder,
                          ),
                          const SizedBox(width: 48),
                          // Right Action Box
                          Expanded(
                            flex: 6,
                            child: _buildActionColumn(context, isDark, innerCardBg, cardBorder, titleColor, subtitleColor, brandNavy),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoColumn(isDark, titleColor, subtitleColor),
                          const SizedBox(height: 28),
                          Divider(color: cardBorder),
                          const SizedBox(height: 24),
                          _buildActionColumn(context, isDark, innerCardBg, cardBorder, titleColor, subtitleColor, brandNavy),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(bool isDark, Color titleColor, Color subtitleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Image.asset(
                'assets/piggytrunk_logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Piggy Trunk Direct Support',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Online Inquiries & Assistance',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildFeatureItem(Icons.bolt_rounded, 'Fast Response', 'Messages are reviewed and answered promptly by our administration team.', isDark),
        const SizedBox(height: 12),
        _buildFeatureItem(Icons.agriculture_rounded, 'Farm Onboarding', 'Assistance with setting up batches, raiser profiles, and inventory stocks.', isDark),
        const SizedBox(height: 12),
        _buildFeatureItem(Icons.verified_user_outlined, 'Admin Verification', 'Accounts and access roles are managed securely with admin approval.', isDark),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String desc, bool isDark) {
    const iconColor = Color(0xFF3B82F6);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  height: 1.4,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionColumn(
    BuildContext context,
    bool isDark,
    Color innerCardBg,
    Color cardBorder,
    Color titleColor,
    Color subtitleColor,
    Color brandNavy,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Official Support Email',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 10),

        // Interactive Tap-to-Copy Card
        InkWell(
          onTap: () => _copyEmail(showToast: true),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: innerCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _copied ? const Color(0xFF10B981) : cardBorder,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.alternate_email_rounded,
                  size: 20,
                  color: _copied
                      ? const Color(0xFF10B981)
                      : (isDark ? Colors.white70 : brandNavy),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Click to copy email address',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        LandingContactSection.contactEmail,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: titleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _copied
                      ? Container(
                          key: const ValueKey('copied_badge'),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                              const SizedBox(width: 4),
                              Text(
                                'Copied!',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          key: const ValueKey('copy_btn'),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: isDark ? Colors.white : brandNavy,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Send Email Button
        FilledButton.icon(
          onPressed: () => _launchEmail(context),
          style: FilledButton.styleFrom(
            backgroundColor: isDark ? Colors.white : brandNavy,
            foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.send_rounded, size: 18),
          label: Text(
            'Send Email (Open Gmail / Mail App)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
