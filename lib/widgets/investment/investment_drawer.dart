import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/investment_model.dart';
import '../../theme/app_theme.dart';

class InvestmentDrawer {
  static void show({
    required BuildContext context,
    Investment? existingInvestment,
    required VoidCallback onSaved,
    required void Function(String msg, {bool isError}) onShowSnackBar,
  }) async {
    final supabase = Supabase.instance.client;
    final isEdit = existingInvestment != null;

    final capitalCtrl = TextEditingController(text: isEdit ? existingInvestment.initialCapital.toInt().toString() : '');
    final totalHogCtrl = TextEditingController(text: isEdit ? existingInvestment.totalHog.toString() : '');

    String? selectedRaiserId = isEdit
        ? (existingInvestment.hogRaiserId.isEmpty ? 'unassigned' : existingInvestment.hogRaiserId)
        : 'unassigned';

    List<String> selectedHogTypes = ['Fattening'];
    if (isEdit && existingInvestment.hogType.isNotEmpty) {
      final types = existingInvestment.hogType.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (types.isNotEmpty) selectedHogTypes = types;
    }

    String? selectedBatchId = 'unassigned';
    List<Map<String, dynamic>> activeBatches = [];
    List<Map<String, dynamic>> activeRaisers = [];
    List<Map<String, dynamic>> parsedBatches = [];

    // Fetch batches and raisers
    try {
      final raisersRes = await supabase
          .from('hog_raisers')
          .select('hog_raiser_id, name, pig_type, status, account_status, app_users!hog_raisers_user_id_fkey(name, email)')
          .order('name', ascending: true);

      final List<Map<String, dynamic>> parsedRaisers = [];
      for (var r in (raisersRes as List)) {
        final rMap = Map<String, dynamic>.from(r as Map);
        final accStatus = (rMap['account_status'] ?? '').toString().toLowerCase();
        if (accStatus == 'rejected' || accStatus == 'pending') continue;

        final appUsers = rMap['app_users'] as Map<String, dynamic>?;
        final googleOrAppName = (appUsers?['name'] ?? '').toString().trim();
        final raiserName = (rMap['name'] ?? '').toString().trim();
        final resolvedFullName = googleOrAppName.isNotEmpty && googleOrAppName.toLowerCase() != 'hog raiser'
            ? googleOrAppName
            : (raiserName.isNotEmpty ? raiserName : 'Hog Raiser');

        final idStr = (rMap['id'] ?? rMap['hog_raiser_id'] ?? '').toString();
        if (idStr.isEmpty) continue;

        parsedRaisers.add({
          'id': idStr,
          'name': resolvedFullName,
          'pig_type': rMap['pig_type'] ?? 'Fattening',
          'real_pk_col': rMap['id'] != null ? 'id' : 'hog_raiser_id',
        });
      }

      activeRaisers = [
        {'id': 'unassigned', 'name': 'Unassigned (General Pool)'},
        ...parsedRaisers,
      ];

      final batchesRes = await supabase
          .from('batches')
          .select('batch_id, batch_name, date_created, assignments(assignment_id, hog_raiser_id, status, hog_raisers(name, pig_type, hog_raiser_id, app_users!hog_raisers_user_id_fkey(name)), hogs(hog_id))')
          .order('date_created', ascending: false);

      for (var b in (batchesRes as List)) {
        final bMap = Map<String, dynamic>.from(b as Map);
        final bId = bMap['batch_id']?.toString() ?? '';
        final bName = bMap['batch_name']?.toString() ?? 'Batch $bId';

        final assigns = bMap['assignments'] as List<dynamic>? ?? [];
        final activeAssign = assigns.firstWhere(
          (a) => (a['status'] ?? '').toString().toLowerCase() == 'active',
          orElse: () => assigns.isNotEmpty ? assigns.first : null,
        );

        String raiserId = '';
        String raiserName = 'Unassigned';
        String pigType = 'Fattening';
        int hogCount = 0;

        if (activeAssign != null) {
          final raiser = activeAssign['hog_raisers'] as Map<String, dynamic>?;
          raiserId = (activeAssign['hog_raiser_id'] ?? raiser?['hog_raiser_id'] ?? '').toString();
          if (raiser != null) {
            final appUsers = raiser['app_users'] as Map<String, dynamic>?;
            final appName = appUsers?['name']?.toString().trim();
            final rName = raiser['name']?.toString().trim();
            raiserName = (appName != null && appName.isNotEmpty && appName.toLowerCase() != 'hog raiser')
                ? appName
                : (rName != null && rName.isNotEmpty ? rName : 'Hog Raiser');
            pigType = raiser['pig_type']?.toString() ?? 'Fattening';
          }
          final hogs = activeAssign['hogs'] as List<dynamic>? ?? [];
          hogCount = hogs.length;
        }

        parsedBatches.add({
          'batch_id': bId,
          'batch_name': bName,
          'display_label': activeAssign != null
              ? '$bName • $raiserName ($hogCount heads)'
              : '$bName • Pool ($hogCount heads)',
          'raiser_id': raiserId,
          'raiser_name': raiserName,
          'pig_type': pigType,
          'hog_count': hogCount,
        });
      }

      activeBatches = [
        {
          'batch_id': 'unassigned',
          'batch_name': 'No Specific Batch (General Pool)',
          'display_label': 'General Investment Pool (No Batch Assigned)',
          'raiser_id': '',
          'raiser_name': 'Unassigned',
          'pig_type': 'Fattening',
          'hog_count': 0,
        },
        ...parsedBatches,
      ];

      if (!isEdit) {
        selectedBatchId = activeBatches.length > 1 ? activeBatches[1]['batch_id'] : 'unassigned';
        if (selectedBatchId != null && selectedBatchId != 'unassigned') {
          final matched = activeBatches.firstWhere((b) => b['batch_id'] == selectedBatchId, orElse: () => {});
          selectedRaiserId = (matched['raiser_id'] ?? '').toString();
          final count = matched['hog_count'];
          if (count != null && count > 0) totalHogCtrl.text = count.toString();
          final pt = (matched['pig_type'] ?? 'Fattening').toString();
          if (pt.isNotEmpty) selectedHogTypes = [pt];
        }
      }
    } catch (_) {}

    if (!context.mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF132238) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
    final titleColor = isDark ? Colors.white : const Color(0xFF18314F);
    final fieldBg = isDark ? const Color(0xFF1A2B44) : const Color(0xFFF5F8FE);
    final fieldBorder = isDark ? const Color(0xFF28405D) : const Color(0xFFC9D8EC);
    final fieldFocus = isDark ? const Color(0xFF88A7CE) : const Color(0xFF315C8F);
    final fieldText = isDark ? Colors.white : const Color(0xFF18314F);
    final hintText = isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);

