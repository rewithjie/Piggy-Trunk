import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../../../utils/app_strings.dart';

class PartnerLifecycleTab extends StatefulWidget {
  final List<Map<String, dynamic>> projectsList;
  final String? batchName;
  final String? raiserName;
  final String currentStage;
  final String hogType;
  final List<Map<String, dynamic>> hogsList;
  final bool hasActiveProject;
  final List<Map<String, dynamic>> activitiesList;
  final Future<void> Function() onRefresh;
  final VoidCallback? onNavigateToBatches;

  const PartnerLifecycleTab({
    super.key,
    this.projectsList = const [],
    this.batchName,
    this.raiserName,
    this.currentStage = 'Booster',
    this.hogType = 'Fattening',
    this.hogsList = const [],
    this.hasActiveProject = false,
    this.activitiesList = const [],
    required this.onRefresh,
    this.onNavigateToBatches,
  });

  @override
  State<PartnerLifecycleTab> createState() => _PartnerLifecycleTabState();
}

class _PartnerLifecycleTabState extends State<PartnerLifecycleTab> {
  static const Color _brandColor = Color(0xFF18314F);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _dangerRed = Color(0xFFEF4444);

  static const List<String> _fatteningStages = [
    'Booster',
    'Pre-Starter',
    'Starter',
    'Grower',
    'Finisher',
    'Selling',
  ];

  static const List<String> _sowStages = [
    'Booster',
    'Pre-Starter',
    'Starter',
    'Grower',
    'Breeder',
    'Lactation',
  ];

  int _selectedProjectIndex = 0;
  int _selectedHogIndex = 0;

  Map<String, dynamic>? get _currentProject {
    if (widget.projectsList.isNotEmpty) {
      final safeIdx = _selectedProjectIndex.clamp(0, widget.projectsList.length - 1);
      return widget.projectsList[safeIdx];
    }
    return null;
  }

  String get _effectiveBatchName {
    final proj = _currentProject;
    if (proj != null && proj['batch_name'] != null && proj['batch_name'].toString().isNotEmpty) {
      return proj['batch_name'].toString();
    }
    return widget.batchName ?? 'Active Batch';
  }

  String get _effectiveRaiserName {
    final proj = _currentProject;
    if (proj != null) {
      final name = (proj['assigned_raiser'] ?? proj['raiser_name'])?.toString();
      if (name != null && name.isNotEmpty && name != 'null') {
        return name;
      }
    }
    return widget.raiserName ?? 'Assigned Raiser';
  }

  String get _effectiveRaiserLocation {
    final proj = _currentProject;
    if (proj != null) {
      final loc = (proj['address'] ?? proj['location'])?.toString();
      if (loc != null && loc.isNotEmpty && loc != 'null') {
        return loc;
      }
    }
    return 'Farm Location Not Set';
  }

  String get _effectiveRaiserPhone {
    final proj = _currentProject;
    if (proj != null) {
      final ph = (proj['phone'] ?? proj['contact'])?.toString();
      if (ph != null && ph.isNotEmpty && ph != 'null') {
        return ph;
      }
    }
    return 'N/A';
  }

  List<Map<String, dynamic>> get _effectiveHogs {
    final proj = _currentProject;
    if (proj != null && proj['hogs'] is List && (proj['hogs'] as List).isNotEmpty) {
      return List<Map<String, dynamic>>.from(proj['hogs']);
    }
    if (widget.hogsList.isNotEmpty) {
      return widget.hogsList;
    }
    if (proj != null) {
      final int count = (proj['total_hogs'] as num?)?.toInt() ?? 15;
      if (count > 0) {
        final isSow = (proj['hog_type'] ?? '').toString().toLowerCase().contains('sow');
        final stage = (proj['stage'] ?? proj['lifecycle_stage'] ?? 'Grower').toString();
        final half = (count / 2).ceil();
        return List.generate(count, (i) {
          final hogIsSow = (isSow && i >= half) || (proj['hog_type'] ?? '').toString().toLowerCase() == 'sow';
          final sName = hogIsSow ? 'Booster' : stage;
          return {
            'hog_id': i + 1,
            'tag_number': 'HOG-${i + 1}',
            'index': i + 1,
            'pig_type': hogIsSow ? 'Sow' : 'Fattening',
            'stage': sName,
            'health_status': 'Healthy',
            'status': 'active',
          };
        });
      }
    }
    return [];
  }

