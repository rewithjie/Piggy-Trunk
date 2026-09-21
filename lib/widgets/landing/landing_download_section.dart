import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_toast.dart';
import '../../utils/responsive.dart';
import 'scroll_reveal.dart';

class LandingDownloadSection extends StatefulWidget {
  final GlobalKey? downloadSectionKey;

  const LandingDownloadSection({
    super.key,
    this.downloadSectionKey,
  });

  @override
  State<LandingDownloadSection> createState() => _LandingDownloadSectionState();
}

class _LandingDownloadSectionState extends State<LandingDownloadSection> {
  static const String _apkUrl =
      'https://ywwwrshblzyqmxkbkxsp.supabase.co/storage/v1/object/public/piggytrunkmobile/PiggyTrunkMobile.apk';

  Future<void> _handleDownload() async {
    final uri = Uri.parse(_apkUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Unable to open download link: $e');
      }
    }
  }

  void _copyLink() {
    Clipboard.setData(const ClipboardData(text: _apkUrl));
    AppToast.success(context, 'Download link copied to clipboard!');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = Responsive.isMobile(context);

    final titleColor = isDark ? PiggyTrunkTheme.ptTextDark : PiggyTrunkTheme.ptText;
    final subtitleColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;
    final cardBg = isDark ? PiggyTrunkTheme.ptSurfaceDark : PiggyTrunkTheme.ptSurface;
    final cardBorder = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;

    final qrUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=260x260&data=${Uri.encodeComponent(_apkUrl)}';

    return Container(
      key: widget.downloadSectionKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : (isDesktop ? 64 : 32),
        vertical: isMobile ? 48 : 80,
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
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'DOWNLOAD & INSTALL',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                'Ready to Transform Your Swine Operations?',
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
                constraints: const BoxConstraints(maxWidth: 680),
                child: Text(
                  'Download the Piggy Trunk Mobile APK directly to your Android device, or scan the QR code. For iPhone & iPad, install instantly via Safari using "Add to Home Screen".',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    color: subtitleColor,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Main Download Card (QR + Step-by-Step Guide)
              LayoutBuilder(
                builder: (context, cardConstraints) {
                  final isWideCard = cardConstraints.maxWidth >= 820;

                  return HoverCard(
                    translateY: -5.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cardBorder, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(isMobile ? 18 : 28),
                    child: isWideCard
                        ? IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Left QR & Download Buttons
                                Expanded(
                                  flex: 5,
                                  child: _buildQrAndActionGroup(
                                    context,
                                    qrUrl,
                                    isDark,
                                    titleColor,
                                    subtitleColor,
                                  ),
                                ),
                                const SizedBox(width: 32),
                                // Vertical divider
                                Container(
                                  width: 1,
                                  color: cardBorder,
                                ),
                                const SizedBox(width: 32),
                                // Right Installation Guide
                                Expanded(
                                  flex: 6,
                                  child: _buildInstallationGuide(
                                    context,
                                    isDark,
                                    titleColor,
                                    subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              _buildQrAndActionGroup(
                                context,
                                qrUrl,
                                isDark,
                                titleColor,
                                subtitleColor,
                              ),
                              const SizedBox(height: 28),
                              Divider(color: cardBorder),
                              const SizedBox(height: 24),
                              _buildInstallationGuide(
                                context,
                                isDark,
                                titleColor,
                                subtitleColor,
                              ),
                            ],
                          ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrAndActionGroup(
    BuildContext context,
    String qrUrl,
    bool isDark,
    Color titleColor,
    Color subtitleColor,
  ) {
    final border = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // OS Badges
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.android_rounded, size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(
                    'Android APK',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.apple, size: 14, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                  const SizedBox(width: 4),
                  Text(
                    'iOS Web App',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // QR Code Box
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  qrUrl,
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF18314F),
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 200,
                      color: const Color(0xFFF1F5F9),
                      child: const Center(
                        child: Icon(Icons.qr_code_2_rounded, size: 70, color: Color(0xFF64748B)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt_outlined, size: 15, color: Color(0xFF475569)),
                  const SizedBox(width: 6),
                  Text(
                    'Scan with Phone Camera',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Primary Download APK Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white
                  : const Color(0xFF18314F),
              foregroundColor: isDark
                  ? const Color(0xFF0F172A)
                  : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.download_rounded, size: 22),
            label: Text(
              'Download APK File',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),


        // Copy Link Secondary Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _copyLink,
            style: OutlinedButton.styleFrom(
              foregroundColor: titleColor,
              side: BorderSide(
                color: border,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.copy_rounded, size: 17),
            label: Text(
              'Copy Download Link',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstallationGuide(
    BuildContext context,
    bool isDark,
    Color titleColor,
    Color subtitleColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                ),
              ),
              child: const Icon(Icons.android_rounded, color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Android Installation Guide',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Because Piggy Trunk Mobile is distributed directly as an APK, follow these 3 simple steps:',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: subtitleColor,
          ),
        ),
        const SizedBox(height: 24),

        _buildStepItem(
          stepNumber: '1',
          title: 'Download the APK File',
          description:
              'Tap "Download APK File" above or scan the QR code using your phone camera.',
          icon: Icons.file_download_outlined,
          isDark: isDark,
        ),
        const SizedBox(height: 18),

        _buildStepItem(
          stepNumber: '2',
          title: 'Allow Installation (Unknown Apps)',
          description:
              'If your mobile browser displays a security alert like "File might be harmful", tap "Download anyway" and enable "Allow from this source / Install".',
          icon: Icons.security_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 18),

        _buildStepItem(
          stepNumber: '3',
          title: 'Launch & Sign In',
          description:
              'Once installed, tap the Piggy Trunk icon on your home screen and log in with your verified Hog Raiser or Partner account.',
          icon: Icons.check_circle_outline_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 22),

        // Unified iOS (iPhone / iPad) Guide Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF132035) : const Color(0xFFF8FAFD),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF263A53) : const Color(0xFFD5E3F5),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.apple,
                      size: 16,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'iOS (iPhone / iPad) Guide',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'PWA / Web App',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'APKs are exclusively for Android. For iOS devices, install Piggy Trunk directly as a Web App in 3 simple steps:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 12),
              _buildIosStepItem(
                step: '1',
                text: 'Open this website in Safari on your iPhone.',
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _buildIosStepItem(
                step: '2',
                text: 'Tap the Share icon at the bottom of the Safari screen.',
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _buildIosStepItem(
                step: '3',
                text: 'Scroll down and tap "Add to Home Screen" to install.',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIosStepItem({
    required String step,
    required String text,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF28405D) : const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF18314F),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem({
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required bool isDark,
  }) {
    final stepColor = isDark ? Colors.white : const Color(0xFF18314F);
    final stepBg = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFF18314F).withValues(alpha: 0.08);
    final stepBorder = isDark
        ? Colors.white.withValues(alpha: 0.25)
        : const Color(0xFF18314F).withValues(alpha: 0.15);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: stepBg,
            shape: BoxShape.circle,
            border: Border.all(color: stepBorder),
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: stepColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFF1F5F9) : PiggyTrunkTheme.ptPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5D7391),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
