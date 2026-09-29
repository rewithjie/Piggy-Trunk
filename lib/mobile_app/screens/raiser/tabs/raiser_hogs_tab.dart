import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../../../utils/app_strings.dart';
import '../../../utils/capitalization_formatters.dart';
import '../../../widgets/piggy_toast.dart';
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
  int _selectedHogIndex = 0;
  final Map<String, String> _hogSpecificStages = {};
  BigInt? _selectedBatchAssignmentId;

  @override
  void initState() {
    super.initState();
    _initSelectedBatch();
  }

  @override
  void didUpdateWidget(covariant RaiserHogsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedBatchAssignmentId == null ||
        !widget.activeAssignments.any((a) =>
            BigInt.from(a['assignment_id'] as num) == _selectedBatchAssignmentId)) {
      _initSelectedBatch();
    }
  }

  void _initSelectedBatch() {
    if (widget.selectedAssignmentId != null &&
        widget.activeAssignments.any((a) =>
            BigInt.from(a['assignment_id'] as num) == widget.selectedAssignmentId)) {
      _selectedBatchAssignmentId = widget.selectedAssignmentId;
    } else if (widget.activeAssignments.isNotEmpty) {
      _selectedBatchAssignmentId = BigInt.from(widget.activeAssignments[0]['assignment_id'] as num);
    }
  }

  String _formatReportTime(String? createdAtStr, AppStrings strings) {
    if (createdAtStr == null || createdAtStr.isEmpty) return strings.isFilipino ? 'Kani-kanina lang' : 'Recent';
    try {
      final created = DateTime.parse(createdAtStr);
      return strings.formatRelativeTime(created);
    } catch (_) {
      return strings.isFilipino ? 'Kani-kanina lang' : 'Recent';
    }
  }

  String _formatReadableDateTime(dynamic dateVal) {
    if (dateVal == null) return '';
    try {
      final DateTime dt = (dateVal is DateTime ? dateVal : DateTime.parse(dateVal.toString())).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final m = months[dt.month - 1];
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '$m ${dt.day}, ${dt.year} • $hour:$min $period';
    } catch (_) {
      return dateVal.toString();
    }
  }

  Map<String, dynamic>? _findHog(dynamic hogId) {
    if (hogId == null) return null;
    final idStr = hogId.toString();
    for (var h in widget.hogsList) {
      if (h['hog_id']?.toString() == idStr) {
        return h;
      }
    }
    return null;
  }

  String _getHogDisplayName(dynamic hogId, AppStrings strings) {
    if (hogId == null) return strings.isFilipino ? 'Alagang Baboy' : 'Hog';
    final hog = _findHog(hogId);
    final hogPrefix = strings.isFilipino ? 'Baboy' : 'Hog';
    if (hog != null) {
      if (hog['tag_number'] != null && hog['tag_number'].toString().isNotEmpty) {
        return '$hogPrefix ${hog['tag_number']}';
      }
      final assignId = hog['assignment_id'];
      final batchHogs = assignId != null
          ? widget.hogsList.where((h) => h['assignment_id'] == assignId).toList()
          : widget.hogsList;
      final idx = batchHogs.indexOf(hog);
      final num = idx >= 0 ? (idx + 1) : (widget.hogsList.indexOf(hog) + 1);
      return '$hogPrefix #$num';
    }
    return strings.isFilipino ? 'Alagang Baboy' : 'Hog';
  }

  IconData _getReportIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('fever')) return Icons.thermostat_rounded;
    if (t.contains('poison')) return Icons.warning_amber_rounded;
    if (t.contains('diarrhea')) return Icons.water_drop_outlined;
    if (t.contains('injury')) return Icons.healing_rounded;
    if (t.contains('dead') || t.contains('deceased')) return Icons.dangerous_rounded;
    return Icons.medical_services_rounded;
  }

  Color _getReportColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('fever')) return const Color(0xFFEF4444);
    if (t.contains('injury')) return const Color(0xFFF43F5E);
    if (t.contains('poison')) return const Color(0xFFEA580C);
    if (t.contains('diarrhea')) return const Color(0xFFF59E0B);
    if (t.contains('dead') || t.contains('deceased')) return const Color(0xFF64748B);
    return const Color(0xFFEF4444);
  }

  int _stageNameToId(String stage, bool isBreeding) {
    final s = stage.trim().toLowerCase();
    if (s == 'booster') return 1;
    if (s == 'pre-starter' || s == 'pre starter') return 2;
    if (s == 'starter') return 3;
    if (s == 'grower') return 4;
    if (s == 'finisher' || s == 'breeder') return 5;
    if (s == 'selling' || s == 'lactation') return 6;
    return 1;
  }

  String _stageIdToName(dynamic stageId, bool isBreeding, String fallback) {
    if (stageId == null) return fallback;
    final id = int.tryParse(stageId.toString());
    final fatteningStages = const ['Booster', 'Pre-Starter', 'Starter', 'Grower', 'Finisher', 'Selling'];
    final sowStages = const ['Booster', 'Pre-Starter', 'Starter', 'Grower', 'Breeder', 'Lactation'];
    final list = isBreeding ? sowStages : fatteningStages;
    if (id != null && id >= 1 && id <= list.length) {
      return list[id - 1];
    }
    final s = stageId.toString().trim();
    if (s.isNotEmpty && s != 'null' && s != 'N/A' && int.tryParse(s) == null) {
      return s;
    }
    return fallback;
  }

  String _getHogPigType(Map<String, dynamic> hog, String fallbackType) {
    final rawType = (hog['pig_type'] ?? hog['type_name'] ?? hog['type'] ?? '').toString().trim();
    if (rawType.isNotEmpty && rawType != 'null' && rawType != 'N/A' && rawType != 'None') {
      final l = rawType.toLowerCase();
      return (l == 'sow' || l.contains('breed')) ? 'Sow' : 'Fattening';
    }
    final fallbackLower = fallbackType.toLowerCase();
    return (fallbackLower == 'sow' || fallbackLower.contains('breed')) ? 'Sow' : 'Fattening';
  }

  String _getHogStage(Map<String, dynamic> hog, String fallbackStage, bool isBreeding) {
    final hogId = hog['hog_id']?.toString() ?? '';
    if (hogId.isNotEmpty && _hogSpecificStages.containsKey(hogId)) {
      return _hogSpecificStages[hogId]!;
    }
    final dbStage = hog['stage_id'] ?? hog['lifecycle_stage'] ?? hog['stage'];
    if (dbStage != null) {
      return _stageIdToName(dbStage, isBreeding, 'Booster');
    }
    return 'Booster';
  }

  Future<void> _updateSpecificHogStage(Map<String, dynamic> hog, String targetStage, bool isBreeding) async {
    final hogId = hog['hog_id'];
    final hogIdStr = hogId?.toString() ?? '';
    final int stageNum = _stageNameToId(targetStage, isBreeding);
    final hogName = _getHogDisplayName(hogId, AppStrings.of(context));

    setState(() {
      if (hogIdStr.isNotEmpty) {
        _hogSpecificStages[hogIdStr] = targetStage;
      }
      hog['stage_id'] = stageNum;
    });

    if (hogId != null) {
      try {
        await Supabase.instance.client
            .from('hogs')
            .update({
              'stage_id': stageNum,
              'last_updated': DateTime.now().toIso8601String(),
            })
            .eq('hog_id', hogId);
      } catch (e) {
        debugPrint('Notice updating hog stage_id: $e');
        try {
          await Supabase.instance.client
              .from('hogs')
              .update({'lifecycle_stage': targetStage})
              .eq('hog_id', hogId);
        } catch (_) {}
      }
    }

    if (mounted) {
      PiggyToast.showSuccess(
        context,
        AppStrings.of(context).hogStageUpdatedSuccess(hogName, targetStage),
      );
    }

    try {
      await widget.onRefresh();
    } catch (_) {}
  }

  void _showHogDetailModal(
    BuildContext context,
    Map<String, dynamic> hog,
    int index,
    String fallbackType,
    String fallbackStage,
  ) {
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
    final textColor = isDark ? Colors.white : _brandColor;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final hogId = BigInt.from(hog['hog_id'] as num);
    final tagNumber = hog['tag_number'] ?? '#${index + 1}';
    final rawStatus = (hog['health_status'] ?? 'Healthy').toString();
    final isHealthy = rawStatus.toLowerCase() == 'healthy' || rawStatus.isEmpty;
    final weight = hog['current_weight'] != null
        ? '${hog['current_weight']} kg'
        : (hog['weight'] != null ? '${hog['weight']} kg' : null);
    final hogType = _getHogPigType(hog, fallbackType);
    final isSow = hogType == 'Sow';
    final stages = isSow
        ? const ['Booster', 'Pre-Starter', 'Starter', 'Grower', 'Breeder', 'Lactation']
        : const ['Booster', 'Pre-Starter', 'Starter', 'Grower', 'Finisher', 'Selling'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final currentStageNow = _getHogStage(hog, fallbackStage, isSow);

            return Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with Hog name and close button
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.pets_rounded,
                            color: isDark ? Colors.white : _brandColor,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${strings.isFilipino ? "Baboy" : "Hog"} $tagNumber',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              weight ?? (strings.isFilipino ? 'Walang tala ng timbang' : 'No weight recorded'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFF94A3B8) : PiggyTrunkTheme.ptMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Health badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isHealthy
                              ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9))
                              : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFFEBEE)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          strings.formatStatus(rawStatus).toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isHealthy ? const Color(0xFF10B981) : const Color(0xFFE53935),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Tags Card (Pig Type & Current Feed Stage)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.isFilipino ? 'Uri ng Pag-aalaga' : 'Production Type',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : PiggyTrunkTheme.ptMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isSow
                                      ? (isDark ? const Color(0xFF2E1065).withValues(alpha: 0.35) : const Color(0xFFFAF5FF))
                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSow
                                        ? (isDark ? const Color(0xFF7E22CE) : const Color(0xFFDDD6FE))
                                        : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  isSow ? strings.sowBreedTag : strings.fatteningTag,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isSow
                                        ? (isDark ? const Color(0xFFD8B4FE) : const Color(0xFF6B21A8))
                                        : (isDark ? const Color(0xFFF1F5F9) : _brandColor),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 36, color: borderColor),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.feedStageLabel,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : PiggyTrunkTheme.ptMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.grass_rounded,
                                    size: 14,
                                    color: isDark ? const Color(0xFF94A3B8) : PiggyTrunkTheme.ptMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    currentStageNow,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Interactive Feed Stage Quick Selector
                  Text(
                    strings.isFilipino ? 'Palitan ang Yugto ng Pakain para sa Baboy na Ito:' : 'Update Feed Stage for this Hog:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: stages.map((st) {
                      final isCurrent = st.toLowerCase() == currentStageNow.toLowerCase();
                      return GestureDetector(
                        onTap: () {
                          if (!isCurrent) {
                            Navigator.pop(ctx);
                            _showStageProgressionDialog(context, hog, st, isSow);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? (isDark ? Colors.white : _brandColor)
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCurrent
                                  ? (isDark ? Colors.white : _brandColor)
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isCurrent) ...[
                                Icon(
                                  Icons.check_rounded,
                                  size: 13,
                                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                st,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                  color: isCurrent
                                      ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),

                  // Action Buttons: Focus on Top Timeline & Report Issue
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() => _selectedHogIndex = index);
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.timeline_rounded, size: 16),
                          label: Text(
                            strings.isFilipino ? 'Tingnan sa Timeline' : 'View in Timeline',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            foregroundColor: isDark ? Colors.white : _brandColor,
                            side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showAddReportDialog(context, hogId);
                          },
                          icon: const Icon(Icons.medical_services_outlined, size: 16),
                          label: Text(
                            strings.isFilipino ? 'Mag-ulat' : 'Report Issue',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReportDetailModal(BuildContext context, Map<String, dynamic> report) {
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
    final textColor = isDark ? Colors.white : _brandColor;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final type = (report['report_type'] ?? 'Health Report').toString();
    final notes = (report['description'] ?? report['notes'] ?? '').toString().trim();
    final hogId = report['hog_id'];
    final hogName = _getHogDisplayName(hogId, strings);
    final rawType = (widget.raiserData['pig_type'] ?? '').toString().trim();
    final pigTypeLabel = (rawType.isNotEmpty && rawType != 'N/A' && rawType != 'None')
        ? rawType
        : (widget.activeAssignments.isNotEmpty && widget.activeAssignments[0]['hog_types']?['type_name'] != null
            ? widget.activeAssignments[0]['hog_types']['type_name'].toString()
            : 'Fattening');
    final formattedTime = _formatReadableDateTime(report['created_at']);
    final reportColor = _getReportColor(type);
    final reportIcon = _getReportIcon(type);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: reportColor.withValues(alpha: isDark ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(reportIcon, color: reportColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.isFilipino ? 'Detalye ng Ulat sa Kalusugan' : 'Health Report Details',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            report['report_id'] != null
                                ? 'Report Ref #${report['report_id']}'
                                : (strings.isFilipino ? 'Opisyal na Tala ng Alaga' : 'Official Hog Record'),
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
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.isFilipino ? 'Naisumite na sa Farm Admin at Investor' : 'Submitted to Farm Admin & Investor',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              strings.isFilipino
                                  ? 'Nakatala na sa sistema ang iyong ulat para sa agarang gabay o gamot ng alaga.'
                                  : 'Logged in the system. Farm management and investor are notified for guidance.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        context,
                        icon: Icons.pets_rounded,
                        label: strings.isFilipino ? 'Alagang Baboy' : 'Target Hog',
                        value: '$hogName ($pigTypeLabel)',
                        valueColor: textColor,
                      ),
                      Divider(height: 16, color: borderColor),
                      _buildDetailRow(
                        context,
                        icon: reportIcon,
                        label: strings.isFilipino ? 'Uri ng Ulat' : 'Report Type',
                        value: strings.formatStatus(type),
                        valueColor: reportColor,
                      ),
                      Divider(height: 16, color: borderColor),
                      _buildDetailRow(
                        context,
                        icon: Icons.calendar_today_rounded,
                        label: strings.isFilipino ? 'Petsa at Oras' : 'Date & Time',
                        value: formattedTime.isNotEmpty ? formattedTime : 'Kamakailan',
                        valueColor: textColor,
                      ),
                      Divider(height: 16, color: borderColor),
                      _buildDetailRow(
                        context,
                        icon: Icons.info_outline_rounded,
                        label: strings.isFilipino ? 'Katayuan' : 'Status',
                        value: strings.isFilipino ? 'Naiulat / Aktibo' : 'Reported / Active',
                        valueColor: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.isFilipino ? 'Inilagay na Obserbasyon / Tala' : 'Reported Observation / Notes',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.format_quote_rounded, size: 20, color: reportColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notes.isNotEmpty
                              ? notes
                              : (strings.isFilipino ? 'Walang karagdagang detalye na inilagay.' : 'No additional details provided.'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: notes.isNotEmpty
                                ? textColor
                                : (isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted),
                            fontStyle: notes.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : _brandColor,
                      foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      strings.isFilipino ? 'Naintindihan' : 'Close',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            color: isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: valueColor ?? (isDark ? Colors.white : _brandColor),
            ),
          ),
        ),
      ],
    );
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
            final strings = AppStrings.of(modalCtx);
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final bg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
            final textColor = isDark ? Colors.white : _brandColor;
            final inputBg = isDark ? const Color(0xFF1E2D42) : const Color(0xFFF8FAFC);
            final inputBorder = isDark ? const Color(0xFF3B506D) : const Color(0xFFE2E8F0);
            final dropdownBg = isDark ? const Color(0xFF1E2D42) : Colors.white;
            final rawType = (widget.raiserData['pig_type'] ?? '').toString().trim();
            final pigTypeLabel = (rawType.isNotEmpty && rawType != 'N/A' && rawType != 'None')
                ? rawType
                : (widget.activeAssignments.isNotEmpty && widget.activeAssignments[0]['hog_types']?['type_name'] != null
                    ? widget.activeAssignments[0]['hog_types']['type_name'].toString()
                    : 'Fattening');

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
                                strings.healthReportTitle,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                strings.healthReportSubtitle,
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
                      strings.selectHog,
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
                              strings.noHogsAssignedCurrently,
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
                                child: Text('${strings.isFilipino ? "Baboy" : "Hog"} $tag ($pigTypeLabel)'),
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
                      strings.reportType,
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
                      items: [
                        DropdownMenuItem(value: 'Food Poisoning', child: Text(strings.foodPoisoning)),
                        DropdownMenuItem(value: 'Fever', child: Text(strings.fever)),
                        DropdownMenuItem(value: 'Diarrhea', child: Text(strings.diarrhea)),
                        DropdownMenuItem(value: 'Injury', child: Text(strings.injury)),
                        DropdownMenuItem(value: 'Dead', child: Text(strings.deceasedReport)),
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
                      strings.additionalDetails,
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
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.sentences,
                      inputFormatters: const [
                        CapitalizeSentencesInputFormatter(),
                      ],
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textColor),
                      decoration: InputDecoration(
                        hintText: strings.healthNotesHint,
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
                              strings.cancel,
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
                              strings.submitReportAction,
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
                  color: isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : _brandColor).withValues(alpha: isDark ? 0.15 : 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.assignment_late_outlined,
                            size: 28,
                            color: isDark ? Colors.white : _brandColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        strings.isFilipino ? 'Walang nakatalagang alagang baboy.' : 'No hogs assigned yet.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF18314F),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        strings.isFilipino ? 'I-aassign ng Farm Admin ang iyong batch dito.' : 'Farm Admin will assign your batch here.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // ==================== BATCH SELECTION & FILTERING (1:MANY) ====================
              Builder(
                builder: (context) {
                  final selectedAssignment = widget.activeAssignments.firstWhere(
                    (a) =>
                        _selectedBatchAssignmentId != null &&
                        BigInt.from(a['assignment_id'] as num) == _selectedBatchAssignmentId,
                    orElse: () => widget.activeAssignments.isNotEmpty
                        ? widget.activeAssignments[0]
                        : <String, dynamic>{},
                  );

                  final String batchType = (selectedAssignment['hog_types']?['type_name'] ??
                          selectedAssignment['pig_type'] ??
                          displayPigType)
                      .toString();
                  final bool isBatchSow = batchType.toLowerCase() == 'sow' ||
                      batchType.toLowerCase().contains('breed');

                  final visibleHogs = widget.hogsList.where((h) {
                    if (_selectedBatchAssignmentId == null || widget.activeAssignments.length <= 1) {
                      return true;
                    }
                    final aId = h['assignment_id'];
                    if (aId == null) return true;
                    return BigInt.from(aId as num) == _selectedBatchAssignmentId;
                  }).toList();

                  final selectedHog = visibleHogs.isNotEmpty
                      ? visibleHogs[_selectedHogIndex.clamp(0, visibleHogs.length - 1)]
                      : null;
                  final String currentHogType = selectedHog != null
                      ? _getHogPigType(selectedHog, batchType)
                      : batchType;
                  final bool isCurrentBreeding = isBatchSow || currentHogType.toLowerCase() == 'sow';
                  final String currentHogStage = selectedHog != null
                      ? _getHogStage(selectedHog, displayStage, isCurrentBreeding)
                      : displayStage;
                  final List<String> currentStages = (isFundedAndActive && isCurrentBreeding)
                      ? const ['Booster', 'Pre-Starter', 'Starter', 'Grower', 'Breeder', 'Lactation']
                      : const ['Booster', 'Pre-Starter', 'Starter', 'Grower', 'Finisher', 'Selling'];

                  final int batchHogsCount = visibleHogs.length;
                  final int batchHealthyCount = visibleHogs.where((h) {
                    final raw = (h['health_status'] ?? 'Healthy').toString().toLowerCase();
                    return raw == 'healthy' || raw.isEmpty;
                  }).length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Batch Selector Chips (rendered if multiple batches exist for 1:Many raiser)
                      if (widget.activeAssignments.length > 1) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.layers_outlined,
                              size: 15,
                              color: isDark ? const Color(0xFF94A3B8) : PiggyTrunkTheme.ptMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              strings.isFilipino ? 'Piliin ang Batch ng Alaga:' : 'Select Active Batch:',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF94A3B8) : PiggyTrunkTheme.ptMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: widget.activeAssignments.map((assign) {
                              final aId = BigInt.from(assign['assignment_id'] as num);
                              final isSelected = _selectedBatchAssignmentId == aId;
                              final batchName = assign['batches']?['batch_name'] ??
                                  assign['batch_name'] ??
                                  'Batch #${assign['batch_id'] ?? aId}';
                              final type = (assign['hog_types']?['type_name'] ?? assign['pig_type'] ?? 'Fattening').toString();
                              final isSowType = type.toLowerCase() == 'sow' || type.toLowerCase().contains('breed');
                              final hogsInBatch = widget.hogsList.where((h) {
                                final hAid = h['assignment_id'];
                                return hAid != null && BigInt.from(hAid as num) == aId;
                              }).length;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedBatchAssignmentId = aId;
                                    _selectedHogIndex = 0;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isDark ? Colors.white : _brandColor)
                                        : (isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? (isDark ? Colors.white : _brandColor)
                                          : (isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: (isDark ? Colors.white : _brandColor).withValues(alpha: isDark ? 0.25 : 0.15),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isSowType ? Icons.favorite_rounded : Icons.agriculture_rounded,
                                        size: 15,
                                        color: isSelected
                                            ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                            : (isDark ? const Color(0xFF94A3B8) : _brandColor),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            batchName,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: isSelected
                                                  ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                                  : textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$type • $hogsInBatch ${strings.hogs}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))
                                                  : PiggyTrunkTheme.ptMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // ==================== FEEDS STAGES TIMELINE CARD ====================
                      _buildFeedsCard(
                        title: strings.isFilipino ? 'Mga Stage ng Pakain' : 'Feeds Stages',
                        badgeText: isFundedAndActive
                            ? (isCurrentBreeding ? strings.sowBreedTag : strings.fatteningTag)
                            : strings.unassigned,
                        stages: currentStages,
                        activeStage: currentHogStage,
                        targetHog: selectedHog,
                        isBreeding: isCurrentBreeding,
                        fallbackType: batchType,
                        fallbackStage: displayStage,
                        hogs: visibleHogs,
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
                              '$batchHogsCount ${strings.hogs} ($batchHealthyCount ${strings.healthy})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: PiggyTrunkTheme.ptMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (visibleHogs.isEmpty) ...[
                          RaiserEmptyState(
                            icon: Icons.pets_outlined,
                            message: strings.noHogsFound,
                            subtitle: strings.noHogsSubtitle,
                          ),
                        ] else ...[
                          ...visibleHogs.asMap().entries.map((entry) {
                            final index = entry.key;
                            final hog = entry.value;
                            final rawStatus = (hog['health_status'] ?? 'Healthy').toString();
                            final isHealthy = rawStatus.toLowerCase() == 'healthy' || rawStatus.isEmpty;
                            final tagNumber = hog['tag_number'] ?? '#${index + 1}';
                            final weight = hog['current_weight'] != null
                                ? '${hog['current_weight']} kg'
                                : (hog['weight'] != null ? '${hog['weight']} kg' : null);
                            final hogType = _getHogPigType(hog, batchType);
                            final isSow = hogType == 'Sow';
                            final hogStage = _getHogStage(hog, displayStage, isSow);

                            return GestureDetector(
                              onTap: () => _showHogDetailModal(context, hog, index, batchType, displayStage),
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
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.pets_rounded,
                                          color: isDark ? Colors.white : _brandColor,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${strings.isFilipino ? "Baboy" : "Hog"} $tagNumber',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? Colors.white : _brandColor,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              // Distinct Fattening vs Sow/Breed Tag
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: isSow
                                                      ? (isDark ? const Color(0xFF2E1065).withValues(alpha: 0.35) : const Color(0xFFFAF5FF))
                                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: isSow
                                                        ? (isDark ? const Color(0xFF7E22CE) : const Color(0xFFDDD6FE))
                                                        : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: Text(
                                                  isSow ? strings.sowBreedTag : strings.fatteningTag,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: isSow
                                                        ? (isDark ? const Color(0xFFD8B4FE) : const Color(0xFF6B21A8))
                                                        : (isDark ? const Color(0xFFF1F5F9) : _brandColor),
                                                  ),
                                                ),
                                              ),
                                              // Specific Feed Stage Tag
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.grass_rounded,
                                                      size: 11,
                                                      color: isDark ? const Color(0xFF94A3B8) : PiggyTrunkTheme.ptMuted,
                                                    ),
                                                    const SizedBox(width: 3.5),
                                                    Text(
                                                      hogStage,
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: isDark ? const Color(0xFFE2E8F0) : _brandColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            weight ?? (strings.isFilipino ? 'Walang tala ng timbang' : 'No weight recorded'),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? const Color(0xFF94A3B8) : PiggyTrunkTheme.ptMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
                                        size: 13,
                                        color: isHealthy ? const Color(0xFF10B981) : const Color(0xFFE53935),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        strings.formatStatus(rawStatus).toUpperCase(),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: isHealthy ? const Color(0xFF10B981) : const Color(0xFFE53935),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 13,
                                  color: isDark ? PiggyTrunkTheme.ptMutedDark : const Color(0xFFCBD5E1),
                                ),
                              ],
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
                    final notes = (report['description'] ?? report['notes'] ?? '').toString().trim();
                    final hogId = report['hog_id'];
                    final hogName = _getHogDisplayName(hogId, strings);
                    final timeAgo = _formatReportTime(report['created_at'], strings);
                    final reportColor = _getReportColor(type);
                    final reportIcon = _getReportIcon(type);

                    return GestureDetector(
                      onTap: () => _showReportDetailModal(context, report),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Icon, Title & Hog chip, and Status badge
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: reportColor.withValues(alpha: isDark ? 0.25 : 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    reportIcon,
                                    color: reportColor,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        strings.formatStatus(type),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.pets_rounded,
                                              size: 11,
                                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              hogName,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF10B981)),
                                      const SizedBox(width: 4),
                                      Text(
                                        strings.isFilipino ? 'Naiulat' : 'Reported',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Raiser Observation Box (Fixes the missing notes issue!)
                            if (notes.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border(
                                    left: BorderSide(color: reportColor, width: 3),
                                    top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                    right: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                    bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.format_quote_rounded, size: 14, color: reportColor),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        notes,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: isDark ? Colors.white : const Color(0xFF334155),
                                          fontWeight: FontWeight.w500,
                                          height: 1.35,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),
                            // Footer: Timestamp and "View Details" prompt
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 13,
                                      color: isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted,
                                    ),
                                    const SizedBox(width: 4),
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
                                Row(
                                  children: [
                                    Text(
                                      strings.isFilipino ? 'Tingnan ang detalye' : 'View details',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : _brandColor,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 10,
                                      color: isDark ? Colors.white : _brandColor,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                      ],
                    ],
                  ],
                );
              },
            ),
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
    final inactiveText = isDark ? Colors.white : _brandColor;
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
    Map<String, dynamic>? targetHog,
    required bool isBreeding,
    required String fallbackType,
    required String fallbackStage,
    List<Map<String, dynamic>>? hogs,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = AppStrings.of(context);
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
          // Header Row: Title & Pig Type Badge
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
                      : isBreeding
                          ? (isDark ? const Color(0xFF2E1065).withValues(alpha: 0.35) : const Color(0xFFFAF5FF))
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUnassigned
                        ? (isDark ? const Color(0xFF3B506D) : const Color(0xFFE2E8F0))
                        : isBreeding
                            ? (isDark ? const Color(0xFF7E22CE) : const Color(0xFFDDD6FE))
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  ),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isUnassigned
                        ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
                        : isBreeding
                            ? (isDark ? const Color(0xFFD8B4FE) : const Color(0xFF6B21A8))
                            : (isDark ? const Color(0xFFF1F5F9) : _brandColor),
                  ),
                ),
              ),
            ],
          ),

          // Hog Switcher Tab Bar (when there are multiple hogs in batch!)
          Builder(
            builder: (context) {
              final effectiveHogs = hogs ?? widget.hogsList;
              if (effectiveHogs.length <= 1) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: effectiveHogs.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final h = entry.value;
                      final isSelected = _selectedHogIndex == idx;
                      final tag = h['tag_number'] ?? '#${idx + 1}';
                      final hType = _getHogPigType(h, fallbackType);
                      final hIsBreed = hType.toLowerCase() == 'sow';
                      final hStage = _getHogStage(h, fallbackStage, hIsBreed);

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedHogIndex = idx),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.pets_rounded,
                                      size: 13,
                                      color: isSelected ? (isDark ? Colors.white : _brandColor) : PiggyTrunkTheme.ptMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${strings.isFilipino ? "Baboy" : "Hog"} $tag',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected ? (isDark ? Colors.white : _brandColor) : PiggyTrunkTheme.ptMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hStage,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? (isDark ? const Color(0xFFF1F5F9) : _brandColor)
                                        : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          _buildTimeline(stages, activeStage, targetHog, isBreeding),
        ],
      ),
    );
  }

  Widget _buildTimeline(
    List<String> stages,
    String activeStage,
    Map<String, dynamic>? targetHog,
    bool isBreeding,
  ) {
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
                      final effectiveHog = targetHog ?? (widget.hogsList.isNotEmpty ? widget.hogsList[0] : null);
                      if (effectiveHog != null) {
                        _showStageProgressionDialog(context, effectiveHog, stages[index], isBreeding);
                      }
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

  void _showStageProgressionDialog(
    BuildContext context,
    Map<String, dynamic> targetHog,
    String targetStage,
    bool isBreeding,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = AppStrings.of(context);
    final hogId = targetHog['hog_id'];
    final hogName = _getHogDisplayName(hogId, strings);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            strings.stageProgressionTitle,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: isDark ? Colors.white : _brandColor,
            ),
          ),
          content: Text(
            strings.advanceHogStagePrompt(hogName, targetStage),
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
                      strings.cancel,
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
                      _updateSpecificHogStage(targetHog, targetStage, isBreeding);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : _brandColor,
                      foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      strings.confirm,
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
