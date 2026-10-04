import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../../utils/app_strings.dart';
import '../../utils/capitalization_formatters.dart';
import '../../widgets/piggy_toast.dart';

class RequestFormScreen extends StatefulWidget {
  final List<Map<String, dynamic>> activeAssignments;
  final Map<String, dynamic> raiserData;
  final String initialCategory;
  final VoidCallback onBack;
  final VoidCallback onSuccess;
  final VoidCallback onViewHistory;

  const RequestFormScreen({
    super.key,
    required this.activeAssignments,
    required this.raiserData,
    this.initialCategory = 'Feeds',
    required this.onBack,
    required this.onSuccess,
    required this.onViewHistory,
  });

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  bool _feedsSelected = false;
  int _feedsQuantity = 0;
  final TextEditingController _feedsDetailController = TextEditingController();

  bool _medicineSelected = false;
  int _medicineQuantity = 0;
  final TextEditingController _medicineDetailController = TextEditingController();

  bool _vitaminsSelected = false;
  int _vitaminsQuantity = 0;
  final TextEditingController _vitaminsDetailController = TextEditingController();

  final TextEditingController _generalNotesController = TextEditingController();
  BigInt? _selectedAssignmentId;
  bool _isSubmitting = false;

  String? _assignmentError;
  String? _quantityError;

