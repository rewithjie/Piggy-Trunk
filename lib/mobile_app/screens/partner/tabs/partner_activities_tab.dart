import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../../../utils/screen_fit_util.dart';
import '../../../utils/app_strings.dart';

class PartnerActivitiesTab extends StatefulWidget {
  final List<Map<String, dynamic>> activitiesList;
  final Future<void> Function() onRefresh;
  final VoidCallback? onNavigateToBatches;
  final VoidCallback? onNavigateToLifecycle;

  const PartnerActivitiesTab({
    super.key,
    required this.activitiesList,
    required this.onRefresh,
    this.onNavigateToBatches,
    this.onNavigateToLifecycle,
  });

  @override
  State<PartnerActivitiesTab> createState() => _PartnerActivitiesTabState();
}

class _PartnerActivitiesTabState extends State<PartnerActivitiesTab> {
  static const Color _brandColor = Color(0xFF18314F);
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _accentBlue = Color(0xFF3B82F6);
  static const Color _accentAmber = Color(0xFFF59E0B);
  static const Color _accentPurple = Color(0xFF8B5CF6);

  String _selectedFilter = 'All'; // 'All' or 'Reports'
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredActivities() {
    return widget.activitiesList.where((act) {
      final title = (act['title'] ?? '').toString().toLowerCase();
      final desc = (act['description'] ?? act['message'] ?? '').toString().toLowerCase();
      final type = (act['type'] ?? '').toString().toLowerCase();
      final raiser = (act['raiser_name'] ?? '').toString().toLowerCase();

      // Category filter
      bool matchesCategory = true;
      if (_selectedFilter == 'Reports') {
        // Exclude pure investment milestone records, focus on farm raiser field updates
        final isInvestment = type.contains('invest') ||
            (act['report_id'] ?? '').toString().startsWith('inv_') ||
            title.contains('funded') ||
            title.contains('invest');
        matchesCategory = !isInvestment;
      }

      if (!matchesCategory) return false;

      if (_searchController.text.trim().isNotEmpty) {
        final query = _searchController.text.trim().toLowerCase();
        return title.contains(query) || desc.contains(query) || raiser.contains(query);
      }

      return true;
    }).toList();
  }

  Color _getColorForActivity(String type) {
    final t = type.toLowerCase();
    if (t.contains('invest')) {
      return const Color(0xFF2563EB);
    } else if (t.contains('vaccin') || t.contains('med')) {
      return _accentPurple;
    } else if (t.contains('sick') || t.contains('health') || t.contains('observation')
        || t.contains('fever') || t.contains('poison') || t.contains('diarrhea') || t.contains('injur') || t.contains('dead') || t.contains('mortality')) {
      return const Color(0xFFEF4444);
    } else if (t.contains('feed') || t.contains('weight') || t.contains('nutrition')) {
      return _accentAmber;
    } else if (t.contains('stage') || t.contains('growth') || t.contains('lifecycle')) {
      return _accentGreen;
    }
    return _accentBlue;
  }

