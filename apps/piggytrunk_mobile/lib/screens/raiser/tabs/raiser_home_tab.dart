import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../widgets/raiser_header_bar.dart';

class RaiserHomeTab extends StatelessWidget {
  final Map<String, dynamic> raiserData;
  final double investedAmount;
  final List<Map<String, dynamic>> requestsList;
  final List<Map<String, dynamic>> notificationsList;
  final List<Map<String, dynamic>> activeAssignments;
  final List<Map<String, dynamic>> hogsList;
  final List<Map<String, dynamic>> reportsList;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onNavigateToTab;
  final Function(int notificationId) onMarkNotificationAsRead;
  final VoidCallback onMarkAllRead;
  final Function(String targetStage) onUpdateLifecycleStage;

  static const Color _brandColor = Color(0xFF18314F);
  static const Color _gradientEndColor = Color(0xFF3B5270);
  static const Color _successGreen = Color(0xFF10B981);

  const RaiserHomeTab({
    super.key,
    required this.raiserData,
    required this.investedAmount,
    required this.requestsList,
    required this.notificationsList,
    this.activeAssignments = const [],
    this.hogsList = const [],
    this.reportsList = const [],
    required this.errorMessage,
    required this.onRefresh,
    required this.onNavigateToTab,
    required this.onMarkNotificationAsRead,
    required this.onMarkAllRead,
    required this.onUpdateLifecycleStage,
  });