  static const Color _brandColor = Color(0xFF18314F);

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory == 'Medicine') {
      _medicineSelected = true;
      _medicineQuantity = 1;
    } else if (widget.initialCategory == 'Vitamins') {
      _vitaminsSelected = true;
      _vitaminsQuantity = 1;
    } else {
      _feedsSelected = true;
      _feedsQuantity = 1;
    }

    if (widget.activeAssignments.isNotEmpty) {
      _selectedAssignmentId = BigInt.from(widget.activeAssignments[0]['assignment_id'] as num);
    }
  }

  @override
  void dispose() {
    _feedsDetailController.dispose();
    _medicineDetailController.dispose();
    _vitaminsDetailController.dispose();
    _generalNotesController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final strings = AppStrings.of(context);
    setState(() {
      _assignmentError = null;
      _quantityError = null;
    });

    if (widget.activeAssignments.isEmpty) {
      PiggyToast.showWarning(
        context,
        strings.batchRequiredMessage,
        title: strings.batchRequiredTitle,
        duration: const Duration(milliseconds: 4000),
      );
      return;
    }

    if (_selectedAssignmentId == null) {
      setState(() {
        _assignmentError = strings.pleaseSelectBatch;
      });
      return;
    }

    final int totalCount = (_feedsSelected ? _feedsQuantity : 0) +
        (_medicineSelected ? _medicineQuantity : 0) +
        (_vitaminsSelected ? _vitaminsQuantity : 0);

    if (totalCount <= 0) {
      setState(() {
        _quantityError = strings.pleaseEnterQuantity;
      });
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final raiserId = widget.raiserData['hog_raiser_id'] ?? widget.raiserData['id'];
      if (raiserId == null) throw Exception('Raiser profile is not available.');

      final now = DateTime.now();
      final nowIso = now.toUtc().toIso8601String();
      final today = now.toIso8601String().split('T').first;
      final generalNotes = _generalNotesController.text.trim();

      final isRealAssignment = _selectedAssignmentId != null &&
          _selectedAssignmentId! < BigInt.from(900000);
      final int? validAssignmentId = isRealAssignment ? _selectedAssignmentId!.toInt() : null;

      final String? cleanGeneralNotes = generalNotes.isNotEmpty ? generalNotes : null;

      final List<Map<String, dynamic>> requestsToInsert = [];
      final List<String> descriptions = [];

      if (_feedsSelected && _feedsQuantity > 0) {
        final feedDetail = _feedsDetailController.text.trim();
        final effectiveFeedType = feedDetail.isNotEmpty ? feedDetail : 'Feeds';

        final Map<String, dynamic> feedsPayload = {
          'hog_raiser_id': raiserId,
          'status': 'pending',
          'request_date': today,
          'category': 'Feeds',
          'quantity': _feedsQuantity,
          'feed_type': effectiveFeedType,
          'notes': cleanGeneralNotes,
          'created_at': nowIso,
        };
        if (validAssignmentId != null) {
          feedsPayload['assignment_id'] = validAssignmentId;
        }

        requestsToInsert.add(feedsPayload);
        descriptions.add('$_feedsQuantity ${_feedsQuantity > 1 ? "sacks" : "sack"} of $effectiveFeedType');
      }

      if (_medicineSelected && _medicineQuantity > 0) {
        final medDetail = _medicineDetailController.text.trim();
        final effectiveMedName = medDetail.isNotEmpty ? medDetail : 'Medicine';

        final Map<String, dynamic> medPayload = {
          'hog_raiser_id': raiserId,
          'status': 'pending',
          'request_date': today,
          'category': 'Medicine',
          'quantity': _medicineQuantity,
          'feed_type': effectiveMedName,
          'notes': cleanGeneralNotes,
          'created_at': nowIso,
        };
        if (validAssignmentId != null) {
          medPayload['assignment_id'] = validAssignmentId;
        }

        requestsToInsert.add(medPayload);
        descriptions.add('$_medicineQuantity ${_medicineQuantity > 1 ? "pcs" : "pc"} of $effectiveMedName (Medicine)');
      }

      if (_vitaminsSelected && _vitaminsQuantity > 0) {
        final vitDetail = _vitaminsDetailController.text.trim();
        final effectiveVitName = vitDetail.isNotEmpty ? vitDetail : 'Vitamins';

        final Map<String, dynamic> vitPayload = {
          'hog_raiser_id': raiserId,
          'status': 'pending',
          'request_date': today,
          'category': 'Vitamins',
          'quantity': _vitaminsQuantity,
          'feed_type': effectiveVitName,
          'notes': cleanGeneralNotes,
          'created_at': nowIso,
        };
        if (validAssignmentId != null) {
          vitPayload['assignment_id'] = validAssignmentId;
        }

        requestsToInsert.add(vitPayload);
        descriptions.add('$_vitaminsQuantity ${_vitaminsQuantity > 1 ? "pcs" : "pc"} of $effectiveVitName (Vitamins)');
      }

      if (requestsToInsert.isEmpty) {
        throw Exception('No valid items to request.');
      }

      try {
        await Supabase.instance.client.from('stock_requests').insert(requestsToInsert);
      } catch (insertErr) {
        final errStr = insertErr.toString().toLowerCase();
        debugPrint('Notice: stock_requests insert failed: $insertErr');

        final bool isFkError = errStr.contains('stock_requests_assignment_id_fkey') ||
            errStr.contains('23503') ||
            errStr.contains('foreign key constraint');

        final fallbackList = requestsToInsert.map((r) {
          final m = Map<String, dynamic>.from(r);
          m.remove('created_at');
          if (isFkError) {
            m.remove('assignment_id');
          }
          return m;
        }).toList();

        try {
          await Supabase.instance.client.from('stock_requests').insert(fallbackList);
        } catch (retryErr) {
          final retryErrStr = retryErr.toString().toLowerCase();
          if (retryErrStr.contains('stock_requests_assignment_id_fkey') ||
              retryErrStr.contains('23503') ||
              retryErrStr.contains('foreign key constraint')) {
            final noAssignList = fallbackList.map((r) {
              final m = Map<String, dynamic>.from(r);
              m.remove('assignment_id');
              return m;
            }).toList();
            await Supabase.instance.client.from('stock_requests').insert(noAssignList);
          } else {
            rethrow;
          }
        }
      }

      final raiserName = widget.raiserData['name'] ?? 'Hog Raiser';
      final itemsSummary = descriptions.join(' and ');
      final notifMessage = generalNotes.isNotEmpty
          ? '$raiserName requested $itemsSummary.\nNotes: "$generalNotes"'
          : '$raiserName requested $itemsSummary.';

      try {
        await Supabase.instance.client.from('admin_notifications').insert({
          'title': 'New Stock Request',
          'message': notifMessage,
          'type': 'stock_request',
          'is_read': false,
        });
      } catch (_) {}

      if (mounted) {
        PiggyToast.showSuccess(
          context,
          strings.requestSuccessToast,
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        PiggyToast.showError(
          context,
          '${strings.requestFailedToast}: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildCategoryCard({
    required String name,
    required String label,
    required String sublabel,
    required String imagePath,
    required Color accentColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
    final cardBorder = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
    final selectedBorderColor = accentColor;
    final textColor = isDark ? Colors.white : (isSelected ? _brandColor : const Color(0xFF1E293B));
    final mutedColor = isDark ? const Color(0xFF94A3B8) : PiggyTrunkTheme.ptMuted;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? selectedBorderColor : cardBorder,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? accentColor.withValues(alpha: isDark ? 0.25 : 0.15)
                    : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: isSelected ? 10 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (isSelected)
                Positioned(
                  top: -6,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        imagePath,
                        width: 22,
                        height: 22,
                        color: accentColor,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          name == 'Feeds'
                              ? Icons.grass_rounded
                              : (name == 'Vitamins'
                                  ? Icons.medication_liquid_rounded
                                  : Icons.medical_services_rounded),
                          size: 22,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sublabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemConfigCard({
    required String title,
    required String unitLabel,
    required String imagePath,
    required IconData fallbackIcon,
    required Color accentColor,
    required int quantity,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required VoidCallback onRemove,
    Widget? extraContent,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceBg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
    final borderColor = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
    final textColor = isDark ? Colors.white : _brandColor;
    final mutedColor = isDark ? const Color(0xFF94A3B8) : PiggyTrunkTheme.ptMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.45 : 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.1 : 0.05),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.25 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  imagePath,
                  width: 22,
                  height: 22,
                  color: accentColor,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    fallbackIcon,
                    size: 22,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    Text(
                      unitLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Quantity stepper
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: Icon(Icons.remove, size: 16, color: textColor),
                      onPressed: onDecrement,
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 32),
                      alignment: Alignment.center,
                      child: Text(
                        quantity.toString(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: Icon(Icons.add, size: 16, color: textColor),
                      onPressed: onIncrement,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: Icon(Icons.close_rounded, size: 18, color: mutedColor),
                tooltip: 'Remove',
                onPressed: onRemove,
              ),
            ],
          ),
          if (extraContent != null) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: borderColor.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            extraContent,
          ],
        ],
      ),
    );
  }

  Widget _buildItemDetailField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color accentColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : PiggyTrunkTheme.ptMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: mutedColor,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(icon, size: 18, color: accentColor),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      controller.clear();
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: surfaceBg,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? PiggyTrunkTheme.ptBgDark : PiggyTrunkTheme.ptBg;
    final surfaceBg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
    final borderColor = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
    final textColor = isDark ? Colors.white : _brandColor;
    final mutedColor = isDark ? const Color(0xFF94A3B8) : PiggyTrunkTheme.ptMuted;

    final List<String> activeSummaryParts = [];
    int totalItemCount = 0;
    if (_feedsSelected && _feedsQuantity > 0) {
      final feedDetail = _feedsDetailController.text.trim();
      final feedName = feedDetail.isNotEmpty ? feedDetail : 'Feeds';
      activeSummaryParts.add('$_feedsQuantity ${strings.isFilipino ? "sako ng" : "sacks"} $feedName');
      totalItemCount += _feedsQuantity;
    }
    if (_medicineSelected && _medicineQuantity > 0) {
      final medName = _medicineDetailController.text.trim();
      final displayMed = medName.isNotEmpty ? medName : 'Medicine';
      activeSummaryParts.add('$_medicineQuantity ${strings.isFilipino ? "pirasong" : "pcs"} $displayMed');
      totalItemCount += _medicineQuantity;
    }
    if (_vitaminsSelected && _vitaminsQuantity > 0) {
      final vitName = _vitaminsDetailController.text.trim();
      final displayVit = vitName.isNotEmpty ? vitName : 'Vitamins';
      activeSummaryParts.add('$_vitaminsQuantity ${strings.isFilipino ? "pirasong" : "pcs"} $displayVit');
      totalItemCount += _vitaminsQuantity;
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: surfaceBg,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: widget.onBack,
        ),
        title: Text(
          strings.requestSuppliesTitle,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: textColor,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: textColor),
            onPressed: widget.onViewHistory,
          ),
        ],
      ),
      body: _isSubmitting
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white : _brandColor),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active Batch Selection dropdown or Batch Required Banner
                    Text(
                      strings.selectBatchHogs,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    widget.activeAssignments.isEmpty
                        ? GestureDetector(
                            onTap: () {
                              PiggyToast.showWarning(
                                context,
                                strings.batchRequiredMessage,
                                title: strings.batchRequiredTitle,
                                duration: const Duration(milliseconds: 4000),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: surfaceBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      strings.noActiveBatchAssigned,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        color: mutedColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : DropdownButtonFormField<BigInt>(
                            initialValue: _selectedAssignmentId,
                            dropdownColor: surfaceBg,
                            isExpanded: true,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              fillColor: surfaceBg,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: isDark ? Colors.white54 : _brandColor, width: 1.5),
                              ),
                            ),
                            items: widget.activeAssignments.map((a) {
                              final rawBatchName = a['batches']?['batch_name'] ?? 'Assignment #${a['assignment_id']}';
                              String displayBatchName = rawBatchName;
                              if (rawBatchName.contains(' (')) {
                                final parts = rawBatchName.split(' (');
                                if (parts.last.endsWith(')')) {
                                  displayBatchName = parts.sublist(0, parts.length - 1).join(' (');
                                }
                              }
                              final rawHogType = a['hog_types']?['type_name']?.toString() ??
                                  a['pig_type']?.toString() ??
                                  widget.raiserData['pig_type']?.toString() ??
                                  'Unassigned';
                              final hogType = (rawHogType.isEmpty || rawHogType == 'N/A' || rawHogType.toLowerCase() == 'unassigned')
                                  ? strings.unassigned
                                  : rawHogType;
                              return DropdownMenuItem<BigInt>(
                                value: BigInt.from(a['assignment_id'] as num),
                                child: Text(
                                  '$displayBatchName ($hogType)',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedAssignmentId = val;
                                _assignmentError = null;
                              });
                            },
                          ),
                    if (_assignmentError != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFE53935)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _assignmentError!,
                              style: const TextStyle(
                                color: Color(0xFFE53935),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Select Category Group (Multi-select)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          strings.selectCategory,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : _brandColor).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            strings.isFilipino ? 'Sabay-sabay / Multi' : 'Multi-select',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : _brandColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.selectCategoriesHint,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildCategoryCard(
                          name: 'Feeds',
                          label: strings.feedsLabel,
                          sublabel: strings.feedsSublabel,
                          imagePath: 'assets/feeds_icon.png',
                          accentColor: const Color(0xFF10B981),
                          isSelected: _feedsSelected,
                          onTap: () {
                            setState(() {
                              _feedsSelected = !_feedsSelected;
                              if (_feedsSelected && _feedsQuantity <= 0) {
                                _feedsQuantity = 1;
                              }
                              _quantityError = null;
                            });
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildCategoryCard(
                          name: 'Medicine',
                          label: strings.medicineLabel,
                          sublabel: strings.medicineSublabel,
                          imagePath: 'assets/medicine_icon.png',
                          accentColor: const Color(0xFFEF4444),
                          isSelected: _medicineSelected,
                          onTap: () {
                            setState(() {
                              _medicineSelected = !_medicineSelected;
                              if (_medicineSelected && _medicineQuantity <= 0) {
                                _medicineQuantity = 1;
                              }
                              _quantityError = null;
                            });
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildCategoryCard(
                          name: 'Vitamins',
                          label: strings.vitaminsLabel,
                          sublabel: strings.vitaminsSublabel,
                          imagePath: 'assets/vitamins_icon.png',
                          accentColor: const Color(0xFF8B5CF6),
                          isSelected: _vitaminsSelected,
                          onTap: () {
                            setState(() {
                              _vitaminsSelected = !_vitaminsSelected;
                              if (_vitaminsSelected && _vitaminsQuantity <= 0) {
                                _vitaminsQuantity = 1;
                              }
                              _quantityError = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Items Configuration Section
                    Text(
                      strings.quantityBagsPcs,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _quantityError != null ? const Color(0xFFE53935) : textColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (!_feedsSelected && !_medicineSelected && !_vitaminsSelected) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: surfaceBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _quantityError != null ? const Color(0xFFE53935) : borderColor,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app_outlined,
                              size: 32,
                              color: _quantityError != null ? const Color(0xFFE53935) : mutedColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              strings.noCategorySelectedPrompt,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _quantityError != null ? const Color(0xFFE53935) : mutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_feedsSelected) ...[
                      _buildItemConfigCard(
                        title: strings.feedsLabel,
                        unitLabel: strings.isFilipino ? 'Sako / Bags' : 'Bags / Sacks',
                        imagePath: 'assets/feeds_icon.png',
                        fallbackIcon: Icons.grass_rounded,
                        accentColor: const Color(0xFF10B981),
                        quantity: _feedsQuantity,
                        onIncrement: () {
                          setState(() {
                            _feedsQuantity++;
                            _quantityError = null;
                          });
                        },
                        onDecrement: () {
                          setState(() {
                            if (_feedsQuantity > 1) {
                              _feedsQuantity--;
                            } else {
                              _feedsQuantity = 0;
                              _feedsSelected = false;
                            }
                            _quantityError = null;
                          });
                        },
                        onRemove: () {
                          setState(() {
                            _feedsQuantity = 0;
                            _feedsSelected = false;
                            _quantityError = null;
                          });
                        },
                        extraContent: _buildItemDetailField(
                          controller: _feedsDetailController,
                          label: strings.specificFeedsLabel,
                          hint: strings.specificFeedsHint,
                          icon: Icons.grass_rounded,
                          accentColor: const Color(0xFF10B981),
                        ),
                      ),
                    ],

                    if (_medicineSelected) ...[
                      _buildItemConfigCard(
                        title: strings.medicineLabel,
                        unitLabel: strings.isFilipino ? 'Piraso / Bote' : 'Pieces / Bottles',
                        imagePath: 'assets/medicine_icon.png',
                        fallbackIcon: Icons.medical_services_rounded,
                        accentColor: const Color(0xFFEF4444),
                        quantity: _medicineQuantity,
                        onIncrement: () {
                          setState(() {
                            _medicineQuantity++;
                            _quantityError = null;
                          });
                        },
                        onDecrement: () {
                          setState(() {
                            if (_medicineQuantity > 1) {
                              _medicineQuantity--;
                            } else {
                              _medicineQuantity = 0;
                              _medicineSelected = false;
                            }
                            _quantityError = null;
                          });
                        },
                        onRemove: () {
                          setState(() {
                            _medicineQuantity = 0;
                            _medicineSelected = false;
                            _quantityError = null;
                          });
                        },
                        extraContent: _buildItemDetailField(
                          controller: _medicineDetailController,
                          label: strings.specificMedicineLabel,
                          hint: strings.specificMedicineHint,
                          icon: Icons.medication_outlined,
                          accentColor: const Color(0xFFEF4444),
                        ),
                      ),
                    ],

                    if (_vitaminsSelected) ...[
                      _buildItemConfigCard(
                        title: strings.vitaminsLabel,
                        unitLabel: strings.isFilipino ? 'Piraso / Bote' : 'Pieces / Bottles',
                        imagePath: 'assets/vitamins_icon.png',
                        fallbackIcon: Icons.medication_liquid_rounded,
                        accentColor: const Color(0xFF8B5CF6),
                        quantity: _vitaminsQuantity,
                        onIncrement: () {
                          setState(() {
                            _vitaminsQuantity++;
                            _quantityError = null;
                          });
                        },
                        onDecrement: () {
                          setState(() {
                            if (_vitaminsQuantity > 1) {
                              _vitaminsQuantity--;
                            } else {
                              _vitaminsQuantity = 0;
                              _vitaminsSelected = false;
                            }
                            _quantityError = null;
                          });
                        },
                        onRemove: () {
                          setState(() {
                            _vitaminsQuantity = 0;
                            _vitaminsSelected = false;
                            _quantityError = null;
                          });
                        },
                        extraContent: _buildItemDetailField(
                          controller: _vitaminsDetailController,
                          label: strings.specificVitaminsLabel,
                          hint: strings.specificVitaminsHint,
                          icon: Icons.vaccines_outlined,
                          accentColor: const Color(0xFF8B5CF6),
                        ),
                      ),
                    ],

                    if (_quantityError != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFE53935)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _quantityError!,
                                style: const TextStyle(
                                  color: Color(0xFFE53935),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Summary Banner (if active items > 0)
                    if (activeSummaryParts.isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.inventory_2_rounded, size: 20, color: isDark ? Colors.white : _brandColor),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    strings.requestSummaryTitle,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    activeSummaryParts.join(' • '),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : _brandColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : _brandColor).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$totalItemCount ${strings.isFilipino ? "kabuuan" : "total"}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : _brandColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Notes/Explanation field (General message from raiser)
                    Text(
                      strings.notesTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.generalNotesSubtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _generalNotesController,
                      maxLines: 3,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.sentences,
                      inputFormatters: const [
                        CapitalizeSentencesInputFormatter(),
                      ],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: strings.notesHint,
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: mutedColor,
                        ),
                        fillColor: surfaceBg,
                        filled: true,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: isDark ? Colors.white54 : _brandColor, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Confirm Request Action Button (Always responsive to gestures!)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _submitRequest,
                        icon: Icon(
                          widget.activeAssignments.isEmpty ? Icons.lock_outline_rounded : Icons.check_circle_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: Text(
                          strings.confirmRequestButton,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.activeAssignments.isEmpty
                              ? (isDark ? const Color(0xFF475569) : const Color(0xFF64748B))
                              : PiggyTrunkTheme.ptSuccess,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
