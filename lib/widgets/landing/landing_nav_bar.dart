import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';

class LandingNavBar extends ConsumerWidget {
  final VoidCallback onScrollToOverview;
  final VoidCallback onScrollToHowItWorks;
  final VoidCallback onScrollToPlatforms;
  final VoidCallback onScrollToDownload;
  final VoidCallback onContactTap;

  const LandingNavBar({
    super.key,
    required this.onScrollToOverview,
    required this.onScrollToHowItWorks,
    required this.onScrollToPlatforms,
    required this.onScrollToDownload,
    required this.onContactTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isSmallScreen(context);

    // Exact PiggyTrunkTheme system tokens
    final bgNav = isDark ? PiggyTrunkTheme.ptSurfaceDark : PiggyTrunkTheme.ptSurface;
    final borderColor = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
    final brandTitleColor = isDark ? PiggyTrunkTheme.ptTextDark : PiggyTrunkTheme.ptText;

    return Container(
      decoration: BoxDecoration(
        color: bgNav,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 36,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand Logo & Title
          InkWell(
            onTap: onScrollToOverview,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/piggytrunk_logo.png',
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 14),
                Text(
                  'Piggy Trunk',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: brandTitleColor,
                  ),
                ),
              ],
            ),
          ),

          // Desktop Navigation Links
          if (!isMobile)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavLink(
                  title: 'Overview',
                  onTap: onScrollToOverview,
                ),
                const SizedBox(width: 12),
                _NavLink(
                  title: 'How It Works',
                  onTap: onScrollToHowItWorks,
                ),
                const SizedBox(width: 12),
                _NavLink(
                  title: 'Platforms',
                  onTap: onScrollToPlatforms,
                ),
                const SizedBox(width: 12),
                _NavLink(
                  title: 'Install Guide',
                  onTap: onScrollToDownload,
                ),
                const SizedBox(width: 20),
                // Theme Mode Switcher
                _ThemeToggleButton(ref: ref, isDark: isDark),
                const SizedBox(width: 14),
                // Open Web App CTA
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/app'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                  label: Text(
                    'Open App',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Admin Portal CTA
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/login'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : const Color(0xFF18314F),
                    side: BorderSide(
                      color: isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder,
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                  label: Text(
                    'Admin Portal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Primary Contact Us CTA
                FilledButton.icon(
                  onPressed: onContactTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.white
                        : const Color(0xFF18314F),
                    foregroundColor: isDark
                        ? const Color(0xFF0F172A)
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.mail_outline_rounded, size: 16),
                  label: Text(
                    'Contact Us',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          else
            // Mobile Action Group
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ThemeToggleButton(ref: ref, isDark: isDark),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Open App',
                  onPressed: () => Navigator.of(context).pushNamed('/app'),
                  icon: const Icon(
                    Icons.open_in_browser_rounded,
                    size: 22,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Admin Portal',
                  onPressed: () => Navigator.of(context).pushNamed('/login'),
                  icon: Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 22,
                    color: isDark ? Colors.white : const Color(0xFF18314F),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Contact Us',
                  onPressed: onContactTap,
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF18314F),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.mail_outline_rounded,
                      size: 18,
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final String title;
  final VoidCallback onTap;

  const _NavLink({
    required this.title,
    required this.onTap,
  });

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;
    final hoverColor = isDark ? Colors.white : PiggyTrunkTheme.ptPrimary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered
                ? (isDark
                    ? PiggyTrunkTheme.ptSurfaceSoftDark
                    : PiggyTrunkTheme.ptSurfaceSoft)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: _isHovered ? FontWeight.w700 : FontWeight.w600,
              color: _isHovered ? hoverColor : normalColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  final WidgetRef ref;
  final bool isDark;

  const _ThemeToggleButton({
    required this.ref,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      onPressed: () {
        ref.read(themeModeProvider.notifier).state =
            isDark ? ThemeMode.light : ThemeMode.dark;
      },
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        size: 19,
        color: isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted,
      ),
    );
  }
}
