import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_toast.dart';
import '../../utils/responsive.dart';

class LandingFooter extends StatelessWidget {
  final VoidCallback onScrollToOverview;
  final VoidCallback onScrollToHowItWorks;
  final VoidCallback onScrollToPlatforms;
  final VoidCallback onScrollToDownload;
  final VoidCallback onContactTap;

  const LandingFooter({
    super.key,
    required this.onScrollToOverview,
    required this.onScrollToHowItWorks,
    required this.onScrollToPlatforms,
    required this.onScrollToDownload,
    required this.onContactTap,
  });

  static const String contactEmail = 'piggytrunk@gmail.com';

  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: contactEmail));
    if (context.mounted) {
      AppToast.success(context, 'Copied $contactEmail to clipboard.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);

    final footerBg = isDark ? const Color(0xFF0B1320) : const Color(0xFF182738);
    final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFF2D3E54);
    final textMuted = const Color(0xFF94A3B8);
    final textHeader = Colors.white;

    return Container(
      width: double.infinity,
      color: footerBg,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : (isDesktop ? 64 : 32),
        vertical: 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Info
                    Expanded(
                      flex: 5,
                      child: _buildBrandInfo(context, textHeader, textMuted),
                    ),
                    const SizedBox(width: 48),
                    // Quick Links
                    Expanded(
                      flex: 3,
                      child: _buildNavLinks(context, textHeader, textMuted),
                    ),
                    // App Specs
                    Expanded(
                      flex: 4,
                      child: _buildAppSpecs(context, textHeader, textMuted),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBrandInfo(context, textHeader, textMuted),
                    const SizedBox(height: 32),
                    _buildNavLinks(context, textHeader, textMuted),
                    const SizedBox(height: 32),
                    _buildAppSpecs(context, textHeader, textMuted),
                  ],
                ),
              const SizedBox(height: 40),
              Divider(color: borderColor, height: 1),
              const SizedBox(height: 24),

              // Copyright bar
              Text(
                '© 2026 Piggy Trunk. All rights reserved.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandInfo(BuildContext context, Color textHeader, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/piggytrunk_logo.png',
              width: 38,
              height: 38,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Text(
              'Piggy Trunk',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textHeader,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Next-generation swine farm management and operations monitoring platform. Centralizing retail sales, inventory, stock distribution, and hog-raising operations.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.55,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => _copyEmail(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mail_outline_rounded, size: 15, color: textMuted),
              const SizedBox(width: 6),
              Text(
                contactEmail,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavLinks(BuildContext context, Color textHeader, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Navigation',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: textHeader,
          ),
        ),
        const SizedBox(height: 14),
        _buildFooterLink('Overview', onScrollToOverview, textMuted),
        const SizedBox(height: 8),
        _buildFooterLink('How to Get Started', onScrollToHowItWorks, textMuted),
        const SizedBox(height: 8),
        _buildFooterLink('Platform Roles', onScrollToPlatforms, textMuted),
        const SizedBox(height: 8),
        _buildFooterLink('Android Installation Guide', onScrollToDownload, textMuted),
        const SizedBox(height: 8),
        _buildFooterLink('Admin Portal Login', () => Navigator.pushNamed(context, '/admin'), textMuted),
        const SizedBox(height: 8),
        _buildFooterLink('Mobile Web App (PWA)', () => Navigator.pushNamed(context, '/app'), textMuted),
        const SizedBox(height: 8),
        _buildFooterLink('Contact Us (Inquiries)', onContactTap, textMuted),
      ],
    );
  }

  Widget _buildAppSpecs(BuildContext context, Color textHeader, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Specifications',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: textHeader,
          ),
        ),
        const SizedBox(height: 14),
        _buildSpecRow('Admin Portal', 'Browser (Web Application)', textMuted),
        const SizedBox(height: 6),
        _buildSpecRow('Mobile App', 'Android 7.0 (Nougat) or higher', textMuted),
        const SizedBox(height: 6),
        _buildSpecRow('Access Policy', 'Admin-controlled registration', textMuted),
        const SizedBox(height: 6),
        _buildSpecRow('Contact Email', contactEmail, textMuted),
      ],
    );
  }

  Widget _buildFooterLink(String label, VoidCallback onTap, Color textMuted) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textMuted,
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, Color textMuted) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
