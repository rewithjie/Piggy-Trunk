import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../utils/capitalization_formatters.dart';

class BatchFormDrawer {
  static void show({
    required BuildContext context,
    Map<String, dynamic>? existingBatch,
    List<Map<String, dynamic>>? activeRaisers,
    required VoidCallback onBatchSaved,
    required void Function(String msg, {bool isError}) onShowSnackBar,
  }) {
    final isEdit = existingBatch != null;
    final batchNameCtrl = TextEditingController(text: isEdit ? existingBatch['batch_name']?.toString() ?? '' : '');

    String? batchNameError;
    bool isDrawerSaving = false;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF132238) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
    final titleColor = isDark ? Colors.white : const Color(0xFF18314F);
    final fieldBg = isDark ? const Color(0xFF1A2B44) : const Color(0xFFF5F8FE);
    final fieldBorder = isDark ? const Color(0xFF28405D) : const Color(0xFFC9D8EC);
    final fieldFocus = isDark ? const Color(0xFF88A7CE) : const Color(0xFF315C8F);
    final fieldText = isDark ? Colors.white : const Color(0xFF18314F);
    final hintText = isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Batch Drawer',
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
                                    isEdit ? Icons.edit_note_rounded : Icons.layers_rounded,
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
                                        isEdit ? 'Edit Hog Batch' : 'Create New Hog Batch',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: titleColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isEdit ? 'Update batch name and code' : 'Define batch code identifier',
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
                                  // Batch Name
                                  Text(
                                    'BATCH NAME / CODE *',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: hintText,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: batchNameCtrl,
                                    textCapitalization: TextCapitalization.words,
                                    inputFormatters: const [CapitalizeWordsInputFormatter()],
                                    onChanged: (_) {
                                      if (batchNameError != null) setDrawerState(() => batchNameError = null);
                                    },
                                    style: GoogleFonts.plusJakartaSans(color: fieldText, fontSize: 14, fontWeight: FontWeight.w600),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. BATCH-2026-01',
                                      hintStyle: GoogleFonts.plusJakartaSans(color: hintText, fontSize: 14),
                                      filled: true,
                                      fillColor: fieldBg,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: batchNameError != null ? const Color(0xFFE53E3E) : fieldBorder,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: batchNameError != null ? const Color(0xFFE53E3E) : fieldFocus,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (batchNameError != null) ...[
                                    const SizedBox(height: 4),
                                    Text(batchNameError!, style: const TextStyle(color: Color(0xFFE53E3E), fontSize: 11.5)),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Footer Actions
                          Divider(color: cardBorder.withValues(alpha: 0.5), height: 1),
                          Padding(
                            padding: const EdgeInsets.all(20),
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
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: isDrawerSaving
                                        ? null
                                        : () async {
                                            final name = batchNameCtrl.text.trim();
                                            if (name.isEmpty) {
                                              setDrawerState(() => batchNameError = 'Please enter batch name');
                                              return;
                                            }

                                            setDrawerState(() => isDrawerSaving = true);
                                            try {
                                              final supabase = Supabase.instance.client;
                                              if (isEdit) {
                                                final bId = existingBatch['batch_id'] ?? existingBatch['id'];
                                                await supabase.from('batches').update({'batch_name': name}).eq(
                                                  existingBatch['batch_id'] != null ? 'batch_id' : 'id',
                                                  bId,
                                                );
                                              } else {
                                                try {
                                                  await supabase.from('batches').insert({
                                                    'batch_name': name,
                                                    'date_created': DateTime.now().toIso8601String().split('T').first,
                                                    'status': 'Active',
                                                  });
                                                } catch (_) {
                                                  await supabase.from('batches').insert({'batch_name': name});
                                                }
                                              }

                                              if (!dialogContext.mounted) return;
                                              Navigator.pop(dialogContext);
                                              onShowSnackBar(isEdit ? 'Batch updated successfully.' : 'Batch created successfully.');
                                              onBatchSaved();
                                            } catch (e) {
                                              setDrawerState(() => isDrawerSaving = false);
                                              onShowSnackBar('Operation failed: $e', isError: true);
                                            }
                                          },
                                    icon: isDrawerSaving
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : Icon(isEdit ? Icons.save_rounded : Icons.add_rounded, size: 18),
                                    label: Text(
                                      isDrawerSaving ? 'Saving...' : (isEdit ? 'Save Changes' : 'Create Batch'),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
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
}
