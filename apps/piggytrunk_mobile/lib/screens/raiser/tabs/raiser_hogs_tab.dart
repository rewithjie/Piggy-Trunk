import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../widgets/raiser_empty_state.dart';

class RaiserHogsTab extends StatefulWidget {
  final Map<String, dynamic> raiserData;
  final double investedAmount;
  final List<Map<String, dynamic>> activeAssignments;
  final List<Map<String, dynamic>> hogsList;
  final List<Map<String, dynamic>> reportsList;
  final List<Map<String, dynamic>> notificationsList;
  final BigInt? selectedAssignmentId;
  final Future<void> Function() onRefresh;
  final Function(int notificationId) onMarkNotificationAsRead;
  final VoidCallback onMarkAllRead;
  final Future<void> Function(BigInt hogId, String reportType, String notes) onSubmitHogReport;

  const RaiserHogsTab({
    super.key,
    required this.raiserData,
    this.investedAmount = 0.0,
    this.activeAssignments = const [],
    required this.hogsList,
    required this.reportsList,
    required this.notificationsList,
    required this.selectedAssignmentId,
    required this.onRefresh,
    required this.onMarkNotificationAsRead,
    required this.onMarkAllRead,
    required this.onSubmitHogReport,
  });

  @override
  State<RaiserHogsTab> createState() => _RaiserHogsTabState();
}

class _RaiserHogsTabState extends State<RaiserHogsTab> {
  static const Color _brandColor = Color(0xFF18314F);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _warningAmber = Color(0xFFF59E0B);
  static const Color _dangerRed = Color(0xFFEF4444);

  String _selectedTab = 'Hogs'; // 'Hogs' or 'Reports'