  bool get _hasAnyActiveBatch {
    return widget.hasActiveProject || widget.projectsList.isNotEmpty || widget.hogsList.isNotEmpty;
  }

  String _getHogPigType(Map<String, dynamic> hog, String fallbackType) {
    final raw = (hog['pig_type'] ?? hog['type_name'] ?? hog['type'] ?? '').toString().trim();
    if (raw.isNotEmpty && raw != 'null' && raw != 'N/A' && raw != 'None') {
      final l = raw.toLowerCase();
      return (l == 'sow' || l.contains('breed')) ? 'Sow' : 'Fattening';
    }
    final fallbackLower = fallbackType.toLowerCase();
    return (fallbackLower == 'sow' || fallbackLower.contains('breed')) ? 'Sow' : 'Fattening';
  }

  String _getHogStage(Map<String, dynamic> hog, String fallbackStage, bool isBreeding) {
    final stages = isBreeding ? _sowStages : _fatteningStages;
    final sId = hog['stage_id'];
    if (sId != null) {
      final id = int.tryParse(sId.toString());
      if (id != null && id >= 1 && id <= stages.length) {
        return stages[id - 1];
      }
    }
    final rawStage = (hog['stage'] ?? hog['lifecycle_stage'])?.toString().trim();
    if (rawStage != null && rawStage.isNotEmpty && rawStage != 'null') {
      for (final st in stages) {
        if (st.toLowerCase() == rawStage.toLowerCase()) return st;
      }
      return rawStage;
    }
    return fallbackStage.isNotEmpty ? fallbackStage : 'Booster';
  }

  Map<String, String> _getStageInfo(String stageName, bool isSow) {
    final s = stageName.trim().toLowerCase();
    if (isSow) {
      if (s.contains('boost')) {
        return {
          'duration': 'Day 1 - 30',
          'purpose': 'Early nutrition and immune defense development for replacement breeding prospects.',
          'feed': 'Booster Micro-pellets (20-22% CP)',
        };
      } else if (s.contains('pre')) {
        return {
          'duration': 'Day 31 - 60',
          'purpose': 'Skeletal structure foundation and reproductive organ health initialization.',
          'feed': 'Pre-Starter Pellets (18-20% CP)',
        };
      } else if (s.contains('start')) {
        return {
          'duration': 'Day 61 - 90',
          'purpose': 'Gilt selection, bone density development, and daily growth rate optimization.',
          'feed': 'Starter Mash / Pellets',
        };
      } else if (s.contains('grow')) {
        return {
          'duration': 'Day 91 - 150',
          'purpose': 'Targeted body conditioning, frame expansion, and reproductive maturity priming.',
          'feed': 'Grower Conditioning Feeds',
        };
      } else if (s.contains('breed')) {
        return {
          'duration': 'Day 151 - 210',
          'purpose': 'Active breeding cycle management, ovulation tracking, and gestation support.',
          'feed': 'Gestation & Breeder Mash',
        };
      } else {
        return {
          'duration': 'Day 211 - 270',
          'purpose': 'Post-farrowing maternal nourishment, high-yield milk production, and piglet weaning.',
          'feed': 'Lactation High-Energy Ration',
        };
      }
    } else {
      if (s.contains('boost')) {
        return {
          'duration': 'Day 1 - 30',
          'purpose': 'Post-weaning gut health preservation, rapid digestive tract enzyme development.',
          'feed': 'Booster Micro-pellets (20-22% CP)',
        };
      } else if (s.contains('pre')) {
        return {
          'duration': 'Day 31 - 60',
          'purpose': 'Smooth transition from milk boosters to solid cereal feeds with high digestibility.',
          'feed': 'Pre-Starter Crumble',
        };
      } else if (s.contains('start')) {
        return {
          'duration': 'Day 61 - 90',
          'purpose': 'Accelerating muscle development, lean tissue deposition, and frame scaling.',
          'feed': 'Starter Pellets (16-18% CP)',
        };
      } else if (s.contains('grow')) {
        return {
          'duration': 'Day 91 - 120',
          'purpose': 'Maximum average daily weight gain (ADG) and efficient feed conversion ratio (FCR).',
          'feed': 'Grower Mash / Pellets',
        };
      } else if (s.contains('finish')) {
        return {
          'duration': 'Day 121 - 150',
          'purpose': 'Target market weight accumulation (95-110 kg) and optimal carcass meat quality.',
          'feed': 'Finisher Feed (13-14% CP)',
        };
      } else {
        return {
          'duration': 'Day 151+',
          'purpose': 'Final pre-market evaluation, commercial dispatch, and revenue liquidation.',
          'feed': 'Maintenance Ration / Market Prep',
        };
      }
    }
  }

