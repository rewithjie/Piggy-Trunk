import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_toast.dart';

class LandingContactDialog extends StatefulWidget {
  const LandingContactDialog({super.key});

  static const String contactEmail = 'piggytrunk@gmail.com';

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const LandingContactDialog(),
    );
  }

  @override
  State<LandingContactDialog> createState() => _LandingContactDialogState();
}

class _LandingContactDialogState extends State<LandingContactDialog> {
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
      'https://mail.google.com/mail/?view=cm&fs=1&to=${LandingContactDialog.contactEmail}&su=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    await _copyEmail(showToast: false);

    try {
      if (await canLaunchUrl(webGmailUrl)) {
        await launchUrl(webGmailUrl, mode: LaunchMode.externalApplication);
      } else {
        final mailtoUri = Uri(
          scheme: 'mailto',
          path: LandingContactDialog.contactEmail,
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
    await Clipboard.setData(const ClipboardData(text: LandingContactDialog.contactEmail));

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
        '${LandingContactDialog.contactEmail} copied to clipboard.',
        title: 'Copied to Clipboard',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC);
    final brandNavy = const Color(0xFF18314F);

    return Dialog(
      backgroundColor: surfaceColor,
      surfaceTintColor: Colors.transparent,
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: borderColor, width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Official Piggy Trunk Logo and Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
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
                    child: Text(
                      'Contact Piggy Trunk',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: mutedColor, size: 20),
                    tooltip: 'Close',
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Description
              Text(
                'For system access, questions, or farm assistance, reach out directly to our official email address:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  color: mutedColor,
                ),
              ),
              const SizedBox(height: 16),

              // Interactive Tap-to-Copy Email Card
              InkWell(
                onTap: () => _copyEmail(showToast: true),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _copied
                          ? const Color(0xFF10B981)
                          : borderColor,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.alternate_email_rounded,
                        size: 18,
                        color: _copied
                            ? const Color(0xFF10B981)
                            : (isDark ? Colors.white70 : brandNavy),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          LandingContactDialog.contactEmail,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _copied
                            ? Row(
                                key: const ValueKey('copied'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: Color(0xFF10B981),
                                  ),
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
                              )
                            : Container(
                                key: const ValueKey('copy_icon'),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.copy_rounded,
                                  size: 15,
                                  color: isDark ? Colors.white70 : brandNavy,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Bottom Actions: Clean Close & Prominent Send Email
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: mutedColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
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
