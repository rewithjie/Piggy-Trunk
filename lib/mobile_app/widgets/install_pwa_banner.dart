import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Clean English "Add to Home Screen" (PWA) banner and guide for iOS & Android
class InstallPwaBanner extends StatefulWidget {
  final VoidCallback? onDismissed;

  const InstallPwaBanner({super.key, this.onDismissed});

  @override
  State<InstallPwaBanner> createState() => _InstallPwaBannerState();
}

class _InstallPwaBannerState extends State<InstallPwaBanner> {
  bool _isDismissed = false;

  void _showInstallGuideModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _PwaInstallGuideSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || _isDismissed) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFBBF7D0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // App Icon / Pig Badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF18314F),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Image.asset(
                'assets/piggytrunk_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.install_mobile_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // English Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Install Piggy Trunk',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Add to Home Screen for faster access',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // "How to Install" Button in English
          InkWell(
            onTap: () => _showInstallGuideModal(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF18314F),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Guide',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Dismiss Button
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              size: 16,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            onPressed: () {
              setState(() => _isDismissed = true);
              widget.onDismissed?.call();
            },
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}

/// Detailed English Step-by-Step Modal Guide for iOS & Android
class _PwaInstallGuideSheet extends StatelessWidget {
  const _PwaInstallGuideSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 25,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18314F).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_to_home_screen_rounded,
                    color: Color(0xFF18314F),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Install on your device',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'No App Store or Play Store download required',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: textSecondary, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // OS Platform Tabs
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: const Color(0xFF18314F),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: textSecondary,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.apple_rounded, size: 18),
                    text: 'iOS',
                  ),
                  Tab(
                    icon: Icon(Icons.android_rounded, size: 18),
                    text: 'Android',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Tab Views
            SizedBox(
              height: 220,
              child: TabBarView(
                children: [
                  // iOS Guide (English)
                  _buildStepsList(
                    context,
                    steps: const [
                      _GuideStep(
                        number: '1',
                        icon: Icons.ios_share_rounded,
                        title: 'Tap the Share button in Safari',
                        description: 'Located in the bottom toolbar of Safari (box with arrow pointing up).',
                      ),
                      _GuideStep(
                        number: '2',
                        icon: Icons.add_box_outlined,
                        title: 'Select "Add to Home Screen"',
                        description: 'Scroll down the share sheet and tap "Add to Home Screen".',
                      ),
                      _GuideStep(
                        number: '3',
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Tap "Add" in top-right corner',
                        description: 'Piggy Trunk icon will now appear on your home screen.',
                      ),
                    ],
                    note: 'Note: Please open using Safari browser on your iPhone.',
                  ),

                  // Android Guide (English)
                  _buildStepsList(
                    context,
                    steps: const [
                      _GuideStep(
                        number: '1',
                        icon: Icons.more_vert_rounded,
                        title: 'Tap Menu in Chrome',
                        description: 'Tap the 3 vertical dots (⋮) in the top-right corner of Chrome.',
                      ),
                      _GuideStep(
                        number: '2',
                        icon: Icons.install_mobile_rounded,
                        title: 'Tap "Install app" or "Add to Home screen"',
                        description: 'Select the install option from the Chrome menu dropdown.',
                      ),
                      _GuideStep(
                        number: '3',
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Confirm Install',
                        description: 'Tap "Install" to add Piggy Trunk to your app drawer and home screen.',
                      ),
                    ],
                    note: 'Note: Works best when opened in Google Chrome on Android.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // In-App Browser Reminder Box
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withValues(alpha: isDark ? 0.15 : 0.8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFFD97706),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Opened via Messenger or Facebook? Tap the top-right menu (⋮) and select "Open in Chrome / Safari" for best performance and Google sign-in.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Dismiss Button
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18314F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Got it, thanks!',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsList(
    BuildContext context, {
    required List<_GuideStep> steps,
    required String note,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        ...steps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF18314F).withValues(alpha: isDark ? 0.4 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      step.number,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF18314F),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(step.icon, size: 18, color: const Color(0xFF18314F)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          step.description,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            note,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _GuideStep {
  final String number;
  final IconData icon;
  final String title;
  final String description;

  const _GuideStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });
}