  void _showBatchPickerModal(BuildContext parentContext) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : _brandColor;
    final surfaceBg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
    final borderColor = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
    final mutedColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: surfaceBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: mutedColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _brandColor.withValues(alpha: isDark ? 0.25 : 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.inventory_2_rounded, size: 20, color: isDark ? Colors.white : _brandColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Funded Batch',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'Switch active batch to monitor lifecycle progress',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: mutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: mutedColor,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: borderColor),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: widget.projectsList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final p = widget.projectsList[index];
                      final isSelected = _selectedProjectIndex == index;
                      final bName = p['batch_name'] ?? 'Batch #${index + 1}';
                      final rName = (p['assigned_raiser'] ?? p['raiser_name'] ?? 'Assigned Raiser').toString();
                      final pType = (p['hog_type'] ?? 'Fattening').toString();
                      final hogs = (p['hogs'] as List?)?.length ?? p['total_hogs'] ?? 0;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedProjectIndex = index;
                            _selectedHogIndex = 0;
                          });
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? const Color(0xFF1E2D42) : const Color(0xFFF1F5F9))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? const Color(0xFF3B82F6) : _brandColor)
                                  : borderColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark ? Colors.white : _brandColor)
                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.pets_rounded,
                                    size: 18,
                                    color: isSelected
                                        ? (isDark ? _brandColor : Colors.white)
                                        : mutedColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected
                                            ? (isDark ? Colors.white : _brandColor)
                                            : textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Raiser: $rName • $hogs Hogs ($pType)',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        color: mutedColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: isDark ? const Color(0xFF38BDF8) : _brandColor,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

    final tagNumber = hog['tag_number'] ?? '#${index + 1}';
    final rawStatus = (hog['health_status'] ?? 'Healthy').toString();
    final isHealthy = rawStatus.toLowerCase() == 'healthy' || rawStatus.isEmpty;
    final weight = hog['current_weight'] != null
        ? '${hog['current_weight']} kg'
        : (hog['weight'] != null ? '${hog['weight']} kg' : null);
    final hogType = _getHogPigType(hog, fallbackType);
    final isSow = hogType == 'Sow';
    final currentStage = _getHogStage(hog, fallbackStage, isSow);
    final stageInfo = _getStageInfo(currentStage, isSow);
    final isHogCompleted = currentStage.toLowerCase() == 'selling' || currentStage.toLowerCase() == 'lactation';

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
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag handle
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

              // Header Row
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
                        if (weight != null && weight.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            weight,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF94A3B8) : PiggyTrunkTheme.ptMuted,
                            ),
                          ),
                        ],
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isHealthy ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                          size: 13,
                          color: isHealthy ? _successGreen : _dangerRed,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isHealthy ? strings.healthy : rawStatus,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isHealthy ? _successGreen : _dangerRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Production Type & Current Stage
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
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              isSow ? strings.sowBreedTag : strings.fatteningTag,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFFF1F5F9) : _brandColor,
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
                          Text(
                            isHogCompleted ? '$currentStage (Complete)' : currentStage,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isHogCompleted ? _successGreen : textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Stage Guidance Details
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      icon: Icons.access_time_rounded,
                      label: 'Typical Timeline',
                      value: stageInfo['duration'] ?? 'Standard Phase',
                      textColor: textColor,
                      mutedColor: isDark ? const Color(0xFF94A3B8) : PiggyTrunkTheme.ptMuted,
                    ),
                    Divider(height: 16, color: borderColor),
                    _buildDetailRow(
                      icon: Icons.restaurant_rounded,
                      label: 'Recommended Feed',
                      value: stageInfo['feed'] ?? 'Standard Ration',
                      textColor: textColor,
                      mutedColor: isDark ? const Color(0xFF94A3B8) : PiggyTrunkTheme.ptMuted,
                    ),
                    Divider(height: 16, color: borderColor),
                    _buildDetailRow(
                      icon: Icons.track_changes_rounded,
                      label: 'Growth Objective',
                      value: stageInfo['purpose'] ?? 'Healthy daily development',
                      textColor: textColor,
                      mutedColor: isDark ? const Color(0xFF94A3B8) : PiggyTrunkTheme.ptMuted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Raiser info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF142032) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_pin_circle_rounded,
                      size: 18,
                      color: isDark ? const Color(0xFF38BDF8) : _brandColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Managed by $_effectiveRaiserName ($_effectiveBatchName)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Close button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    strings.close,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: isDark ? Colors.white : _brandColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: mutedColor),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: mutedColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  void _showStageInfoDialog(BuildContext context, String stageName, bool isSow) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final info = _getStageInfo(stageName, isSow);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _brandColor.withValues(alpha: isDark ? 0.25 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.timeline_rounded, color: isDark ? Colors.white : _brandColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$stageName Stage',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16.5,
                    color: isDark ? Colors.white : _brandColor,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isSow ? 'Sow / Breeding Track' : 'Fattening Track',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : _brandColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Duration: ${info['duration']}',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Recommended Feed: ${info['feed']}',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                info['purpose'] ?? '',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : PiggyTrunkTheme.ptMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Close',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF38BDF8) : _brandColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : _brandColor;
    final surfaceBg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
    final borderColor = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
    final mutedColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;
    final strings = AppStrings.of(context);

    if (!_hasAnyActiveBatch) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        color: _brandColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: surfaceBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
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
                      Icons.timeline_rounded,
                      size: 28,
                      color: isDark ? Colors.white : _brandColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Active Funded Batch',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Invest in an active livestock batch to monitor hog growth, feeds stages, and raiser updates in real-time.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: mutedColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                if (widget.onNavigateToBatches != null)
                  ElevatedButton.icon(
                    onPressed: widget.onNavigateToBatches,
                    icon: const Icon(Icons.inventory_2_rounded, size: 16),
                    label: const Text('Browse Investment Batches'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : _brandColor,
                      foregroundColor: isDark ? _brandColor : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final visibleHogs = _effectiveHogs;
    final int totalHogs = visibleHogs.length;
    final int healthyCount = visibleHogs.where((h) {
      final s = (h['health_status'] ?? 'Healthy').toString().toLowerCase();
      return s == 'healthy' || s.isEmpty;
    }).length;

    // Resolve currently selected hog
    final selectedHog = visibleHogs.isNotEmpty
        ? visibleHogs[_selectedHogIndex.clamp(0, visibleHogs.length - 1)]
        : null;

    final String selectedHogType = selectedHog != null
        ? _getHogPigType(selectedHog, widget.hogType)
        : (widget.hogType.toLowerCase().contains('sow') ? 'Sow' : 'Fattening');

    final bool isCurrentSow = selectedHogType == 'Sow';
    final List<String> currentStages = isCurrentSow ? _sowStages : _fatteningStages;

    final String selectedHogStage = selectedHog != null
        ? _getHogStage(selectedHog, widget.currentStage, isCurrentSow)
        : (widget.currentStage.isNotEmpty ? widget.currentStage : 'Booster');

    final stageInfo = _getStageInfo(selectedHogStage, isCurrentSow);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: _brandColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== TOP BATCH HEADER & SELECTOR ====================
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: surfaceBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: InkWell(
                onTap: widget.projectsList.length > 1
                    ? () => _showBatchPickerModal(context)
                    : null,
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _brandColor.withValues(alpha: isDark ? 0.25 : 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.pets_rounded, size: 16, color: isDark ? Colors.white : _brandColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Batch:',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: mutedColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _effectiveBatchName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Raiser: $_effectiveRaiserName • $totalHogs Hogs',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: mutedColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (widget.projectsList.length > 1) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              strings.isFilipino ? 'Palitan' : 'Change',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF38BDF8) : _brandColor,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.unfold_more_rounded,
                              size: 14,
                              color: isDark ? const Color(0xFF38BDF8) : _brandColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ==================== FEEDS STAGES TIMELINE CARD ====================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
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
                  // Header Row: Feeds Stages Title & Track Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        strings.isFilipino ? 'Mga Stage ng Pakain' : 'Feeds Stages',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          isCurrentSow ? strings.sowBreedTag : strings.fatteningTag,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFF1F5F9) : _brandColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ==================== HOG SWITCHER PILL ROW ====================
                  if (visibleHogs.length > 1) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: visibleHogs.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final h = entry.value;
                            final isSelected = _selectedHogIndex == idx;
                            final tag = h['tag_number'] ?? '#${idx + 1}';
                            final hIsSow = _getHogPigType(h, widget.hogType) == 'Sow';
                            final hStage = _getHogStage(h, widget.currentStage, hIsSow);
                            final isHogDone = hStage.toLowerCase() == 'selling' || hStage.toLowerCase() == 'lactation';

                            return Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => setState(() => _selectedHogIndex = idx),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
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
                                            size: 12,
                                            color: isSelected
                                                ? (isDark ? Colors.white : _brandColor)
                                                : mutedColor,
                                          ),
                                          const SizedBox(width: 3),
                                          Flexible(
                                            child: Text(
                                              '$tag',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11.5,
                                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                color: isSelected
                                                    ? (isDark ? Colors.white : _brandColor)
                                                    : mutedColor,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (isHogDone) ...[
                                            const Icon(Icons.check_rounded, size: 10, color: _successGreen),
                                            const SizedBox(width: 2),
                                          ],
                                          Flexible(
                                            child: Text(
                                              hStage,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10.5,
                                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                color: isHogDone
                                                    ? _successGreen
                                                    : (isSelected
                                                        ? (isDark ? const Color(0xFFF1F5F9) : _brandColor)
                                                        : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ==================== CONNECTED TIMELINE STEPPER ====================
                  _buildTimeline(
                    stages: currentStages,
                    activeStage: selectedHogStage,
                    isSow: isCurrentSow,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 20),

                  // ==================== ACTIVE STAGE GUIDANCE PILL ====================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF142032) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF24334A) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: _brandColor.withValues(alpha: isDark ? 0.3 : 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.restaurant_rounded,
                                size: 14,
                                color: isDark ? Colors.white : _brandColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$selectedHogStage: ${stageInfo['feed']}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                            ),
                            Text(
                              stageInfo['duration'] ?? '',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: mutedColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stageInfo['purpose'] ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: mutedColor,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ==================== HOGS INVENTORY SECTION ====================
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
                  '$totalHogs ${strings.hogs} ($healthyCount ${strings.healthy})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (visibleHogs.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                decoration: BoxDecoration(
                  color: surfaceBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Center(
                  child: Text(
                    'No individual hogs recorded for this batch yet.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: mutedColor,
                    ),
                  ),
                ),
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
                final hogType = _getHogPigType(hog, widget.hogType);
                final isSow = hogType == 'Sow';
                final hogStage = _getHogStage(hog, widget.currentStage, isSow);
                final isHogCompleted = hogStage.toLowerCase() == 'selling' || hogStage.toLowerCase() == 'lactation';

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedHogIndex = index);
                    _showHogDetailModal(context, hog, index, widget.hogType, widget.currentStage);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _selectedHogIndex == index
                            ? (isDark ? const Color(0xFF3B82F6) : _brandColor)
                            : borderColor,
                        width: _selectedHogIndex == index ? 1.5 : 1,
                      ),
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
                              size: 20,
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  // Track Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      isSow ? strings.sowBreedTag : strings.fatteningTag,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFFF1F5F9) : _brandColor,
                                      ),
                                    ),
                                  ),
                                  // Stage Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: isHogCompleted
                                          ? _successGreen.withValues(alpha: isDark ? 0.22 : 0.12)
                                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isHogCompleted
                                            ? _successGreen.withValues(alpha: isDark ? 0.6 : 0.4)
                                            : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isHogCompleted) ...[
                                          const Icon(Icons.check_rounded, size: 10, color: _successGreen),
                                          const SizedBox(width: 3),
                                        ],
                                        Text(
                                          isHogCompleted ? '$hogStage • Complete' : hogStage,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: isHogCompleted
                                                ? _successGreen
                                                : (isDark ? const Color(0xFFE2E8F0) : _brandColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (weight != null && weight.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(
                                  weight,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: mutedColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isHealthy
                                    ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9))
                                    : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFFEBEE)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                isHealthy ? strings.healthy : rawStatus,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: isHealthy ? _successGreen : _dangerRed,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Icon(Icons.chevron_right_rounded, size: 18, color: mutedColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 16),

            // ==================== ASSIGNED RAISER VERIFICATION CARD ====================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
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
                      color: _brandColor.withValues(alpha: isDark ? 0.25 : 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person_pin_circle_rounded,
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
                          'Assigned Raiser: $_effectiveRaiserName',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_effectiveRaiserLocation • $_effectiveRaiserPhone',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: _successGreen.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _successGreen.withValues(alpha: isDark ? 0.5 : 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 11, color: _successGreen),
                        const SizedBox(width: 3.5),
                        Text(
                          'Active',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _successGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline({
    required List<String> stages,
    required String activeStage,
    required bool isSow,
    required bool isDark,
  }) {
    int activeIndex = stages.indexWhere((s) => s.toLowerCase() == activeStage.toLowerCase());
    if (activeIndex == -1) activeIndex = 0;
    final bool isLastStageReached = activeIndex >= 0 && activeIndex == stages.length - 1;

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
                  final isPassed = index < activeIndex || isLastStageReached;
                  return Expanded(
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: isPassed
                            ? _successGreen
                            : (isDark ? const Color(0xFF334A66) : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Stage Nodes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(stages.length, (index) {
                final bool isLastNodeAndCompleted = isLastStageReached && index == stages.length - 1;
                final isPassed = index < activeIndex || isLastNodeAndCompleted;
                final isActive = index == activeIndex && !isLastStageReached;

                Color circleColor;
                Widget iconWidget;
                BoxBorder? nodeBorder;

                if (isPassed) {
                  circleColor = _successGreen;
                  iconWidget = const Icon(Icons.check_rounded, size: 16, color: Colors.white);
                } else if (isActive) {
                  circleColor = isDark ? Colors.white : _brandColor;
                  iconWidget = Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
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

                return GestureDetector(
                  onTap: () => _showStageInfoDialog(context, stages[index], isSow),
                  child: SizedBox(
                    width: stepWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: (isActive || isLastNodeAndCompleted) ? 34 : 30,
                          height: (isActive || isLastNodeAndCompleted) ? 34 : 30,
                          decoration: BoxDecoration(
                            color: circleColor,
                            shape: BoxShape.circle,
                            border: nodeBorder,
                            boxShadow: (isActive || isLastNodeAndCompleted)
                                ? [
                                    BoxShadow(
                                      color: (isLastNodeAndCompleted
                                              ? _successGreen
                                              : (isDark ? Colors.white : _brandColor))
                                          .withValues(alpha: isDark ? 0.35 : 0.3),
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
                            fontWeight: (isActive || isLastNodeAndCompleted)
                                ? FontWeight.w800
                                : (isPassed ? FontWeight.w700 : FontWeight.w600),
                            color: isActive
                                ? (isDark ? Colors.white : _brandColor)
                                : (isPassed
                                    ? _successGreen
                                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFFA0AEC0))),
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
}