  IconData _getIconForActivity(String type) {
    final t = type.toLowerCase();
    if (t.contains('invest')) {
      return Icons.assignment_rounded;
    } else if (t.contains('vaccin') || t.contains('med')) {
      return Icons.medication_rounded;
    } else if (t.contains('sick') || t.contains('health') || t.contains('observation')
        || t.contains('fever') || t.contains('poison') || t.contains('diarrhea') || t.contains('injur') || t.contains('dead') || t.contains('mortality')) {
      return Icons.health_and_safety_rounded;
    } else if (t.contains('feed') || t.contains('weight') || t.contains('nutrition')) {
      return Icons.monitor_weight_rounded;
    } else if (t.contains('stage') || t.contains('growth') || t.contains('lifecycle')) {
      return Icons.trending_up_rounded;
    }
    return Icons.assignment_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final fit = ScreenFit(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = AppStrings.of(context);

    final primaryTextColor = isDark ? Colors.white : _brandColor;
    final cardBgColor = isDark ? const Color(0xff151f2e) : Colors.white;
    final cardBorderColor = isDark ? const Color(0xff28354a) : const Color(0xffe6ebf2);
    final secondaryBgColor = isDark ? const Color(0xff1b2638) : const Color(0xfff8fafc);
    final mutedTextColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;

    final filteredActivities = _getFilteredActivities();

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: isDark ? Colors.white : _brandColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.fromLTRB(fit.dp(20), fit.dp(20), fit.dp(20), fit.dp(36)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== 1. FILTER PILLS ====================
            Row(
              children: [
                _buildFilterChip(
                  fit: fit,
                  label: strings.isFilipino ? 'Lahat ng Log' : 'All Logs',
                  value: 'All',
                  isDark: isDark,
                  icon: Icons.list_alt_rounded,
                ),
                SizedBox(width: fit.dp(8)),
                _buildFilterChip(
                  fit: fit,
                  label: strings.isFilipino ? 'Mga Ulat ng Raiser' : 'Raiser Reports',
                  value: 'Reports',
                  isDark: isDark,
                  icon: Icons.health_and_safety_outlined,
                ),
              ],
            ),
            SizedBox(height: fit.dp(16)),

            // ==================== 2. ACTIVITIES LIST ====================
            if (filteredActivities.isEmpty) ...[
              _buildCategoryEmptyState(
                fit: fit,
                isDark: isDark,
                cardBg: cardBgColor,
                cardBorder: cardBorderColor,
                primaryText: primaryTextColor,
                mutedText: mutedTextColor,
                filter: _selectedFilter,
                strings: strings,
              ),
              if (widget.onNavigateToBatches != null) ...[
                SizedBox(height: fit.dp(16)),
                _buildExploreBatchesButton(fit: fit, isDark: isDark, strings: strings),
              ],
            ] else ...[
              // Summary counter
              Padding(
                padding: EdgeInsets.only(bottom: fit.dp(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedFilter == 'Reports'
                          ? (strings.isFilipino ? 'MGA ULAT NG RAISER (${filteredActivities.length})' : 'RAISER FIELD REPORTS (${filteredActivities.length})')
                          : (strings.isFilipino ? 'LAHAT NG AKTIBIDAD (${filteredActivities.length})' : 'ALL ACTIVITIES & LOGS (${filteredActivities.length})'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: fit.sp(11.5),
                        fontWeight: FontWeight.w800,
                        color: mutedTextColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      strings.isFilipino ? 'Awtomatikong naka-sync' : 'Auto-synchronized',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: fit.sp(11.0),
                        fontWeight: FontWeight.w600,
                        color: _accentGreen,
                      ),
                    ),
                  ],
                ),
              ),

              // Activity Cards Stream
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredActivities.length,
                separatorBuilder: (context, index) => SizedBox(height: fit.dp(12)),
                itemBuilder: (ctx, index) {
                  final act = filteredActivities[index];
                  final isFil = strings.isFilipino;
                  final String title = isFil
                      ? (act['title_fil'] ?? act['title'] ?? 'Aktibidad')
                      : (act['title_en'] ?? act['title'] ?? 'Activity Update');
                  final String description = isFil
                      ? (act['desc_fil'] ?? act['description'] ?? act['message'] ?? '')
                      : (act['desc_en'] ?? act['description'] ?? act['message'] ?? '');
                  final String date = isFil
                      ? (act['date_fil'] ?? act['date'] ?? act['created_at'] ?? '')
                      : (act['date'] ?? act['created_at'] ?? '');
                  final String raiserName = act['raiser_name'] ?? 'Assigned Raiser';
                  final String type = act['type'] ?? 'general';
                  final bool isInvestment = type.toLowerCase().contains('invest') ||
                      (act['report_id'] ?? '').toString().startsWith('inv_');

                  final Color typeColor = isInvestment ? const Color(0xFF2563EB) : _getColorForActivity(type);
                  final IconData typeIcon = isInvestment
                      ? Icons.assignment_rounded
                      : ((act['icon'] is IconData) ? act['icon'] as IconData : _getIconForActivity(type));

                  return Container(
                    padding: EdgeInsets.all(fit.dp(16)),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(fit.dp(18)),
                      border: Border.all(color: cardBorderColor, width: 1.1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: fit.dp(40),
                          height: fit.dp(40),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(fit.dp(12)),
                          ),
                          child: Icon(typeIcon, size: fit.dp(20), color: typeColor),
                        ),
                        SizedBox(width: fit.dp(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: fit.sp(14.5),
                                        fontWeight: FontWeight.w800,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: fit.dp(8), vertical: fit.dp(3)),
                                    decoration: BoxDecoration(
                                      color: secondaryBgColor,
                                      borderRadius: BorderRadius.circular(fit.dp(10)),
                                      border: Border.all(color: cardBorderColor, width: 0.8),
                                    ),
                                    child: Text(
                                      date,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: fit.sp(10.5),
                                        fontWeight: FontWeight.w600,
                                        color: mutedTextColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (description.isNotEmpty) ...[
                                SizedBox(height: fit.dp(6)),
                                Text(
                                  description,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: fit.sp(12.5),
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                              if (!isInvestment && raiserName.isNotEmpty) ...[
                                SizedBox(height: fit.dp(10)),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_pin_circle_outlined,
                                      size: fit.dp(14),
                                      color: mutedTextColor,
                                    ),
                                    SizedBox(width: fit.dp(4)),
                                    Text(
                                      isFil ? 'Itinala ni $raiserName' : 'Logged by $raiserName',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: fit.sp(11.5),
                                        fontWeight: FontWeight.w600,
                                        color: mutedTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Filter Chip Component
  Widget _buildFilterChip({
    required ScreenFit fit,
    required String label,
    required String value,
    required bool isDark,
    IconData? icon,
  }) {
    final isSelected = _selectedFilter == value;
    final activeBg = isDark ? Colors.white : _brandColor;
    final activeText = isDark ? const Color(0xFF0F172A) : Colors.white;
    final inactiveBg = isDark ? const Color(0xff151f2e) : Colors.white;
    final inactiveBorder = isDark ? const Color(0xff28354a) : const Color(0xffe2e8f0);
    final inactiveText = isDark ? const Color(0xff94a3b8) : const Color(0xff64748b);

    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      borderRadius: BorderRadius.circular(fit.dp(20)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: fit.dp(14), vertical: fit.dp(7)),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(fit.dp(20)),
          border: Border.all(
            color: isSelected ? activeBg : inactiveBorder,
            width: isSelected ? 1.4 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark ? Colors.white : _brandColor).withValues(alpha: isDark ? 0.15 : 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: fit.dp(14),
                color: isSelected ? activeText : inactiveText,
              ),
              SizedBox(width: fit.dp(5)),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: fit.sp(11.5),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeText : (isDark ? Colors.white : inactiveText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Context-aware empty state for filters
  Widget _buildCategoryEmptyState({
    required ScreenFit fit,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color primaryText,
    required Color mutedText,
    required String filter,
    required AppStrings strings,
  }) {
    IconData icon = Icons.assignment_outlined;
    String title = strings.noReportsYet;
    String subtitle = strings.noReportsSubtitle;

    if (filter == 'Reports') {
      icon = Icons.health_and_safety_rounded;
      title = strings.isFilipino ? 'Walang Sakit na Naitala' : 'No Health Alerts Reported';
      subtitle = strings.isFilipino
          ? 'Lahat ng 4 na baboy sa batch na ito ay malulusog at nasa maayos na kalagayan.'
          : 'All 4 hogs in this batch are healthy with regular checkups on track.';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: fit.dp(20), vertical: fit.dp(24)),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(fit.dp(20)),
        border: Border.all(color: cardBorder, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: fit.dp(48),
            height: fit.dp(48),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: fit.dp(22), color: isDark ? const Color(0xFF38BDF8) : _brandColor),
          ),
          SizedBox(height: fit.dp(10)),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: fit.sp(14.5),
              fontWeight: FontWeight.w800,
              color: primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: fit.dp(4)),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: fit.sp(12.0),
              fontWeight: FontWeight.w500,
              color: mutedText,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExploreBatchesButton({
    required ScreenFit fit,
    required bool isDark,
    required AppStrings strings,
  }) {
    return SizedBox(
      width: double.infinity,
      height: fit.dp(48),
      child: ElevatedButton.icon(
        onPressed: widget.onNavigateToBatches,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : _brandColor,
          foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fit.dp(14))),
        ),
        icon: Icon(
          Icons.inventory_2_outlined,
          size: fit.dp(18),
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
        ),
        label: Text(
          strings.isFilipino ? 'Tingnan ang mga Batch' : 'Explore Available Batches',
          style: GoogleFonts.plusJakartaSans(
            fontSize: fit.sp(13.5),
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
          ),
        ),
      ),
    );
  }
}
