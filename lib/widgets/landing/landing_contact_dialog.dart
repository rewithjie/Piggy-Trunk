import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_toast.dart';

class LandingContactDialog extends StatelessWidget {
  const LandingContactDialog({super.key});

  static const String contactEmail = 'piggytrunk@gmail.com';

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const LandingContactDialog(),
    );
  }

  Future<void> _launchEmail(BuildContext context) async {
    const subject = 'Piggy Trunk Inquiry';
    const body =
        'Hello Piggy Trunk Team,\n\nI would like to inquire about system access for our farm.\n\nFarm / Business Name:\nContact Number:\nLocation / Roles needed:\n\nThank you!';

    final webGmailUrl = Uri.parse(
      'https://mail.google.com/mail/?view=cm&fs=1&to=$contactEmail&su=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    await Clipboard.setData(const ClipboardData(text: contactEmail));

    try {
      if (await canLaunchUrl(webGmailUrl)) {
        await launchUrl(webGmailUrl, mode: LaunchMode.externalApplication);
      } else {
        final mailtoUri = Uri(
          scheme: 'mailto',
          path: contactEmail,
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
        'Opening email to $contactEmail. Email address also copied to clipboard!',
        title: 'Email Piggy Trunk',
      );
    }
  }

  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: contactEmail));
    if (context.mounted) {
      AppToast.success(
        context,
        '$contactEmail has been copied to your clipboard.',
        title: 'Copied to Clipboard',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
    final borderColor = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
    final textColor = isDark ? PiggyTrunkTheme.ptTextDark : PiggyTrunkTheme.ptText;
    final mutedColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;
    final cardBg = isDark ? PiggyTrunkTheme.ptSurfaceSoftDark : PiggyTrunkTheme.ptSurfaceSoft;
    final brandNavy = const Color(0xFF18314F);

    return Dialog(
      backgroundColor: surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Icon and Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : brandNavy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : brandNavy.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Icon(
                      Icons.mail_outline_rounded,
                      color: isDark ? Colors.white : brandNavy,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Piggy Trunk',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Official Inquiry & Onboarding Channel',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: mutedColor, size: 20),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Short Hapyaw Description
              Text(
                'For system access, onboarding inquiries, or farm assistance, reach out directly to our official Gmail address:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  color: mutedColor,
                ),
              ),
              const SizedBox(height: 16),

              // Prominent Email Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.alternate_email_rounded,
                      size: 18,
                      color: isDark ? Colors.white70 : brandNavy,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SelectableText(
                        contactEmail,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _copyEmail(context),
                      tooltip: 'Copy email',
                      icon: Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: isDark ? Colors.white : brandNavy,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Quick Tip
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: mutedColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Include your farm name, contact number, and location so our team can assist you right away.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        height: 1.45,
                        color: mutedColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyEmail(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(
                        'Copy Email',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _launchEmail(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : brandNavy,
                        foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: Text(
                        'Send Email',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
