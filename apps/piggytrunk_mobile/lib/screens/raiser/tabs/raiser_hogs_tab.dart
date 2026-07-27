import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../widgets/raiser_header_bar.dart';

class RaiserHogsTab extends StatelessWidget {
  final Map<String, dynamic> raiserData;
  final List<Map<String, dynamic>> hogsList;
  final List<Map<String, dynamic>> reportsList;
  final List<Map<String, dynamic>> notificationsList;
  final BigInt? selectedAssignmentId;
  final Future<void> Function() onRefresh;
  final Function(int notificationId) onMarkNotificationAsRead;
  final VoidCallback onMarkAllRead;
  final Future<void> Function(BigInt hogId, String reportType, String notes) onSubmitHogReport;

  static const Color _brandColor = Color(0xFF18314F);

  const RaiserHogsTab({
    super.key,
    required this.raiserData,
    required this.hogsList,
    required this.reportsList,
    required this.notificationsList,
    required this.selectedAssignmentId,
    required this.onRefresh,
    required this.onMarkNotificationAsRead,
    required this.onMarkAllRead,
    required this.onSubmitHogReport,
  });

  String _formatReportTime(String? createdAtStr) {
    if (createdAtStr == null) return 'N/A';
    try {
      final created = DateTime.parse(createdAtStr);
      final now = DateTime.now();
      final diff = now.difference(created);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else {
        return '${diff.inDays}d ago';
      }
    } catch (_) {
      return '';
    }
  }

  void _showAddReportDialog(BuildContext context) {
    final filteredHogs = hogsList.where((h) {
      final assId = h['assignment_id'];
      return assId != null && BigInt.from(assId as num) == selectedAssignmentId;
    }).toList();

    BigInt? selectedHogId;
    if (filteredHogs.isNotEmpty) {
      selectedHogId = BigInt.from(filteredHogs[0]['hog_id'] as num);
    }
    String selectedReportType = 'Food Poisoning';
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Mag-submit ng Hog Report',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _brandColor,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Piliin ang Baboy / Hog ID',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _brandColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    filteredHogs.isEmpty
                        ? Text(
                            'Walang nakatalagang baboy.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: PiggyTrunkTheme.ptMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : DropdownButtonFormField<BigInt>(
                            initialValue: selectedHogId,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _brandColor),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: _brandColor,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              fillColor: const Color(0xfff7f8fb),
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            items: List.generate(filteredHogs.length, (index) {
                              final h = filteredHogs[index];
                              final id = h['hog_id'];
                              return DropdownMenuItem<BigInt>(
                                value: BigInt.from(id as num),
                                child: Text('Hog #${index + 1}'),
                              );
                            }),
                            onChanged: (val) {
                              setDialogState(() {
                                selectedHogId = val;
                              });
                            },
                          ),
                    const SizedBox(height: 16),
                    Text(
                      'Uri ng Ulat / Report Type',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _brandColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedReportType,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _brandColor),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: _brandColor,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        fillColor: const Color(0xfff7f8fb),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Food Poisoning', child: Text('Food Poisoning')),
                        DropdownMenuItem(value: 'Fever', child: Text('Lagnat / Fever')),
                        DropdownMenuItem(value: 'Diarrhea', child: Text('Pagtatae / Diarrhea')),
                        DropdownMenuItem(value: 'Injury', child: Text('Sugat / Injury')),
                        DropdownMenuItem(value: 'Dead', child: Text('Pumawaw / Dead')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedReportType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Karagdagang Detalye',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _brandColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _brandColor),
                      decoration: InputDecoration(
                        hintText: 'Isulat ang obserbasyon sa baboy...',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: PiggyTrunkTheme.ptMuted),
                        fillColor: const Color(0xfff7f8fb),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Kanselahin',
                    style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedHogId == null
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await onSubmitHogReport(selectedHogId!, selectedReportType, notesController.text.trim());
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'I-submit',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
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
    if (activeIndex == -1) activeIndex = 0;

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

                Color circleColor = isPassed || isActive ? _brandColor : const Color(0xffe6ebf2);
                Widget iconWidget = isPassed
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : (isActive
                        ? const Icon(Icons.priority_high_rounded, size: 16, color: Colors.white)
                        : const Icon(Icons.lock, size: 12, color: Color(0xffa0aec0)));

                return SizedBox(
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
                );
              }),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            RaiserHeaderBar(
              raiserName: raiserData['name'] ?? 'Hog Raiser',
              notificationsList: notificationsList,
              onRefreshNotifications: onRefresh,
              onMarkNotificationAsRead: onMarkNotificationAsRead,
              onMarkAllRead: onMarkAllRead,
            ),
            const SizedBox(height: 20),

            Text(
              pigType != null ? 'HOG ${pigType.toUpperCase()}' : 'HOG STATUS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _brandColor,
              ),
            ),
            const SizedBox(height: 16),

            if (pigType == 'Fattening') ...[
              _buildFeedsCard(
                title: 'Feeds Stages',
                badgeText: 'Fattening',
                stages: const ['Booster', 'Pre-starter', 'Starter', 'Grower', 'Finisher'],
                activeStage: raiserData['lifecycle_stage'] ?? 'Grower',
              ),
              const SizedBox(height: 20),
            ] else if (pigType == 'Sow') ...[
              _buildFeedsCard(
                title: 'Feeds Stages',
                badgeText: 'Sow',
                stages: const ['Booster', 'Pre-starter', 'Starter', 'Grower', 'Breeder', 'Lactation'],
                activeStage: raiserData['lifecycle_stage'] ?? 'Breeder',
              ),
              const SizedBox(height: 20),
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
                  child: Text(
                    'Walang nakatalagang feeds stage.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: PiggyTrunkTheme.ptMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _showAddReportDialog(context),
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: Text(
                  'Add Report',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006B33),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Report Activity',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _brandColor,
              ),
            ),
            const SizedBox(height: 12),

            reportsList.isEmpty
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
                        'Walang naitalang ulat sa kalusugan.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PiggyTrunkTheme.ptMuted,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reportsList.length,
                    itemBuilder: (context, index) {
                      final report = reportsList[index];
                      final type = report['report_type'] ?? 'Report';
                      final timeAgo = _formatReportTime(report['created_at']);

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
                                color: const Color(0xffef5b6c).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xffef5b6c),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _brandColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              timeAgo,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: PiggyTrunkTheme.ptMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.more_vert, color: Color(0xffa0aec0), size: 20),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
