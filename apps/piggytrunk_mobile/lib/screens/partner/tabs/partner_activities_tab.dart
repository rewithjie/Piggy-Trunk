import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../../../utils/screen_fit_util.dart';

class PartnerActivitiesTab extends StatefulWidget {
  final List<Map<String, dynamic>> activitiesList;
  final Future<void> Function() onRefresh;
  final VoidCallback? onNavigateToBatches;
  final String currentStage; // Booster, Pre-Starter, Starter, Grower, Finisher
  final String? raiserName;
  final int totalHogs;

  const PartnerActivitiesTab({
    super.key,
    required this.activitiesList,
    required this.onRefresh,
    this.onNavigateToBatches,
    this.currentStage = 'Grower',
    this.raiserName,
    this.totalHogs = 0,
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

  static const List<String> _stages = [
    'Booster',
    'Pre-Starter',
    'Starter',
    'Grower',
    'Finisher',
  ];

  int _getStageIndex(String stage) {
    final s = stage.toLowerCase().replaceAll('-', '').replaceAll(' ', '');
    if (s.contains('finisher') || s.contains('harvest')) return 4;
    if (s.contains('grower')) return 3;
    if (s.contains('prestarter') || s.contains('pre')) return 1;
    if (s.contains('starter')) return 2;
    if (s.contains('booster')) return 0;
    return 3; // default to Grower
  }

  String _selectedFilter = 'All'; // 'All', 'Health', 'Medication', 'Feeding', 'Lifecycle'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
      if (_selectedFilter == 'Health') {
        matchesCategory = type.contains('health') ||
            type.contains('sick') ||
            title.contains('health') ||
            desc.contains('health') ||
            desc.contains('check');
      } else if (_selectedFilter == 'Medication') {
        matchesCategory = type.contains('vaccin') ||
            type.contains('med') ||
            title.contains('vaccin') ||
            desc.contains('vaccin') ||
            desc.contains('dose');
      } else if (_selectedFilter == 'Feeding') {
        matchesCategory = type.contains('feed') ||
            type.contains('weight') ||
            title.contains('feed') ||
            desc.contains('feed') ||
            desc.contains('kg');
      } else if (_selectedFilter == 'Lifecycle') {
        matchesCategory = type.contains('stage') ||
            type.contains('growth') ||
            title.contains('stage') ||
            desc.contains('stage') ||
            desc.contains('booster') ||
            desc.contains('grower') ||
            desc.contains('finisher');
      }

      if (!matchesCategory) return false;

      // Text search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return title.contains(query) ||
            desc.contains(query) ||
            raiser.contains(query) ||
            type.contains(query);
      }

      return true;
    }).toList();
  }

  Color _getColorForActivity(String type) {
    final t = type.toLowerCase();
    if (t.contains('vaccin') || t.contains('med')) {
      return _accentBlue;
    } else if (t.contains('sick') || t.contains('health') || t.contains('observation')) {
      return _accentGreen;
    } else if (t.contains('feed') || t.contains('weight') || t.contains('nutrition')) {
      return _accentAmber;
    } else if (t.contains('stage') || t.contains('growth') || t.contains('lifecycle')) {
      return _accentPurple;
    }
    return _brandColor;
  }

  IconData _getIconForActivity(String type) {
    final t = type.toLowerCase();
    if (t.contains('vaccin') || t.contains('med')) {
      return Icons.medication_rounded;
    } else if (t.contains('sick') || t.contains('health') || t.contains('observation')) {
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

    final primaryTextColor = isDark ? const Color(0xffecf2ff) : _brandColor;
    final cardBgColor = isDark ? const Color(0xff151f2e) : Colors.white;
    final cardBorderColor = isDark ? const Color(0xff28354a) : const Color(0xffe6ebf2);
    final secondaryBgColor = isDark ? const Color(0xff1b2638) : const Color(0xfff8fafc);
    final mutedTextColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;

    final filteredActivities = _getFilteredActivities();

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: _brandColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.fromLTRB(fit.dp(20), fit.dp(20), fit.dp(20), fit.dp(36)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== 1. CATEGORY FILTER CHIPS ====================
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip(fit: fit, label: 'All Logs', value: 'All', isDark: isDark),
                  SizedBox(width: fit.dp(8)),
                  _buildFilterChip(fit: fit, label: 'Health', value: 'Health', isDark: isDark, icon: Icons.health_and_safety_outlined),
                  SizedBox(width: fit.dp(8)),
                  _buildFilterChip(fit: fit, label: 'Vaccines', value: 'Medication', isDark: isDark, icon: Icons.medication_outlined),
                  SizedBox(width: fit.dp(8)),
                  _buildFilterChip(fit: fit, label: 'Feeds & Weight', value: 'Feeding', isDark: isDark, icon: Icons.monitor_weight_outlined),
                  SizedBox(width: fit.dp(8)),
                  _buildFilterChip(fit: fit, label: 'Lifecycle', value: 'Lifecycle', isDark: isDark, icon: Icons.trending_up_rounded),
                ],
              ),
            ),
            SizedBox(height: fit.dp(16)),

            // ==================== 2. HOG RAISER REPORTS FEED ====================
            if (filteredActivities.isEmpty) ...[
              _buildModernEmptyState(
                fit: fit,
                isDark: isDark,
                cardBg: cardBgColor,
                cardBorder: cardBorderColor,
                secondaryBg: secondaryBgColor,
                primaryText: primaryTextColor,
                mutedText: mutedTextColor,
              ),
              SizedBox(height: fit.dp(16)),
            ] else ...[
              // Summary counter
              Padding(
                padding: EdgeInsets.only(bottom: fit.dp(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'HOG RAISER REPORTS (${filteredActivities.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: fit.sp(11.5),
                        fontWeight: FontWeight.w800,
                        color: mutedTextColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      'Auto-synchronized',
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
                separatorBuilder: (_, __) => SizedBox(height: fit.dp(12)),
                itemBuilder: (ctx, index) {
                  final act = filteredActivities[index];
                  final String title = act['title'] ?? 'Activity Update';
                  final String description = act['description'] ?? act['message'] ?? '';
                  final String date = act['date'] ?? act['created_at'] ?? '';
                  final String raiserName = act['raiser_name'] ?? 'Assigned Raiser';
                  final String type = act['type'] ?? 'general';

                  final Color typeColor = _getColorForActivity(type);
                  final IconData typeIcon = _getIconForActivity(type);

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
                              SizedBox(height: fit.dp(10)),
                              // Raiser Attribution Badge
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_pin_circle_outlined,
                                    size: fit.dp(14),
                                    color: mutedTextColor,
                                  ),
                                  SizedBox(width: fit.dp(4)),
                                  Text(
                                    'Logged by $raiserName',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: fit.sp(11.5),
                                      fontWeight: FontWeight.w600,
                                      color: mutedTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: fit.dp(16)),
            ],

            // ==================== 3. LIFECYCLE STAGE CARD (AT BOTTOM) ====================
            _buildLifecycleStageCard(
              fit: fit,
              isDark: isDark,
              cardBg: cardBgColor,
              cardBorder: cardBorderColor,
              primaryText: primaryTextColor,
              mutedText: mutedTextColor,
            ),

            // Action CTA to Explore Batches
            if (filteredActivities.isEmpty && widget.onNavigateToBatches != null) ...[
              SizedBox(height: fit.dp(16)),
              SizedBox(
                width: double.infinity,
                height: fit.dp(48),
                child: ElevatedButton.icon(
                  onPressed: widget.onNavigateToBatches,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fit.dp(14))),
                  ),
                  icon: Icon(Icons.inventory_2_outlined, size: fit.dp(18), color: Colors.white),
                  label: Text(
                    'Explore Available Batches',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: fit.sp(13.5),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
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
    final primaryTextColor = isDark ? const Color(0xffecf2ff) : _brandColor;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      borderRadius: BorderRadius.circular(fit.dp(20)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: fit.dp(12), vertical: fit.dp(7)),
        decoration: BoxDecoration(
          color: isSelected
              ? _brandColor
              : (isDark ? const Color(0xff151f2e) : Colors.white),
          borderRadius: BorderRadius.circular(fit.dp(20)),
          border: Border.all(
            color: isSelected
                ? _brandColor
                : (isDark ? const Color(0xff28354a) : const Color(0xffe2e8f0)),
            width: isSelected ? 1.4 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _brandColor.withValues(alpha: 0.25),
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
                size: fit.dp(13),
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xff64748b)),
              ),
              SizedBox(width: fit.dp(5)),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: fit.sp(11.5),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : primaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 4. MODERN CLEAN EMPTY STATE ====================
  Widget _buildModernEmptyState({
    required ScreenFit fit,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color secondaryBg,
    required Color primaryText,
    required Color mutedText,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: fit.dp(24), vertical: fit.dp(28)),
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
            width: fit.dp(54),
            height: fit.dp(54),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: fit.dp(24),
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: fit.dp(14)),
          Text(
            'No Hog Raiser Reports Yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: fit.sp(16.0),
              fontWeight: FontWeight.w800,
              color: primaryText,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: fit.dp(6)),
          Text(
            'Live reports and routine updates from your assigned hog raisers will appear here once submitted.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: fit.sp(12.0),
              fontWeight: FontWeight.w500,
              color: mutedText,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: fit.dp(16)),
          // Refresh action button
          SizedBox(
            height: fit.dp(36),
            child: OutlinedButton.icon(
              onPressed: widget.onRefresh,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cardBorder, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fit.dp(10))),
                padding: EdgeInsets.symmetric(horizontal: fit.dp(16)),
              ),
              icon: Icon(Icons.refresh_rounded, size: fit.dp(14), color: primaryText),
              label: Text(
                'Refresh Reports',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: fit.sp(11.5),
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 5. LIFECYCLE STAGE COMPONENT ====================
  Widget _buildLifecycleStageCard({
    required ScreenFit fit,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color primaryText,
    required Color mutedText,
  }) {
    final int currentStageIdx = _getStageIndex(widget.currentStage);
    final String currentStageName = _stages[currentStageIdx];
    final String raiser = widget.raiserName?.trim() ?? '';
    final int totalHogs = widget.totalHogs;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(fit.dp(18)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timeline_rounded,
                    size: fit.dp(18),
                    color: isDark ? const Color(0xFF93C5FD) : _brandColor,
                  ),
                  SizedBox(width: fit.dp(8)),
                  Text(
                    'Lifecycle Stage',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: fit.sp(14.0),
                      fontWeight: FontWeight.w800,
                      color: primaryText,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: fit.dp(10), vertical: fit.dp(4)),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(fit.dp(12)),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '$currentStageName Stage',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: fit.sp(11.0),
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: fit.dp(16)),

          // Stepper Timeline Nodes
          Row(
            children: List.generate(_stages.length, (index) {
              final stageName = _stages[index];
              final bool isCompleted = index < currentStageIdx;
              final bool isCurrent = index == currentStageIdx;

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Left connecting line
                        Expanded(
                          child: Container(
                            height: 2.5,
                            color: index == 0
                                ? Colors.transparent
                                : (index <= currentStageIdx
                                    ? (isDark ? const Color(0xFF60A5FA) : _brandColor)
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                          ),
                        ),
                        // Node Circle
                        Container(
                          width: fit.dp(28),
                          height: fit.dp(28),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFF10B981)
                                : (isCurrent
                                    ? (isDark ? const Color(0xFF60A5FA) : _brandColor)
                                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCompleted
                                  ? const Color(0xFF10B981)
                                  : (isCurrent
                                      ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB))
                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                              width: isCurrent ? 2 : 1.2,
                            ),
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check_rounded
                                : (isCurrent ? Icons.trending_up_rounded : Icons.lock_outline_rounded),
                            size: fit.dp(14),
                            color: isCompleted || isCurrent
                                ? Colors.white
                                : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                          ),
                        ),
                        // Right connecting line
                        Expanded(
                          child: Container(
                            height: 2.5,
                            color: index == _stages.length - 1
                                ? Colors.transparent
                                : (index < currentStageIdx
                                    ? (isDark ? const Color(0xFF60A5FA) : _brandColor)
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: fit.dp(8)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        stageName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: fit.sp(10.0),
                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                          color: isCurrent
                              ? (isDark ? const Color(0xFF93C5FD) : _brandColor)
                              : (isCompleted ? primaryText : mutedText),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          if (raiser.isNotEmpty || totalHogs > 0) ...[
            SizedBox(height: fit.dp(14)),
            Container(
              padding: EdgeInsets.symmetric(horizontal: fit.dp(12), vertical: fit.dp(8)),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131F33) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(fit.dp(12)),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E2F48) : const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_pin_circle_outlined,
                    size: fit.dp(15),
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  SizedBox(width: fit.dp(6)),
                  Expanded(
                    child: Text(
                      raiser.isNotEmpty ? 'Assigned Raiser: $raiser' : 'Assigned Farm Raiser',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: fit.sp(11.5),
                        fontWeight: FontWeight.w600,
                        color: mutedText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (totalHogs > 0) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: fit.dp(8), vertical: fit.dp(2)),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(fit.dp(8)),
                      ),
                      child: Text(
                        '$totalHogs Hogs Active',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: fit.sp(10.5),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