    String? capitalError;
    String? totalHogError;
    bool isDrawerSaving = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Investment Drawer',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (dialogContext, anim1, anim2, child) {
        final curvedAnimation = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        final isMobile = screenWidth < 600;
        final drawerWidth = isMobile ? screenWidth : 460.0;

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: drawerWidth,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border(left: BorderSide(color: cardBorder, width: 1.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
                      blurRadius: 32,
                      offset: const Offset(-6, 0),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: StatefulBuilder(
                    builder: (context, setDrawerState) {
                      return Column(
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF2563EB).withValues(alpha: 0.25) : PiggyTrunkTheme.ptPrimary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isEdit ? Icons.edit_note_rounded : Icons.account_balance_wallet_rounded,
                                    color: isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isEdit ? 'Edit Investment' : 'Add New Investment',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: titleColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isEdit ? 'Update investment details and capital' : 'Assign capital to an active farm batch',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: hintText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  icon: Icon(Icons.close_rounded, color: hintText, size: 22),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Close panel',
                                ),
                              ],
                            ),
                          ),
                          Divider(color: cardBorder.withValues(alpha: 0.5), height: 1),

                          // Body
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Batch Selector
                                  Text(
                                    'SELECT BATCH TO FUND *',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: hintText,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: selectedBatchId,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: fieldBg,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: fieldBorder),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: fieldFocus, width: 1.5),
                                      ),
                                    ),
                                    dropdownColor: fieldBg,
                                    style: GoogleFonts.plusJakartaSans(color: fieldText, fontSize: 13.5, fontWeight: FontWeight.w600),
                                    items: activeBatches.map((b) {
                                      final isUnassigned = b['batch_id'] == 'unassigned';
                                      return DropdownMenuItem<String>(
                                        value: b['batch_id'].toString(),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isUnassigned ? Icons.layers_clear_outlined : Icons.layers_outlined,
                                              size: 16,
                                              color: isUnassigned ? hintText : (isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                b['display_label'].toString(),
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: isUnassigned ? hintText : fieldText,
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val == null) return;
                                      setDrawerState(() {
                                        selectedBatchId = val;
                                        if (val != 'unassigned') {
                                          final matched = activeBatches.firstWhere((b) => b['batch_id'] == val, orElse: () => {});
                                          selectedRaiserId = (matched['raiser_id'] ?? '').toString();
                                          final count = matched['hog_count'];
                                          if (count != null && count > 0) totalHogCtrl.text = count.toString();
                                          final pt = (matched['pig_type'] ?? 'Fattening').toString();
                                          if (pt.isNotEmpty) selectedHogTypes = [pt];
                                        }
                                      });
                                    },
                                  ),
                                  if (parsedBatches.isEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'No farm batches found. Investment will be allocated to the General Pool.',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        color: hintText,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 18),

                                  // Capital
                                  Text(
                                    'INITIAL CAPITAL (PHP) *',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: hintText,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: capitalCtrl,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    onChanged: (_) {
                                      if (capitalError != null) setDrawerState(() => capitalError = null);
                                    },
                                    style: GoogleFonts.plusJakartaSans(color: fieldText, fontSize: 14, fontWeight: FontWeight.w600),
                                    decoration: InputDecoration(
                                      hintText: '0.00',
                                      hintStyle: GoogleFonts.plusJakartaSans(color: hintText, fontSize: 14),
                                      prefixText: '₱ ',
                                      prefixStyle: GoogleFonts.plusJakartaSans(color: hintText, fontSize: 14, fontWeight: FontWeight.bold),
                                      filled: true,
                                      fillColor: fieldBg,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: capitalError != null ? const Color(0xFFE53E3E) : fieldBorder,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: capitalError != null ? const Color(0xFFE53E3E) : fieldFocus,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (capitalError != null) ...[
                                    const SizedBox(height: 4),
                                    Text(capitalError!, style: const TextStyle(color: Color(0xFFE53E3E), fontSize: 11.5)),
                                  ],
                                  const SizedBox(height: 18),

                                  // Total Heads
                                  Text(
                                    'TOTAL HEADS *',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: hintText,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: totalHogCtrl,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    onChanged: (_) {
                                      if (totalHogError != null) setDrawerState(() => totalHogError = null);
                                    },
                                    style: GoogleFonts.plusJakartaSans(color: fieldText, fontSize: 14, fontWeight: FontWeight.w600),
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      hintStyle: GoogleFonts.plusJakartaSans(color: hintText, fontSize: 14),
                                      filled: true,
                                      fillColor: fieldBg,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: totalHogError != null ? const Color(0xFFE53E3E) : fieldBorder,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: totalHogError != null ? const Color(0xFFE53E3E) : fieldFocus,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (totalHogError != null) ...[
                                    const SizedBox(height: 4),
                                    Text(totalHogError!, style: const TextStyle(color: Color(0xFFE53E3E), fontSize: 11.5)),
                                  ],
                                  const SizedBox(height: 18),

                                  // Hog Types (Stacked vertically for clean UI)
                                  Text(
                                    'HOG TYPE *',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: hintText,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildCheckbox(
                                        title: 'Fattening',
                                        isSelected: selectedHogTypes.contains('Fattening'),
                                        isDark: isDark,
                                        onChanged: (val) {
                                          setDrawerState(() {
                                            if (val == true) {
                                              if (!selectedHogTypes.contains('Fattening')) selectedHogTypes.add('Fattening');
                                            } else {
                                              if (selectedHogTypes.length > 1) selectedHogTypes.remove('Fattening');
                                            }
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      _buildCheckbox(
                                        title: 'Sow / Breeding',
                                        isSelected: selectedHogTypes.contains('Sow / Breeding'),
                                        isDark: isDark,
                                        onChanged: (val) {
                                          setDrawerState(() {
                                            if (val == true) {
                                              if (!selectedHogTypes.contains('Sow / Breeding')) selectedHogTypes.add('Sow / Breeding');
                                            } else {
                                              if (selectedHogTypes.length > 1) selectedHogTypes.remove('Sow / Breeding');
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Footer Actions
                          Divider(color: cardBorder.withValues(alpha: 0.5), height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: isDrawerSaving ? null : () => Navigator.pop(dialogContext),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      side: BorderSide(color: fieldBorder),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: fieldText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    onPressed: isDrawerSaving
                                        ? null
                                        : () async {
                                            final parsedCapital = int.tryParse(capitalCtrl.text.trim());
                                            final parsedTotalHog = int.tryParse(totalHogCtrl.text.trim());

                                            if (parsedCapital == null || parsedCapital <= 0) {
                                              setDrawerState(() => capitalError = 'Please enter a valid capital greater than ₱0.');
                                              return;
                                            }
                                            if (parsedTotalHog == null || parsedTotalHog <= 0) {
                                              setDrawerState(() => totalHogError = 'Please enter total number of heads (min 1).');
                                              return;
                                            }

                                            setDrawerState(() => isDrawerSaving = true);
                                            try {
                                              final isUnassigned = selectedRaiserId == 'unassigned' || selectedRaiserId!.isEmpty;
                                              final raiserName = isUnassigned
                                                  ? 'Unassigned'
                                                  : (activeRaisers.firstWhere(
                                                      (r) => r['id'].toString() == selectedRaiserId,
                                                      orElse: () => {'name': ''},
                                                    )['name'] ?? 'Unassigned');

                                              final hogTypeStr = selectedHogTypes.join(', ');
                                              final payload = {
                                                'hog_raiser_id': isUnassigned ? '' : selectedRaiserId,
                                                'raiser_name': raiserName,
                                                'initial_capital': parsedCapital,
                                                'hog_type': hogTypeStr,
                                                'total_hog': parsedTotalHog,
                                                'investment_date': isEdit ? existingInvestment.investmentDate.toIso8601String() : DateTime.now().toIso8601String(),
                                                if (!isEdit) 'stage': 'active',
                                              };

                                              if (isEdit) {
                                                await supabase.from('investment_records').update(payload).eq('id', existingInvestment.id);
                                              } else {
                                                await supabase.from('investment_records').insert(payload);
                                              }

                                              if (!isUnassigned && int.tryParse(selectedRaiserId!) != null) {
                                                final parsedRaiserId = int.parse(selectedRaiserId!);
                                                final raiserRow = activeRaisers.firstWhere(
                                                  (r) => r['id'].toString() == selectedRaiserId,
                                                  orElse: () => {},
                                                );
                                                final pkCol = raiserRow['real_pk_col'] ?? (raiserRow['id'] != null ? 'id' : 'hog_raiser_id');
                                                await supabase
                                                    .from('hog_raisers')
                                                    .update({
                                                      'lifecycle_stage': 'Booster',
                                                      'pig_type': hogTypeStr,
                                                    })
                                                    .eq(pkCol, parsedRaiserId);
                                              }

                                              if (!dialogContext.mounted) return;
                                              Navigator.pop(dialogContext);
                                              onSaved();
                                              onShowSnackBar(isEdit ? 'Investment updated successfully.' : 'Investment created successfully.');
                                            } catch (e) {
                                              setDrawerState(() => isDrawerSaving = false);
                                              onShowSnackBar('Operation failed: $e', isError: true);
                                            }
                                          },
                                    icon: isDrawerSaving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : Icon(isEdit ? Icons.save_rounded : Icons.add_rounded, size: 18),
                                    label: Text(
                                      isDrawerSaving ? 'Saving...' : (isEdit ? 'Save Changes' : 'Save Investment'),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                                      foregroundColor: isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildCheckbox({
    required String title,
    required bool isSelected,
    required bool isDark,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!isSelected),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: onChanged,
              activeColor: isDark ? const Color(0xFF2563EB) : PiggyTrunkTheme.ptPrimary,
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF18314F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