  String _formatReportTime(String? createdAtStr) {
    if (createdAtStr == null || createdAtStr.isEmpty) return 'Recent';
    try {
      final created = DateTime.parse(createdAtStr);
      final now = DateTime.now();
      final diff = now.difference(created);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[created.month - 1]} ${created.day}';
    } catch (_) {
      return 'Recent';
    }
  }

  void _showAddReportDialog(BuildContext context, [BigInt? preSelectedHogId]) {
    final filteredHogs = widget.hogsList.where((h) {
      if (widget.selectedAssignmentId == null) return true;
      final assId = h['assignment_id'];
      return assId != null && BigInt.from(assId as num) == widget.selectedAssignmentId;
    }).toList();

    BigInt? selectedHogId = preSelectedHogId;
    if (selectedHogId == null && filteredHogs.isNotEmpty) {
      selectedHogId = BigInt.from(filteredHogs[0]['hog_id'] as num);
    }
    String selectedReportType = 'Food Poisoning';
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final bg = isDark ? const Color(0xFF132238) : Colors.white;
            final textColor = isDark ? Colors.white : _brandColor;

            return Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.medical_services_rounded, color: _dangerRed, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ulat sa Kalusugan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Mag-report ng obserbasyon sa kalusugan ng baboy',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: PiggyTrunkTheme.ptMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Piliin ang Baboy
                    Text(
                      'Piliin ang Baboy',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    filteredHogs.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              'Walang nakatalagang baboy sa kasalukuyan.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: PiggyTrunkTheme.ptMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : DropdownButtonFormField<BigInt>(
                            initialValue: selectedHogId,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _brandColor),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: _brandColor,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              fillColor: const Color(0xFFF8FAFC),
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            items: List.generate(filteredHogs.length, (index) {
                              final h = filteredHogs[index];
                              final id = h['hog_id'];
                              final tag = h['tag_number'] ?? '#${index + 1}';
                              return DropdownMenuItem<BigInt>(
                                value: BigInt.from(id as num),
                                child: Text('Hog $tag'),
                              );
                            }),
                            onChanged: (val) {
                              setModalState(() {
                                selectedHogId = val;
                              });
                            },
                          ),
                    const SizedBox(height: 16),

                    // Uri ng Ulat
                    Text(
                      'Uri ng Ulat / Report Type',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedReportType,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _brandColor),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: _brandColor,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
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
                          setModalState(() {
                            selectedReportType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Karagdagang Detalye
                    Text(
                      'Karagdagang Detalye',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _brandColor),
                      decoration: InputDecoration(
                        hintText: 'Isulat ang obserbasyon sa baboy...',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: PiggyTrunkTheme.ptMuted),
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(modalCtx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              'Kanselahin',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: selectedHogId == null
                                ? null
                                : () async {
                                    Navigator.pop(modalCtx);
                                    await widget.onSubmitHogReport(
                                      selectedHogId!,
                                      selectedReportType,
                                      notesController.text.trim(),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _brandColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              'I-submit ang Ulat',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : _brandColor;

    final bool hasActiveBatch = widget.activeAssignments.isNotEmpty;
    final bool hasInvestment = widget.investedAmount > 0;
    final bool isFundedAndActive = hasActiveBatch && hasInvestment;

    final String rawPigType = (widget.raiserData['pig_type'] ?? '').toString().trim();
    final bool isRaiserTypeSet = rawPigType.isNotEmpty &&
        rawPigType != 'N/A' &&
        rawPigType != 'None' &&
        rawPigType.toLowerCase() != 'unassigned';

    final String assignedType = (hasActiveBatch && widget.activeAssignments[0]['hog_types']?['type_name'] != null)
        ? widget.activeAssignments[0]['hog_types']['type_name'].toString()
        : (isRaiserTypeSet ? rawPigType : 'Unassigned');

    final String displayPigType = isFundedAndActive
        ? (assignedType.toLowerCase() == 'sow' ? 'Sow' : 'Fattening')
        : 'Unassigned';

    final String rawStage = (widget.raiserData['lifecycle_stage'] ?? '').toString().trim();
    final String activeStage = (rawStage.isNotEmpty && rawStage != 'N/A' && rawStage != 'None' && rawStage.toLowerCase() != 'unassigned')
        ? rawStage
        : (hasActiveBatch ? (widget.activeAssignments[0]['lifecycle_stage'] ?? 'Booster').toString() : 'Booster');

    final String displayStage = isFundedAndActive ? activeStage : 'Unassigned';

    final int totalHogs = widget.hogsList.length;
    final int sickHogsCount = widget.hogsList.where((h) {
      final s = (h['health_status'] ?? '').toString().toLowerCase();
      return s == 'sick' || s == 'under observation' || s == 'quarantine';
    }).length;
    final int healthyHogsCount = (totalHogs - sickHogsCount).clamp(0, 9999);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: _brandColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== TOP BALANCED FILTER PILLS ====================
            Row(
              children: [
                Expanded(
                  child: _buildFilterChip('Hogs', 'Mga Alaga', totalHogs),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFilterChip('Reports', 'Health Reports', widget.reportsList.length, color: _dangerRed),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (!hasActiveBatch) ...[
              // ==================== EMPTY STATE WHEN NO BATCH ====================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: PiggyTrunkTheme.ptBorder),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.assignment_late_outlined, size: 40, color: Color(0xFFA0AEC0)),
                      const SizedBox(height: 12),
                      Text(
                        'Walang nakatalagang alagang baboy.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PiggyTrunkTheme.ptMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'I-aassign ng Farm Admin ang iyong batch dito.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: PiggyTrunkTheme.ptMuted.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // ==================== FEEDS STAGES TIMELINE CARD ====================
              _buildFeedsCard(
                title: 'Feeds Stages',
                badgeText: displayPigType,
                stages: (isFundedAndActive && displayPigType == 'Sow')
                    ? const ['Booster', 'Pre-Starter', 'Starter', 'Grower', 'Breeder', 'Lactation']
                    : const ['Booster', 'Pre-Starter', 'Starter', 'Grower', 'Finisher', 'Selling'],
                activeStage: displayStage,
              ),
              const SizedBox(height: 24),

              // ==================== TAB CONTENT: HOGS OR REPORTS ====================
              if (_selectedTab == 'Hogs') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Listahan ng Alaga',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '$totalHogs Heads ($healthyHogsCount Healthy)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PiggyTrunkTheme.ptMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (widget.hogsList.isEmpty) ...[
                  RaiserEmptyState(
                    icon: Icons.pets_outlined,
                    message: 'Walang alagang baboy sa listahan.',
                    subtitle: 'Ang mga nakatalagang baboy mula kay Admin ay lalabas dito.',
                  ),
                ] else ...[
                  ...widget.hogsList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final hog = entry.value;
                    final rawStatus = (hog['health_status'] ?? 'Healthy').toString();
                    final isHealthy = rawStatus.toLowerCase() == 'healthy' || rawStatus.isEmpty;
                    final hogId = BigInt.from(hog['hog_id'] as num);
                    final tagNumber = hog['tag_number'] ?? '#${index + 1}';
                    final weight = hog['current_weight'] != null ? '${hog['current_weight']} kg' : null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
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
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isHealthy ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.pets_rounded,
                              color: isHealthy ? _successGreen : _warningAmber,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hog $tagNumber',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _brandColor,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  weight != null ? 'Timbang: $weight' : 'Walang tala ng timbang',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: PiggyTrunkTheme.ptMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showAddReportDialog(context, hogId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isHealthy ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isHealthy
                                      ? _successGreen.withValues(alpha: 0.3)
                                      : _dangerRed.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isHealthy ? Icons.check_circle_outline_rounded : Icons.report_problem_rounded,
                                    size: 13,
                                    color: isHealthy ? _successGreen : _dangerRed,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isHealthy ? 'HEALTHY' : rawStatus.toUpperCase(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isHealthy ? _successGreen : _dangerRed,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ] else ...[
                // ==================== REPORTS TAB ====================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Health Reports Activity',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showAddReportDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _brandColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _brandColor.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              'Add Report',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (widget.reportsList.isEmpty) ...[
                  RaiserEmptyState(
                    icon: Icons.health_and_safety_outlined,
                    message: 'Walang naitalang ulat sa kalusugan.',
                    subtitle: 'Lahat ng baboy ay malusog. Pindutin ang "+ Add Report" kung may obserbasyong medikal.',
                  ),
                ] else ...[
                  ...widget.reportsList.map((report) {
                    final type = (report['report_type'] ?? 'Health Report').toString();
                    final notes = (report['notes'] ?? '').toString().trim();
                    final timeAgo = _formatReportTime(report['created_at']);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
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
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.medical_services_rounded,
                                  color: _dangerRed,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      type,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _brandColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      timeAgo,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        color: PiggyTrunkTheme.ptMuted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (notes.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                notes,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: PiggyTrunkTheme.ptMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, int count, {Color? color}) {
    final isSelected = _selectedTab == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? _brandColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _brandColor : PiggyTrunkTheme.ptBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _brandColor.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : _brandColor,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.22)
                    : (color?.withValues(alpha: 0.12) ?? PiggyTrunkTheme.ptBg),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : (color ?? _brandColor),
                ),
              ),
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
    final bool isUnassigned = badgeText.toLowerCase() == 'unassigned';
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
                  color: isUnassigned ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isUnassigned ? const Color(0xFFE2E8F0) : const Color(0xFFDBEAFE)),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isUnassigned ? const Color(0xFF64748B) : const Color(0xFF2563EB),
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
    final bool isUnassigned = activeStage.toLowerCase() == 'unassigned';
    int activeIndex = isUnassigned
        ? -1
        : stages.indexWhere((s) => s.toLowerCase() == activeStage.toLowerCase());

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final stepWidth = totalWidth / stages.length;

        return Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: 16,
              left: stepWidth / 2,
              right: stepWidth / 2,
              child: Row(
                children: List.generate(stages.length - 1, (index) {
                  final isPassed = activeIndex >= 0 && index < activeIndex;
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(stages.length, (index) {
                final isPassed = activeIndex >= 0 && index < activeIndex;
                final isActive = activeIndex >= 0 && index == activeIndex;

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

                return SizedBox(
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
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
