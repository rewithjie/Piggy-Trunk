import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../../../utils/app_strings.dart';
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
  final Function(String targetStage)? onUpdateLifecycleStage;

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
    this.onUpdateLifecycleStage,
  });

  @override
  State<RaiserHogsTab> createState() => _RaiserHogsTabState();
}

class _RaiserHogsTabState extends State<RaiserHogsTab> {
  static const Color _brandColor = Color(0xFF18314F);
  static const Color _successGreen = Color(0xFF10B981);
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
            final bg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
            final textColor = isDark ? Colors.white : _brandColor;
            final inputBg = isDark ? const Color(0xFF1E2D42) : const Color(0xFFF8FAFC);
            final inputBorder = isDark ? const Color(0xFF3B506D) : const Color(0xFFE2E8F0);
            final dropdownBg = isDark ? const Color(0xFF1E2D42) : Colors.white;

            return Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15),
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
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
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
                            color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2),
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
                                  color: isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: isDark ? PiggyTrunkTheme.ptMutedDark : const Color(0xFF64748B)),
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
                              color: inputBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: inputBorder),
                            ),
                            child: Text(
                              'Walang nakatalagang baboy sa kasalukuyan.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : DropdownButtonFormField<BigInt>(
                            initialValue: selectedHogId,
                            isExpanded: true,
                            dropdownColor: dropdownBg,
                            borderRadius: BorderRadius.circular(14),
                            icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white70 : _brandColor),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              fillColor: inputBg,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: inputBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: inputBorder),
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
                      dropdownColor: dropdownBg,
                      borderRadius: BorderRadius.circular(14),
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white70 : _brandColor),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        fillColor: inputBg,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: inputBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: inputBorder),
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
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Isulat ang obserbasyon sa baboy...',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted),
                        fillColor: inputBg,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: inputBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: inputBorder),
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
                              side: BorderSide(color: isDark ? const Color(0xFF3B506D) : const Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              'Kanselahin',
                              style: GoogleFonts.plusJakartaSans(
                                color: isDark ? PiggyTrunkTheme.ptMutedDark : const Color(0xFF64748B),
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
                              backgroundColor: isDark ? Colors.white : _brandColor,
                              foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              'I-submit ang Ulat',
                              style: GoogleFonts.plusJakartaSans(
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
    final strings = AppStrings.of(context);

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
        : (isRaiserTypeSet ? rawPigType : strings.unassigned);

    final String displayPigType = isFundedAndActive
        ? (assignedType.toLowerCase() == 'sow' ? 'Sow' : 'Fattening')
        : strings.unassigned;

    final String rawStage = (widget.raiserData['lifecycle_stage'] ?? '').toString().trim();
    final String activeStage = (rawStage.isNotEmpty && rawStage != 'N/A' && rawStage != 'None' && rawStage.toLowerCase() != 'unassigned')
        ? rawStage
        : (hasActiveBatch ? (widget.activeAssignments[0]['lifecycle_stage'] ?? 'Booster').toString() : 'Booster');

    final String displayStage = isFundedAndActive ? activeStage : strings.unassigned;

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
                  child: _buildFilterChip('Hogs', strings.isFilipino ? 'Mga Baboy' : 'My Hogs', totalHogs),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFilterChip('Reports', strings.isFilipino ? 'Mga Ulat' : 'Health Reports', widget.reportsList.length, color: _dangerRed),
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
                        strings.isFilipino ? 'Walang nakatalagang alagang baboy.' : 'No hogs assigned yet.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PiggyTrunkTheme.ptMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.isFilipino ? 'I-aassign ng Farm Admin ang iyong batch dito.' : 'Farm Admin will assign your batch here.',
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
                title: strings.isFilipino ? 'Mga Stage ng Pakain' : 'Feeds Stages',
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
                      strings.isFilipino ? 'Listahan ng Alaga' : 'Hogs Inventory',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '$totalHogs ${strings.hogs} ($healthyHogsCount ${strings.healthy})',
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
                    message: strings.noHogsFound,
                    subtitle: strings.noHogsSubtitle,
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

                    return GestureDetector(
                      onTap: () => _showAddReportDialog(context, hogId),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
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
                                color: isHealthy
                                    ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9))
                                    : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFFEBEE)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.pets_rounded,
                                color: isHealthy ? const Color(0xFF10B981) : const Color(0xFFE53935),
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
                                      color: isDark ? PiggyTrunkTheme.ptTextDark : _brandColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    weight ?? (strings.isFilipino ? 'Walang tala ng timbang' : 'No weight recorded'),
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
                                color: isHealthy
                                    ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9))
                                    : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFFEBEE)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isHealthy ? Icons.check_circle_outline : Icons.error_outline,
                                    size: 14,
                                    color: isHealthy ? const Color(0xFF10B981) : const Color(0xFFE53935),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    rawStatus.toUpperCase(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: isHealthy ? const Color(0xFF10B981) : const Color(0xFFE53935),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: isDark ? PiggyTrunkTheme.ptMutedDark : const Color(0xFFCBD5E1),
                            ),
                          ],
                        ),
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
                      strings.healthReportsActivity,
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
                          color: isDark ? Colors.white : _brandColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? Colors.white : _brandColor).withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 16, color: isDark ? const Color(0xFF0F172A) : Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              strings.addReportButton,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
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
                    message: strings.noHealthReports,
                    subtitle: strings.noHealthReportsSubtitle,
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
                        color: isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
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
                                  color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2),
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
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      timeAgo,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        color: isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted,
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
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                notes,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedTab == key;
    final inactiveBg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
    final inactiveBorder = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
    final inactiveText = isDark ? PiggyTrunkTheme.ptTextDark : _brandColor;
    final selectedBg = isDark ? Colors.white : _brandColor;
    final selectedText = isDark ? const Color(0xFF0F172A) : Colors.white;

    return GestureDetector(
      onTap: () => setState(() => _selectedTab = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : inactiveBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? selectedBg : inactiveBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark ? Colors.white : _brandColor).withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
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
                color: isSelected ? selectedText : inactiveText,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? const Color(0xFF0F172A).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.22))
                    : (color?.withValues(alpha: isDark ? 0.2 : 0.12) ?? (isDark ? const Color(0xFF1E293B) : PiggyTrunkTheme.ptBg)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? selectedText : (color ?? inactiveText),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isUnassigned = badgeText.toLowerCase() == 'unassigned';
    final cardBg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
    final cardBorder = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
    final textColor = isDark ? Colors.white : _brandColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
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
                  color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isUnassigned
                      ? (isDark ? const Color(0xFF1E2D42) : const Color(0xFFF1F5F9))
                      : (isDark ? const Color(0xFF1E2D42) : const Color(0xFFEFF6FF)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUnassigned
                        ? (isDark ? const Color(0xFF3B506D) : const Color(0xFFE2E8F0))
                        : (isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.4) : const Color(0xFFDBEAFE)),
                  ),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isUnassigned ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)) : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasActiveBatch = widget.activeAssignments.isNotEmpty;
    final bool hasInvestment = widget.investedAmount > 0;
    final bool isFundedAndActive = hasActiveBatch && hasInvestment;
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
            // Connecting line
            Positioned(
              top: 16,
              left: stepWidth / 2,
              right: stepWidth / 2,
              child: Row(
                children: List.generate(stages.length - 1, (index) {
                  final isPassed = index < activeIndex;
                  return Expanded(
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: isPassed ? _successGreen : (isDark ? const Color(0xFF334A66) : const Color(0xFFE2E8F0)),
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
                final isPassed = index < activeIndex;
                final isActive = index == activeIndex;

                Color circleColor;
                Widget iconWidget;
                BoxBorder? nodeBorder;

                if (isPassed) {
                  circleColor = _successGreen;
                  iconWidget = const Icon(Icons.check_rounded, size: 16, color: Colors.white);
                } else if (isActive) {
                  circleColor = isDark ? Colors.white : _brandColor;
                  iconWidget = Icon(
                    Icons.priority_high_rounded,
                    size: 18,
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  );
                } else {
                  circleColor = isDark ? const Color(0xFF1E2D42) : const Color(0xFFF1F5F9);
                  nodeBorder = isDark ? Border.all(color: const Color(0xFF3B506D), width: 1.2) : null;
                  iconWidget = Icon(
                    Icons.lock_outline_rounded,
                    size: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFFA0AEC0),
                  );
                }

                final isFuture = !hasInvestment || index > activeIndex;

                return GestureDetector(
                  onTap: () {
                    if (isFundedAndActive && isFuture) {
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
                            border: nodeBorder,
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: (isDark ? Colors.white : _brandColor).withValues(alpha: isDark ? 0.35 : 0.3),
                                      blurRadius: 10,
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
                            fontSize: 10.5,
                            fontWeight: isActive ? FontWeight.w800 : (isPassed ? FontWeight.w700 : FontWeight.w600),
                            color: isActive
                                ? (isDark ? Colors.white : _brandColor)
                                : (isPassed ? _successGreen : (isDark ? const Color(0xFF94A3B8) : const Color(0xFFA0AEC0))),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Stage Progression',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: isDark ? Colors.white : _brandColor,
            ),
          ),
          content: Text(
            'Nais mo bang i-advance ang growth stage ng batch patungong $targetStage?',
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
                      'Kanselahin',
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
                      if (widget.onUpdateLifecycleStage != null) {
                        widget.onUpdateLifecycleStage!(targetStage);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : _brandColor,
                      foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Kumpirmahin',
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
