import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../utils/capitalization_formatters.dart';

class BatchFormView extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onBatchSaved;
  final Map<String, dynamic>? existingBatch;
  final List<Map<String, dynamic>> activeRaisers;
  final void Function(String msg, {bool isError}) onShowSnackBar;

  const BatchFormView({
    super.key,
    required this.onCancel,
    required this.onBatchSaved,
    this.existingBatch,
    required this.activeRaisers,
    required this.onShowSnackBar,
  });

  @override
  State<BatchFormView> createState() => _BatchFormViewState();
}

class _BatchFormViewState extends State<BatchFormView> {
  final SupabaseClient _supabase = Supabase.instance.client;

  late final TextEditingController _batchNameCtrl;
  String? _selectedRaiserId;
  String? _batchNameError;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _activeRaisers = [];

  bool get _isEdit => widget.existingBatch != null;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _panelStart => _isDark ? const Color(0xFF1A2940) : Colors.white;
  Color get _panelEnd => _isDark ? const Color(0xFF0F1C2F) : Colors.white;
  Color get _panelBorder => _isDark ? const Color(0xFF2A3E5B) : const Color(0xFFC9D8EC);
  Color get _cardBg => _isDark ? const Color(0xFF132238) : Colors.white;
  Color get _cardBorder => _isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
  Color get _titleColor => _isDark ? Colors.white : const Color(0xFF18314F);
  Color get _mutedColor => _isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);
  Color get _fieldBg => _isDark ? const Color(0xFF1A2B44) : const Color(0xFFF5F8FE);
  Color get _fieldText => _isDark ? Colors.white : const Color(0xFF18314F);
  Color get _fieldBorder => _isDark ? const Color(0xFF28405D) : const Color(0xFFC9D8EC);
  Color get _fieldFocus => _isDark ? const Color(0xFF88A7CE) : const Color(0xFF315C8F);

  @override
  void initState() {
    super.initState();
    _activeRaisers = List.from(widget.activeRaisers);
    _batchNameCtrl = TextEditingController(
      text: _isEdit ? widget.existingBatch!['batch_name']?.toString() ?? '' : '',
    );
    _selectedRaiserId = _isEdit
        ? (widget.existingBatch!['raiser_id'] != null
            ? widget.existingBatch!['raiser_id'].toString()
            : 'unassigned')
        : 'unassigned';

    _loadActiveRaisers();
  }

  Future<void> _loadActiveRaisers() async {
    try {
      List<dynamic> res = [];
      try {
        res = await _supabase
            .from('hog_raisers')
            .select('hog_raiser_id, name, phone, status, account_status, user_id, app_users!hog_raisers_user_id_fkey(name, email)');
      } catch (_) {
        res = await _supabase.from('hog_raisers').select('hog_raiser_id, name, phone');
      }

      // Fetch active assignments to check which raisers are already assigned to active batches
      List<dynamic> activeAssignments = [];
      try {
        activeAssignments = await _supabase
            .from('assignments')
            .select('*');
      } catch (aErr) {
        debugPrint('Notice loading assignments for raisers check: $aErr');
      }

      List<dynamic> batchesRaw = [];
      try {
        batchesRaw = await _supabase.from('batches').select('batch_id, batch_name');
      } catch (_) {}

      final Map<String, String> batchNamesMap = {
        for (var b in batchesRaw)
          (b['batch_id'] ?? b['id'] ?? '').toString(): (b['batch_name'] ?? 'Batch #${b['batch_id']}').toString()
      };

      final currentBatchId = _isEdit && widget.existingBatch != null
          ? widget.existingBatch!['batch_id']?.toString()
          : null;
      final Map<String, String> assignedToBatchMap = {};
      for (var a in activeAssignments) {
        if (a is! Map) continue;
        final st = (a['status'] ?? 'active').toString().toLowerCase();
        if (st == 'completed' || st == 'archived') continue;

        final rId = (a['hog_raiser_id'] ?? '').toString();
        final bId = (a['batch_id'] ?? '').toString();
        final bName = batchNamesMap[bId] ?? 'Batch #$bId';

        if (bId != currentBatchId && rId.isNotEmpty) {
          assignedToBatchMap[rId] = bName;
        }
      }

      final list = <Map<String, dynamic>>[];
      for (var r in res) {
        if (r is! Map) continue;
        final rMap = Map<String, dynamic>.from(r);
        final pk = (rMap['hog_raiser_id'] ?? rMap['id'])?.toString();
        if (pk != null && pk.isNotEmpty) {
          dynamic appUsersRaw = rMap['app_users'];
          Map<String, dynamic>? appUsers;
          if (appUsersRaw is Map) {
            appUsers = Map<String, dynamic>.from(appUsersRaw);
          } else if (appUsersRaw is List && appUsersRaw.isNotEmpty && appUsersRaw.first is Map) {
            appUsers = Map<String, dynamic>.from(appUsersRaw.first);
          }

          final gName = (appUsers?['name'] ?? '').toString().trim();
          final rName = (rMap['name'] ?? '').toString().trim();
          final resolvedName = (gName.isNotEmpty && gName.toLowerCase() != 'hog raiser')
              ? gName
              : (rName.isNotEmpty ? rName : 'Hog Raiser');

          final isAssignedElsewhere = assignedToBatchMap.containsKey(pk);
          final assignedBatchName = assignedToBatchMap[pk];

          list.add({
            'id': pk,
            'name': resolvedName,
            'phone': rMap['phone'] ?? 'N/A',
            'is_assigned_elsewhere': isAssignedElsewhere,
            'assigned_batch_name': assignedBatchName,
          });
        }
      }
      if (mounted) setState(() => _activeRaisers = list);
    } catch (err) {
      debugPrint('Error in _loadActiveRaisers: $err');
    }
  }

  @override
  void dispose() {
    _batchNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    final batchName = _batchNameCtrl.text.trim();

    if (batchName.isEmpty) {
      setState(() => _batchNameError = 'Please enter a batch name or code.');
      return;
    }

    final isUnassigned = _selectedRaiserId == 'unassigned' || _selectedRaiserId == null;
    if (!isUnassigned) {
      final matched = _activeRaisers.firstWhere(
        (r) => r['id'].toString() == _selectedRaiserId,
        orElse: () => {},
      );
      if (matched['is_assigned_elsewhere'] == true) {
        final bName = matched['assigned_batch_name'] ?? 'another Batch';
        setState(() => _isSubmitting = false);
        widget.onShowSnackBar(
          '${matched['name']} is already assigned to $bName. A Hog Raiser can only be assigned to one active batch at a time.',
          isError: true,
        );
        return;
      }
    }

    setState(() {
      _batchNameError = null;
      _isSubmitting = true;
    });

    try {
      dynamic batchId;

      if (_isEdit) {
        batchId = widget.existingBatch!['batch_id'];
        await _supabase.from('batches').update({
          'batch_name': batchName,
        }).eq('batch_id', batchId);
      } else {
        try {
          final batchRes = await _supabase.from('batches').insert({
            'batch_name': batchName,
            'date_created': DateTime.now().toIso8601String().split('T').first,
          }).select().maybeSingle();

          if (batchRes != null) {
            batchId = batchRes['batch_id'] ?? batchRes['id'];
          }
        } catch (bErr) {
          debugPrint('Batch insert with date_created failed: $bErr. Retrying with basic payload...');
          final batchRes = await _supabase.from('batches').insert({
            'batch_name': batchName,
          }).select().maybeSingle();

          if (batchRes != null) {
            batchId = batchRes['batch_id'] ?? batchRes['id'];
          }
        }
      }

      final isUnassigned = _selectedRaiserId == 'unassigned' || _selectedRaiserId == null;

      // Check if this batch already has an assignment record
      final existingAssignForBatch = batchId != null
          ? await _supabase
              .from('assignments')
              .select('assignment_id, hog_type_id')
              .eq('batch_id', batchId)
              .maybeSingle()
          : null;

      if (isUnassigned) {
        if (existingAssignForBatch != null) {
          await _supabase
              .from('assignments')
              .delete()
              .eq('assignment_id', existingAssignForBatch['assignment_id']);
        }
      } else if (int.tryParse(_selectedRaiserId!) != null) {
        final parsedRaiserId = int.parse(_selectedRaiserId!);

        // 1. Resolve required hog_type_id
        dynamic resolvedHogTypeId;
        try {
          final raiserInfo = await _supabase
              .from('hog_raisers')
              .select('pig_type')
              .eq('hog_raiser_id', parsedRaiserId)
              .maybeSingle();

          final pigTypeStr = raiserInfo?['pig_type']?.toString();

          if (pigTypeStr != null && pigTypeStr.isNotEmpty && pigTypeStr != 'N/A' && pigTypeStr.toLowerCase() != 'unassigned') {
            final typeMatch = await _supabase
                .from('hog_types')
                .select('hog_type_id')
                .ilike('type_name', '%$pigTypeStr%')
                .maybeSingle();
            if (typeMatch != null) {
              resolvedHogTypeId = typeMatch['hog_type_id'];
            }
          }

          if (resolvedHogTypeId == null) {
            final defaultType = await _supabase
                .from('hog_types')
                .select('hog_type_id')
                .limit(1)
                .maybeSingle();
            if (defaultType != null) {
              resolvedHogTypeId = defaultType['hog_type_id'];
            }
          }
        } catch (htErr) {
          debugPrint('Notice resolving hog_type_id: $htErr');
        }

        final int finalHogTypeId = resolvedHogTypeId != null
            ? (resolvedHogTypeId as num).toInt()
            : 1;

        if (existingAssignForBatch != null) {
          final updatePayload = <String, dynamic>{
            'hog_raiser_id': parsedRaiserId,
            'status': 'active',
            'hog_type_id': finalHogTypeId,
          };
          await _supabase
              .from('assignments')
              .update(updatePayload)
              .eq('assignment_id', existingAssignForBatch['assignment_id']);
        } else {
          final assignPayload = <String, dynamic>{
            'batch_id': batchId,
            'hog_raiser_id': parsedRaiserId,
            'status': 'active',
            'hog_type_id': finalHogTypeId,
          };
          await _supabase.from('assignments').insert(assignPayload);
        }
      }

      if (!mounted) return;
      widget.onShowSnackBar(_isEdit ? 'Batch updated successfully.' : 'Batch created and assigned successfully.');
      widget.onBatchSaved();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      widget.onShowSnackBar('Operation failed: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1350),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_panelStart, _panelEnd],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border.all(color: _panelBorder, width: 1),
            borderRadius: BorderRadius.circular(isMobile ? 16 : 34),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 14 : 34,
            vertical: isMobile ? 16 : 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit ? 'Edit Hog Batch' : 'Create New Hog Batch',
                          style: GoogleFonts.plusJakartaSans(
                            color: _titleColor,
                            fontSize: isMobile ? 22 : 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isEdit
                              ? 'Update batch name and assigned raiser details.'
                              : 'Define batch code and assign an authorized hog raiser.',
                          style: GoogleFonts.plusJakartaSans(
                            color: _mutedColor,
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onCancel,
                    icon: Icon(Icons.close_rounded, color: _titleColor, size: isMobile ? 24 : 28),
                    tooltip: 'Back to batches',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Form Body Container
              Container(
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                  border: Border.all(color: _cardBorder),
                ),
                padding: EdgeInsets.all(isMobile ? 16 : 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Batch Name
                    Text(
                      'BATCH NAME / CODE *',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _mutedColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _batchNameCtrl,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: const [CapitalizeWordsInputFormatter()],
                      onChanged: (_) {
                        if (_batchNameError != null) setState(() => _batchNameError = null);
                      },
                      style: GoogleFonts.plusJakartaSans(
                        color: _fieldText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. BATCH-2026-01',
                        hintStyle: GoogleFonts.plusJakartaSans(color: _mutedColor, fontSize: 14),
                        filled: true,
                        fillColor: _fieldBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _batchNameError != null ? const Color(0xFFE53E3E) : _fieldBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _batchNameError != null ? const Color(0xFFE53E3E) : _fieldFocus,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    if (_batchNameError != null) ...[
                      const SizedBox(height: 4),
                      Text(_batchNameError!, style: const TextStyle(color: Color(0xFFE53E3E), fontSize: 11.5)),
                    ],
                    const SizedBox(height: 22),

                    // Assign Hog Raiser Dropdown
                    Text(
                       'ASSIGN HOG RAISER',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _mutedColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRaiserId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _fieldBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _fieldBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _fieldFocus, width: 1.5),
                        ),
                      ),
                      dropdownColor: _fieldBg,
                      items: [
                        DropdownMenuItem<String>(
                          value: 'unassigned',
                          child: Row(
                            children: [
                              Icon(Icons.person_off_outlined, size: 16, color: _mutedColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _activeRaisers.isEmpty
                                      ? 'No Active Raisers Available (Unassigned)'
                                      : 'No Raiser Assigned (Unassigned)',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: _mutedColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ..._activeRaisers.map((r) {
                          final isAssignedElsewhere = r['is_assigned_elsewhere'] == true;
                          final assignedBatchName = r['assigned_batch_name'] ?? 'another Batch';
                          return DropdownMenuItem<String>(
                            value: r['id'].toString(),
                            enabled: !isAssignedElsewhere,
                            child: Row(
                              children: [
                                Icon(
                                  isAssignedElsewhere ? Icons.lock_outline_rounded : Icons.person_outline_rounded,
                                  size: 16,
                                  color: isAssignedElsewhere
                                      ? _mutedColor
                                      : (_isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isAssignedElsewhere
                                        ? '${r['name']} (Already Assigned to $assignedBatchName)'
                                        : '${r['name']}',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: isAssignedElsewhere ? _mutedColor.withValues(alpha: 0.6) : _fieldText,
                                      fontWeight: isAssignedElsewhere ? FontWeight.w500 : FontWeight.w600,
                                      fontStyle: isAssignedElsewhere ? FontStyle.italic : FontStyle.normal,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        final matched = _activeRaisers.firstWhere(
                          (r) => r['id'].toString() == val,
                          orElse: () => {},
                        );
                        if (matched['is_assigned_elsewhere'] == true) {
                          final bName = matched['assigned_batch_name'] ?? 'another Batch';
                          widget.onShowSnackBar(
                            '${matched['name']} is already assigned to $bName. A Hog Raiser can only be assigned to one active batch.',
                            isError: true,
                          );
                          return;
                        }
                        setState(() => _selectedRaiserId = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Responsive Action Buttons (Cancel / Submit)
              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitForm,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Icon(_isEdit ? Icons.save_rounded : Icons.add_rounded, size: 18),
                          label: Text(
                            _isSubmitting ? 'Saving...' : (_isEdit ? 'Save Changes' : 'Create Batch'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                            foregroundColor: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _isSubmitting ? null : widget.onCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: _fieldBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.plusJakartaSans(
                              color: _fieldText,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _isSubmitting ? null : widget.onCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            side: BorderSide(color: _fieldBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.plusJakartaSans(
                              color: _fieldText,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitForm,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Icon(_isEdit ? Icons.save_rounded : Icons.add_rounded, size: 18),
                          label: Text(
                            _isSubmitting ? 'Saving...' : (_isEdit ? 'Save Changes' : 'Create Batch'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                            foregroundColor: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
