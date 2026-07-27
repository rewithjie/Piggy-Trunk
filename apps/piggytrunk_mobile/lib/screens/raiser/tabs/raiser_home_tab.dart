import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../widgets/raiser_header_bar.dart';

class RaiserHomeTab extends StatelessWidget {
  final Map<String, dynamic> raiserData;
  final double investedAmount;
  final List<Map<String, dynamic>> requestsList;
  final List<Map<String, dynamic>> notificationsList;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onNavigateToTab;
  final Function(int notificationId) onMarkNotificationAsRead;
  final VoidCallback onMarkAllRead;
  final Function(String targetStage) onUpdateLifecycleStage;

  static const Color _brandColor = Color(0xFF18314F);
  static const Color _gradientEndColor = Color(0xFF3B5270);

  const RaiserHomeTab({
    super.key,
    required this.raiserData,
    required this.investedAmount,
    required this.requestsList,
    required this.notificationsList,
    required this.errorMessage,
    required this.onRefresh,
    required this.onNavigateToTab,
    required this.onMarkNotificationAsRead,
    required this.onMarkAllRead,
    required this.onUpdateLifecycleStage,
  });

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
    final formattedAmount = investedAmount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );

    final String? pigType = raiserData['pig_type'];

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: _brandColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'DEBUG DATABASE ERROR:\n$errorMessage',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.red[800],
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],

            // Header Row
            RaiserHeaderBar(
              raiserName: raiserName,
              notificationsList: notificationsList,
              onRefreshNotifications: onRefresh,
              onMarkNotificationAsRead: onMarkNotificationAsRead,
              onMarkAllRead: onMarkAllRead,
            ),
            const SizedBox(height: 24),

            // Invested Amount Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_brandColor, _gradientEndColor],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _brandColor.withValues(alpha: 0.20),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invested Amount',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '₱ $formattedAmount',
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
            ),
            const SizedBox(height: 28),

            // Feeds Stages Card
            if (pigType == 'Fattening') ...[
              _buildFeedsCard(
                title: 'Feeds Stages',
                badgeText: 'Fattening',
                stages: const ['Booster', 'Pre-Starter', 'Starter', 'Grower', 'Finisher', 'Selling'],
                activeStage: raiserData['lifecycle_stage'] ?? 'Booster',
              ),
              const SizedBox(height: 28),
            ] else if (pigType == 'Sow') ...[
              _buildFeedsCard(
                title: 'Feeds Stages',
                badgeText: 'Sow',
                stages: const ['Booster', 'Pre-Starter', 'Starter', 'Grower', 'Breeder', 'Lactation'],
                activeStage: raiserData['lifecycle_stage'] ?? 'Booster',
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
                      const Icon(Icons.assignment_late_outlined, size: 40, color: Color(0xffa0aec0)),
                      const SizedBox(height: 12),
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

            // Recent Activities Title Row
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

            // Recent Activities List
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
                      final dateStr = _formatDate(req['request_date']);
                      final status = req['status'] as String;
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

  Widget _buildFeedsCard({
    required String title,
    required String badgeText,
    required List<String> stages,
    required String activeStage,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PiggyTrunkTheme.ptBorder),
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
                  fontWeight: FontWeight.w700,
                  color: _brandColor,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _brandColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _brandColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.more_vert, color: Color(0xffa0aec0), size: 20),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTimeline(stages, activeStage),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<String> stages, String activeStage) {
    int activeIndex = stages.indexWhere((s) => s.toLowerCase() == activeStage.toLowerCase());
    if (activeIndex == -1) {
      activeIndex = 0;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final stepWidth = totalWidth / stages.length;

        return Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: 15,
              left: stepWidth / 2,
              right: stepWidth / 2,
              child: Row(
                children: List.generate(stages.length - 1, (index) {
                  final isPassed = index < activeIndex;
                  return Expanded(
                    child: Container(
                      height: 3,
                      color: isPassed ? _brandColor : const Color(0xffe6ebf2),
                    ),
                  );
                }),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(stages.length, (index) {
                final isPassed = index < activeIndex;
                final isActive = index == activeIndex;
                final isFuture = index > activeIndex;

                Color circleColor;
                Widget iconWidget;

                if (isPassed) {
                  circleColor = _brandColor;
                  iconWidget = const Icon(Icons.check, size: 14, color: Colors.white);
                } else if (isActive) {
                  circleColor = _brandColor;
                  iconWidget = const Icon(Icons.priority_high_rounded, size: 16, color: Colors.white);
                } else {
                  circleColor = const Color(0xffe6ebf2);
                  iconWidget = const Icon(Icons.lock, size: 12, color: Color(0xffa0aec0));
                }

                return GestureDetector(
                  onTap: () {
                    if (isFuture) {
                      _showStageProgressionDialog(context, stages[index]);
                    }
                  },
                  child: SizedBox(
                    width: stepWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: circleColor,
                            shape: BoxShape.circle,
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: _brandColor.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
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
                            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                            color: isActive ? _brandColor : (isPassed ? _brandColor : const Color(0xffa0aec0)),
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

  void _showStageProgressionDialog(BuildContext context, String targetStage) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Ilipat ang Stage?',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: _brandColor,
            ),
          ),
          content: Text(
            'Sigurado ka bang nais mong ilipat ang kasalukuyang feeds stage sa "$targetStage"?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: _brandColor.withValues(alpha: 0.8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Kanselahin',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onUpdateLifecycleStage(targetStage);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Kumpirmahin',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PiggyTrunkTheme.ptBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xfff7f8fb),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _brandColor, size: 20),
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: PiggyTrunkTheme.ptMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xffe6f4ea) : const Color(0xfffff8e1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isCompleted ? 'Completed' : 'Pending',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isCompleted ? PiggyTrunkTheme.ptSuccess : PiggyTrunkTheme.ptInProgress,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