  String _formatCurrency(double amount) {
    return '₱${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final raiserName = raiserData['name'] ?? 'Hog Raiser';

    // Active assignment & investment details
    final hasActiveBatch = activeAssignments.isNotEmpty;
    final hasInvestment = investedAmount > 0;
    final String activeBatchName = hasActiveBatch
        ? (activeAssignments[0]['batches']?['batch_name'] ?? 'Active Batch').toString()
        : '';

    // Pig Type and Lifecycle stage
    final String rawPigType = (raiserData['pig_type'] ?? '').toString().trim();
    final String pigType = (rawPigType.isNotEmpty && rawPigType != 'N/A' && rawPigType != 'None')
        ? rawPigType
        : (hasActiveBatch ? (activeAssignments[0]['hog_types']?['type_name'] ?? 'Fattening').toString() : 'Fattening');

    final String rawStage = (raiserData['lifecycle_stage'] ?? '').toString().trim();
    final String activeStage = (rawStage.isNotEmpty && rawStage != 'N/A' && rawStage != 'None')
        ? rawStage
        : (hasActiveBatch ? (activeAssignments[0]['lifecycle_stage'] ?? 'Booster').toString() : 'Booster');

    final String displayStage = hasInvestment ? activeStage : 'Unassigned';
    final String displayPigType = hasInvestment ? pigType : 'Unassigned';

    // Metrics computation
    final int totalHogs = hogsList.isNotEmpty
        ? hogsList.length
        : (hasActiveBatch ? (activeAssignments[0]['assigned_heads'] as num? ?? 0).toInt() : 0);

    final int sickHogsCount = hogsList.where((h) {
      final s = (h['health_status'] ?? '').toString().toLowerCase();
      return s == 'sick' || s == 'under observation' || s == 'quarantine';
    }).length;

    final int healthyHogsCount = (totalHogs - sickHogsCount).clamp(0, 9999);

    final int pendingRequestsCount = requestsList.where((r) {
      final s = (r['status'] ?? '').toString().toLowerCase();
      return s == 'pending' || s == 'for_approval';
    }).length;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: _brandColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Optional Debug Message
            if (errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'DATABASE NOTICE:\n$errorMessage',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.red[800],
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],

            // ==================== TOP GREETING & NOTIFICATION ====================
            RaiserHeaderBar(
              raiserName: raiserName,
              notificationsList: notificationsList,
              onRefreshNotifications: onRefresh,
              onMarkNotificationAsRead: onMarkNotificationAsRead,
              onMarkAllRead: onMarkAllRead,
              onNavigateToTab: onNavigateToTab,
            ),
            const SizedBox(height: 20),

            // ==================== INVESTED AMOUNT HERO CARD ====================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_brandColor, _gradientEndColor],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _brandColor.withValues(alpha: 0.22),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Batch Pill & Cycle Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          hasActiveBatch ? activeBatchName.toUpperCase() : 'NO BATCH ASSIGNED',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: (hasActiveBatch && hasInvestment) ? _successGreen : const Color(0xFFFFA566),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            (hasActiveBatch && hasInvestment)
                                ? 'Active Cycle'
                                : (hasActiveBatch ? 'Pending Investment' : 'Pending Batch'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Middle Main Investment Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invested Amount',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatCurrency(investedAmount),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => onNavigateToTab(1),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.add, color: _brandColor, size: 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bottom Info Chips Row
                  Container(
                    padding: const EdgeInsets.only(top: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildHeroMiniBadge(
                            icon: Icons.pets_rounded,
                            label: '$totalHogs Heads',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildHeroMiniBadge(
                            icon: Icons.restaurant_rounded,
                            label: 'Stage: $displayStage',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildHeroMiniBadge(
                            icon: Icons.assignment_outlined,
                            label: '$pendingRequestsCount Pending',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ==================== 4 METRIC STATS OVERVIEW ====================
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Active Hogs',
                    value: '$totalHogs Heads',
                    subtitle: hasActiveBatch ? activeBatchName : 'No batch assigned',
                    icon: Icons.pets_rounded,
                    accentColor: const Color(0xFFEF5B6C),
                    bgColor: const Color(0xFFFEF2F2),
                    onTap: () => onNavigateToTab(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Hog Health',
                    value: totalHogs > 0
                        ? (sickHogsCount == 0 ? '100% Good' : '$healthyHogsCount/$totalHogs')
                        : '100% Good',
                    subtitle: sickHogsCount == 0 ? 'All healthy' : '$sickHogsCount need care',
                    icon: Icons.health_and_safety_rounded,
                    accentColor: sickHogsCount == 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    bgColor: sickHogsCount == 0 ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                    onTap: () => onNavigateToTab(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Stock Requests',
                    value: '$pendingRequestsCount Pending',
                    subtitle: 'Awaiting Admin approval',
                    icon: Icons.assignment_rounded,
                    accentColor: const Color(0xFFF59E0B),
                    bgColor: const Color(0xFFFFFBEB),
                    onTap: () => onNavigateToTab(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Feeds Stage',
                    value: displayStage,
                    subtitle: hasInvestment ? '$displayPigType Cycle' : 'No active investment',
                    icon: Icons.restaurant_rounded,
                    accentColor: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFEFF6FF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ==================== QUICK ACTIONS ====================
            Text(
              'Quick Actions',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _brandColor,
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                _buildQuickActionTile(
                  icon: Icons.post_add_rounded,
                  label: 'Request',
                  color: const Color(0xFF2563EB),
                  onTap: () => onNavigateToTab(1),
                ),
                const SizedBox(width: 10),
                _buildQuickActionTile(
                  icon: Icons.medical_services_rounded,
                  label: 'Report',
                  color: const Color(0xFFEF4444),
                  onTap: () => onNavigateToTab(2),
                ),
                const SizedBox(width: 10),
                _buildQuickActionTile(
                  icon: Icons.pets_rounded,
                  label: 'My Hogs',
                  color: const Color(0xFF10B981),
                  onTap: () => onNavigateToTab(2),
                ),
                const SizedBox(width: 10),
                _buildQuickActionTile(
                  icon: Icons.receipt_long_rounded,
                  label: 'History',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => onNavigateToTab(1),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ==================== FEEDS STAGES (CONDITIONAL ON ACTIVE BATCH) ====================
            if (hasActiveBatch) ...[
              _buildFeedsCard(
                context: context,
                title: 'Feeds Stages',
                badgeText: hasInvestment ? (pigType == 'Sow' ? 'Sow' : 'Fattening') : 'Unassigned',
                stages: (hasInvestment && pigType == 'Sow')
                    ? const ['Booster', 'Pre-Starter', 'Starter', 'Grower', 'Breeder', 'Lactation']
                    : const ['Booster', 'Pre-Starter', 'Starter', 'Grower', 'Finisher', 'Selling'],
                activeStage: displayStage,
                hasInvestment: hasInvestment,
              ),
              const SizedBox(height: 28),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: PiggyTrunkTheme.ptBorder),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.assignment_late_outlined, size: 36, color: Color(0xffa0aec0)),
                      const SizedBox(height: 10),
                      Text(
                        'Walang nakatalagang feeds stage.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PiggyTrunkTheme.ptMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],

            // ==================== RECENT ACTIVITIES ====================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activities',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _brandColor,
                  ),
                ),
                TextButton(
                  onPressed: () => onNavigateToTab(1),
                  child: Text(
                    'See all',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _brandColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            requestsList.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: PiggyTrunkTheme.ptBorder),
                    ),
                    child: Center(
                      child: Text(
                        'Walang kamakailang aktibidad.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PiggyTrunkTheme.ptMuted,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: requestsList.take(3).map((req) {
                      final dateStr = _formatDate(req['request_date'] ?? '');
                      final status = (req['status'] ?? 'Pending').toString();
                      final rawBatchName = (req['assignments']?['batches']?['batch_name'] ?? 'N/A').toString();
                      String batchName = rawBatchName;
                      if (rawBatchName.contains('(')) {
                        final parts = rawBatchName.split('(');
                        if (parts.last.endsWith(')')) {
                          batchName = parts.sublist(0, parts.length - 1).join('(').trim();
                        }
                      }

                      return _buildActivityItem(
                        icon: Icons.assignment_outlined,
                        title: 'Stock Request ($batchName)',
                        subtitle: '$dateStr • Status: ${status.toUpperCase()}',
                        isCompleted: status.toLowerCase() == 'approved',
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildHeroMiniBadge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.5, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: PiggyTrunkTheme.ptBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 18),
                ),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios_rounded, color: PiggyTrunkTheme.ptMuted.withValues(alpha: 0.6), size: 12),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _brandColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: PiggyTrunkTheme.ptMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PiggyTrunkTheme.ptBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _brandColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedsCard({
    required BuildContext context,
    required String title,
    required String badgeText,
    required List<String> stages,
    required String activeStage,
    required bool hasInvestment,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PiggyTrunkTheme.ptBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
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
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _brandColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTimeline(context, stages, activeStage, hasInvestment),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, List<String> stages, String activeStage, bool hasInvestment) {
    int activeIndex = hasInvestment
        ? stages.indexWhere((s) => s.toLowerCase() == activeStage.toLowerCase())
        : -1;
    if (hasInvestment && activeIndex == -1) {
      activeIndex = 0;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final stepWidth = totalWidth / stages.length;

        return Stack(
          alignment: Alignment.topCenter,
          children: [
            // Connecting line
            Positioned(
              top: 16,
              left: stepWidth / 2,
              right: stepWidth / 2,
              child: Row(
                children: List.generate(stages.length - 1, (index) {
                  final isPassed = hasInvestment && index < activeIndex;
                  return Expanded(
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: isPassed ? _successGreen : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Nodes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(stages.length, (index) {
                final isPassed = hasInvestment && index < activeIndex;
                final isActive = hasInvestment && index == activeIndex;
                final isFuture = !hasInvestment || index > activeIndex;

                Color circleColor;
                Widget iconWidget;

                if (isPassed) {
                  circleColor = _successGreen;
                  iconWidget = const Icon(Icons.check_rounded, size: 15, color: Colors.white);
                } else if (isActive) {
                  circleColor = _brandColor;
                  iconWidget = const Icon(Icons.priority_high_rounded, size: 17, color: Colors.white);
                } else {
                  circleColor = const Color(0xFFF1F5F9);
                  iconWidget = const Icon(Icons.lock_outline_rounded, size: 12, color: Color(0xFFA0AEC0));
                }

                return GestureDetector(
                  onTap: () {
                    if (hasInvestment && isFuture) {
                      _showStageProgressionDialog(context, stages[index]);
                    }
                  },
                  child: SizedBox(
                    width: stepWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: isActive ? 34 : 30,
                          height: isActive ? 34 : 30,
                          decoration: BoxDecoration(
                            color: circleColor,
                            shape: BoxShape.circle,
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: _brandColor.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(child: iconWidget),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stages[index],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: isActive ? FontWeight.w800 : (isPassed ? FontWeight.w700 : FontWeight.w500),
                            color: isActive
                                ? _brandColor
                                : (isPassed ? _successGreen : const Color(0xFFA0AEC0)),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PiggyTrunkTheme.ptBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              size: 22,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _brandColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: PiggyTrunkTheme.ptMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStageProgressionDialog(BuildContext context, String targetStage) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Progression ng Stage',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: isDark ? Colors.white : _brandColor,
            ),
          ),
          content: Text(
            'Nais mo bang i-update ang stage ng iyong alaga sa $targetStage?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : PiggyTrunkTheme.ptMuted,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Hindi',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: isDark ? const Color(0xFF94A3B8) : PiggyTrunkTheme.ptMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onUpdateLifecycleStage(targetStage);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : _brandColor,
                      foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Oo, I-update',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
