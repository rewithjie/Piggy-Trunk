import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../../../utils/screen_fit_util.dart';
import 'partner_hog_updates_tab.dart';

class PartnerMyProjectsTab extends StatefulWidget {
  final List<Map<String, dynamic>> projectsList;
  final double investedAmount;
  final Future<void> Function() onRefresh;
  final VoidCallback? onMakeInvestment;

  const PartnerMyProjectsTab({
    super.key,
    required this.projectsList,
    required this.investedAmount,
    required this.onRefresh,
    this.onMakeInvestment,
  });

  @override
  State<PartnerMyProjectsTab> createState() => _PartnerMyProjectsTabState();
}

class _PartnerMyProjectsTabState extends State<PartnerMyProjectsTab> {
  static const Color _brandColor = Color(0xFF18314F);
  static const Color _greenBtnColor = Color(0xFF34D399);

  int _selectedSubTab = 0; // 0: RECENT PROJECTS, 1: HISTORY
  Map<String, dynamic>? _selectedProjectForUpdates;

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  void _openProjectHogUpdates(Map<String, dynamic> project) {
    setState(() {
      _selectedProjectForUpdates = project;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedProjectForUpdates != null) {
      final proj = _selectedProjectForUpdates!;
      final raiserName = proj['raiser_name'] ?? proj['assigned_raiser'] ?? "Juan Dela Cruz";
      final int hogs = (proj['total_hogs'] as num?)?.toInt() ?? 120;
      final int mortality = (proj['mortality'] as num?)?.toInt() ?? 0;
      final String stage = proj['stage'] ?? "Grower";

      return PartnerHogUpdatesTab(
        raiserName: raiserName,
        totalHog: hogs,
        totalMortality: mortality,
        currentStage: stage,
        reportsList: const [],
        onRefresh: widget.onRefresh,
        onBack: () => setState(() => _selectedProjectForUpdates = null),
      );
    }

    final fit = ScreenFit(context);
    final double paddingH = fit.dp(20.0);
    final double paddingV = fit.dp(16.0);
    final double titleFontSize = fit.sp(24.0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xffecf2ff) : _brandColor;
    final mutedTextColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;
    final cardBgColor = isDark ? const Color(0xff151f2e) : Colors.white;
    final cardBorderColor = isDark ? const Color(0xff28354a) : const Color(0xffe6ebf2);
    final statsBoxBg = isDark ? const Color(0xff1b2638) : const Color(0xfff8fafc);
    final statsBoxBorder = isDark ? const Color(0xff28354a) : const Color(0xffe6ebf2);

    final activeProjects = widget.investedAmount > 0 || widget.projectsList.isNotEmpty
        ? widget.projectsList
        : <Map<String, dynamic>>[];

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: _brandColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Projects',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                    letterSpacing: -0.4,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.search_rounded,
                        color: primaryTextColor,
                        size: fit.dp(24),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(width: fit.dp(16)),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          color: primaryTextColor,
                          size: fit.dp(24),
                        ),
                        Positioned(
                          right: -1,
                          top: -1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF5B6C),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: fit.dp(16.0)),

