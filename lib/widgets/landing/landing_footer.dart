import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_toast.dart';
import '../../utils/responsive.dart';

class LandingFooter extends StatelessWidget {
  final VoidCallback? onScrollToOverview;
  final VoidCallback? onScrollToHowItWorks;
  final VoidCallback? onScrollToPlatforms;
  final VoidCallback? onScrollToDownload;
  final VoidCallback? onContactTap;

  const LandingFooter({
    super.key,
    this.onScrollToOverview,
    this.onScrollToHowItWorks,
    this.onScrollToPlatforms,
    this.onScrollToDownload,
    this.onContactTap,
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
      padding: EdgeInsets.only(
        left: isMobile ? 20 : (isDesktop ? 64 : 32),
        right: isMobile ? 20 : (isDesktop ? 64 : 32),
        top: 48,
        bottom: 0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Info
                    Expanded(
                      flex: 6,
                      child: _buildBrandInfo(context, textHeader, textMuted),
                    ),
                    const SizedBox(width: 64),
                    // App Specs
                    Expanded(
                      flex: 5,
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
                    _buildAppSpecs(context, textHeader, textMuted),
                  ],
                ),
              const SizedBox(height: 40),
              Divider(color: borderColor, height: 1),
              const SizedBox(height: 28),

              // Half-Cut Terminal Text Watermark
              _TerminalWatermark(isDark: isDark),
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
        const SizedBox(height: 14),
        _EmailCopyButton(
          email: contactEmail,
          onTap: () => _copyEmail(context),
          textMuted: textMuted,
        ),
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

class _EmailCopyButton extends StatefulWidget {
  final String email;
  final VoidCallback onTap;
  final Color textMuted;

  const _EmailCopyButton({
    required this.email,
    required this.onTap,
    required this.textMuted,
  });

  @override
  State<_EmailCopyButton> createState() => _EmailCopyButtonState();
}

class _EmailCopyButtonState extends State<_EmailCopyButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.35)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mail_outline_rounded,
                size: 15,
                color: _isHovered ? const Color(0xFF38BDF8) : widget.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                widget.email,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TerminalWatermark extends StatefulWidget {
  final bool isDark;

  const _TerminalWatermark({required this.isDark});

  @override
  State<_TerminalWatermark> createState() => _TerminalWatermarkState();
}

class _TerminalWatermarkState extends State<_TerminalWatermark> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          // Scale font size seamlessly with available footer width
          final fontSize = (availableWidth / 7.6).clamp(28.0, 136.0);
          final letterSpacing = (fontSize * 0.08).clamp(2.0, 12.0);
          // Truly expose top ~56% of the terminal letters so "PIGGY TRUNK" is clearly legible while keeping the half-cut bottom aesthetic
          final visibleHeight = fontSize * 0.56;
          final totalTextHeight = fontSize * 1.15;

          final baseAlpha = widget.isDark ? 0.18 : 0.20;
          final hoverAlpha = widget.isDark ? 0.36 : 0.40;
          final currentAlpha = _isHovered ? hoverAlpha : baseAlpha;

          return ClipRect(
            child: SizedBox(
              height: visibleHeight,
              width: availableWidth,
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: totalTextHeight,
                minHeight: totalTextHeight,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      style: GoogleFonts.spaceMono(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: letterSpacing,
                        color: Colors.white.withValues(alpha: currentAlpha),
                      ),
                      child: const Text(
                        'PIGGY TRUNK',
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