            // 2. Sub-navigation Tabs (RECENT PROJECTS | HISTORY)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedSubTab = 0),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: fit.dp(10)),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedSubTab == 0 ? _brandColor : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'RECENT PROJECTS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: fit.sp(12.0),
                            fontWeight: FontWeight.w800,
                            color: _selectedSubTab == 0 ? primaryTextColor : mutedTextColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedSubTab = 1),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: fit.dp(10)),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedSubTab == 1 ? _brandColor : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'HISTORY',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: fit.sp(12.0),
                            fontWeight: FontWeight.w800,
                            color: _selectedSubTab == 1 ? primaryTextColor : mutedTextColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: fit.dp(16.0)),

            // 3. Tab Content
            if (_selectedSubTab == 0) ...[
              // RECENT PROJECTS TAB
              if (activeProjects.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: fit.dp(20), vertical: fit.dp(28)),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(fit.dp(22)),
                    border: Border.all(color: cardBorderColor, width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.work_outline_rounded,
                        size: fit.dp(38),
                        color: isDark ? const Color(0xff9cb0c9) : _brandColor,
                      ),
                      SizedBox(height: fit.dp(10)),
                      Text(
                        'No Active Projects',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: fit.sp(15.0),
                          fontWeight: FontWeight.w800,
                          color: primaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: fit.dp(4)),
                      Text(
                        'You have not invested in any hog raiser projects yet. Make your first investment to start tracking!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: fit.sp(12.0),
                          fontWeight: FontWeight.w500,
                          color: mutedTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (widget.onMakeInvestment != null) ...[
                        SizedBox(height: fit.dp(16)),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (widget.projectsList.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No active batches available for investment at the moment.'),
                                  backgroundColor: Color(0xFFEF4444),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            widget.onMakeInvestment?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brandColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(horizontal: fit.dp(18), vertical: fit.dp(12)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(fit.dp(14)),
                            ),
                          ),
                          icon: Icon(Icons.add_circle_outline_rounded, size: fit.dp(18), color: Colors.white),
                          label: Text(
                            'Make First Investment',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: fit.sp(13.0),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              else
                ...activeProjects.map((project) {
                  final String title = project['title'] ?? project['batch_name'] ?? 'Batch 2024-B';
                  final String batchCode = project['batch_code'] ?? '#B2024-B';
                  final String status = project['status'] ?? 'IN PROGRESS';
                  final double amount = (project['amount'] as num?)?.toDouble() ?? (widget.investedAmount > 0 ? widget.investedAmount : 10000.0);
                  final int totalRaisers = (project['total_raisers'] as num?)?.toInt() ?? 3;
                  final int totalHogs = (project['total_hogs'] as num?)?.toInt() ?? 42;
                  final int mortality = (project['mortality'] as num?)?.toInt() ?? 0;

                  return Container(
                    margin: EdgeInsets.only(bottom: fit.dp(16)),
                    padding: EdgeInsets.all(fit.dp(20.0)),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(fit.dp(22)),
                      border: Border.all(color: cardBorderColor, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Badge & Code
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: fit.dp(12), vertical: fit.dp(6)),
                              decoration: BoxDecoration(
                                color: _greenBtnColor,
                                borderRadius: BorderRadius.circular(fit.dp(20)),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: fit.sp(11.0),
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            Text(
                              batchCode,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: fit.sp(13.0),
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: fit.dp(12)),

                        // Batch Title
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: fit.sp(20.0),
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: fit.dp(14)),

                        // Stats Table Box
                        Container(
                          padding: EdgeInsets.symmetric(vertical: fit.dp(14), horizontal: fit.dp(12)),
                          decoration: BoxDecoration(
                            color: statsBoxBg,
                            borderRadius: BorderRadius.circular(fit.dp(16)),
                            border: Border.all(color: statsBoxBorder, width: 1),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'TOTAL RAISER',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: fit.sp(10.0),
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    SizedBox(height: fit.dp(4)),
                                    Text(
                                      '$totalRaisers',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: fit.sp(20.0),
                                        fontWeight: FontWeight.w800,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: fit.dp(30),
                                width: 1,
                                color: statsBoxBorder,
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'TOTAL HOG',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: fit.sp(10.0),
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    SizedBox(height: fit.dp(4)),
                                    Text(
                                      '$totalHogs',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: fit.sp(20.0),
                                        fontWeight: FontWeight.w800,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: fit.dp(30),
                                width: 1,
                                color: statsBoxBorder,
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'MORTALITY',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: fit.sp(10.0),
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    SizedBox(height: fit.dp(4)),
                                    Text(
                                      '$mortality',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: fit.sp(20.0),
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: fit.dp(14)),

                        // Investment Amount Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'INVESTMENT:',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: fit.sp(12.0),
                                fontWeight: FontWeight.w800,
                                color: mutedTextColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              '₱${_formatCurrency(amount)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: fit.sp(16.0),
                                fontWeight: FontWeight.w800,
                                color: primaryTextColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: fit.dp(14)),

                        // VIEW Action Button (Brand Navy Theme)
                        SizedBox(
                          width: double.infinity,
                          height: fit.dp(44),
                          child: ElevatedButton(
                            onPressed: () => _openProjectHogUpdates(project),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _brandColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(fit.dp(14)),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'VIEW',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: fit.sp(14.0),
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                SizedBox(width: fit.dp(6)),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: fit.dp(20),
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ] else ...[
              // HISTORY TAB
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: fit.dp(20), vertical: fit.dp(28)),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(fit.dp(22)),
                  border: Border.all(color: cardBorderColor, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: fit.dp(38),
                      color: isDark ? const Color(0xff9cb0c9) : _brandColor,
                    ),
                    SizedBox(height: fit.dp(10)),
                    Text(
                      'No Project History',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: fit.sp(15.0),
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: fit.dp(4)),
                    Text(
                      'Completed or closed project investments will appear here.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: fit.sp(12.0),
                        fontWeight: FontWeight.w500,
                        color: mutedTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
