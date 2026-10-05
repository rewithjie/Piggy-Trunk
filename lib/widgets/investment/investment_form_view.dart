import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/investment_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../common/searchable_dropdown_field.dart';
import '../common/shimmer_loading.dart';

class InvestmentFormView extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onSaved;
  final Investment? existingInvestment;
  final void Function(String msg, {bool isError}) onShowSnackBar;

  const InvestmentFormView({
    super.key,
    required this.onCancel,
    required this.onSaved,
    this.existingInvestment,
    required this.onShowSnackBar,
  });

  @override
  State<InvestmentFormView> createState() => _InvestmentFormViewState();
}

class _InvestmentFormViewState extends State<InvestmentFormView> {
  final SupabaseClient _supabase = Supabase.instance.client;

  late final TextEditingController _capitalCtrl;
  late final TextEditingController _totalHogCtrl;

  String? _selectedRaiserId;
  String? _selectedBatchId;
  List<String> _selectedHogTypes = ['Fattening'];

  List<Map<String, dynamic>> _activeBatches = [];
  List<Map<String, dynamic>> _activeRaisers = [];
  bool _isLoadingData = true;
  bool _isSubmitting = false;

  String? _capitalError;
  String? _totalHogError;

  bool get _isEdit => widget.existingInvestment != null;
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
    _capitalCtrl = TextEditingController(
      text: _isEdit ? widget.existingInvestment!.initialCapital.toInt().toString() : '',
    );
    _totalHogCtrl = TextEditingController(
      text: _isEdit ? widget.existingInvestment!.totalHog.toString() : '',
    );

    _selectedRaiserId = _isEdit
        ? (widget.existingInvestment!.hogRaiserId.isEmpty
            ? 'unassigned'
            : widget.existingInvestment!.hogRaiserId)
        : 'unassigned';

    _selectedBatchId = _isEdit
        ? (widget.existingInvestment!.batchId != null && widget.existingInvestment!.batchId!.isNotEmpty
            ? widget.existingInvestment!.batchId!
            : 'unassigned')
        : 'unassigned';

    if (_isEdit && widget.existingInvestment!.hogType.isNotEmpty) {
      final types = widget.existingInvestment!.hogType
          .split(RegExp(r'[,;]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .map((s) => s.toLowerCase().contains('sow') || s.toLowerCase().contains('breed') ? 'Sow / Breeding' : 'Fattening')
          .toSet()
          .toList();
      if (types.isNotEmpty) _selectedHogTypes = types;
    }

    _fetchDropdownData();
  }

  @override
  void dispose() {
    _capitalCtrl.dispose();
    _totalHogCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDropdownData() async {
    try {
      // 1. Fetch Batches (ordered newest first)
      List<dynamic> batchesRaw = [];
      try {
        batchesRaw = await _supabase
            .from('batches')
            .select('*')
            .order('batch_id', ascending: false);
      } catch (bErr) {
        debugPrint('Error fetching batches with order: $bErr');
        try {
          batchesRaw = await _supabase.from('batches').select('*');
        } catch (_) {}
      }

      final Map<String, String> batchNamesMap = {
        for (var b in batchesRaw)
          (b['batch_id'] ?? b['id'] ?? '').toString(): (b['batch_name'] ?? 'Batch #${b['batch_id']}').toString()
      };

      // 2. Fetch Assignments
      List<dynamic> assignmentsRaw = [];
      try {
        assignmentsRaw = await _supabase.from('assignments').select('*');
      } catch (aErr) {
        debugPrint('Error fetching assignments: $aErr');
      }

      // 3. Fetch Hogs (to calculate hog count per batch / assignment)
      List<dynamic> hogsRaw = [];
      try {
        hogsRaw = await _supabase.from('hogs').select('*');
      } catch (hErr) {
        debugPrint('Error fetching hogs: $hErr');
      }

      final Map<String, int> assignmentHogCounts = {};
      for (var h in hogsRaw) {
        if (h is! Map) continue;
        final assignId = (h['assignment_id'] ?? h['id'])?.toString() ?? '';
        if (assignId.isNotEmpty) {
          assignmentHogCounts[assignId] = (assignmentHogCounts[assignId] ?? 0) + 1;
        }
      }

      final Map<String, String> batchStatusMap = {
        for (var b in batchesRaw)
          (b['batch_id'] ?? b['id'] ?? '').toString(): (b['status'] ?? b['batch_status'] ?? 'Active').toString().toLowerCase()
      };

      // Map active raisers to assigned batches (1 is to 1 tracking)
      final Map<String, Map<String, dynamic>> raiserAssignedBatchMap = {};
      for (var a in assignmentsRaw) {
        if (a is! Map) continue;
        final assignId = (a['assignment_id'] ?? a['id'])?.toString() ?? '';
        final rId = (a['hog_raiser_id'] ?? '').toString();
        final bId = (a['batch_id'] ?? '').toString();
        final bName = batchNamesMap[bId] ?? 'Batch #$bId';
        final bStatus = batchStatusMap[bId] ?? 'active';
        final st = (a['status'] ?? 'active').toString().toLowerCase();

        // Check if batch itself is explicitly completed or archived
        final bool isBatchCompleted = bStatus == 'completed' || bStatus == 'archived' || bStatus == 'harvested' || bStatus == 'sold';
        final bool isAssignCompleted = st == 'completed' || st == 'archived' || st == 'finished';

        // Check if all hogs of this assignment reached terminal stage (sow in lactation, fattening in selling/sold)
        final assignHogs = hogsRaw.where((h) {
          if (h is! Map) return false;
          final hAssignId = (h['assignment_id'] ?? '').toString();
          final hBatchId = (h['batch_id'] ?? '').toString();
          final hRaiserId = (h['hog_raiser_id'] ?? '').toString();
          return (assignId.isNotEmpty && hAssignId == assignId) ||
                 (bId.isNotEmpty && hBatchId == bId) ||
                 (rId.isNotEmpty && hRaiserId == rId);
        }).toList();

        bool allHogsCycleDone = false;
        if (assignHogs.isNotEmpty) {
          final htStr = (a['hog_types']?['type_name'] ?? a['pig_type'] ?? '').toString().toLowerCase();
          final isSow = htStr.contains('sow') || htStr.contains('breed');
          allHogsCycleDone = assignHogs.every((h) {
            final s = (h['stage_id'] ?? h['lifecycle_stage'] ?? h['stage'] ?? '').toString().trim().toLowerCase();
            return isSow ? (s == 'lactation' || s == '6' || s.contains('lactat')) : (s == 'selling' || s == 'sold' || s == '6' || s.contains('sell'));
          });
        }

        final bool isCycleCompleted = isBatchCompleted || isAssignCompleted || allHogsCycleDone;

        if (rId.isNotEmpty && bId.isNotEmpty) {
          final existing = raiserAssignedBatchMap[rId];
          if (existing == null || (existing['is_completed'] == true && !isCycleCompleted)) {
            raiserAssignedBatchMap[rId] = {
              'batch_id': bId,
              'batch_name': bName,
              'is_completed': isCycleCompleted,
              'status': st,
            };
          }
        }
      }

      // 4. Fetch authorized active/approved raisers (ordered newest first by hog_raiser_id)
      List<dynamic> raisersRaw = [];
      try {
        raisersRaw = await _supabase
            .from('hog_raisers')
            .select('hog_raiser_id, name, pig_type, status, account_status, app_users!hog_raisers_user_id_fkey(name, email)')
            .order('hog_raiser_id', ascending: false);
      } catch (rErr) {
        debugPrint('Notice loading raisers with app_users relation: $rErr. Retrying basic...');
        try {
          raisersRaw = await _supabase
              .from('hog_raisers')
              .select('hog_raiser_id, name, pig_type, status, account_status')
              .order('hog_raiser_id', ascending: false);
        } catch (rErr2) {
          debugPrint('Error fetching raisers fallback: $rErr2');
        }
      }

      final Map<String, Map<String, dynamic>> raisersMap = {};
      final List<Map<String, dynamic>> parsedRaisers = [];

      for (var r in raisersRaw) {
        if (r is! Map) continue;
        final rMap = Map<String, dynamic>.from(r);
        final accStatus = (rMap['account_status'] ?? '').toString().toLowerCase();
        if (accStatus == 'rejected' || accStatus == 'pending') continue;

        dynamic appUsersRaw = rMap['app_users'];
        Map<String, dynamic>? appUsers;
        if (appUsersRaw is Map) {
          appUsers = Map<String, dynamic>.from(appUsersRaw);
        } else if (appUsersRaw is List && appUsersRaw.isNotEmpty && appUsersRaw.first is Map) {
          appUsers = Map<String, dynamic>.from(appUsersRaw.first);
        }

        final googleOrAppName = (appUsers?['name'] ?? '').toString().trim();
        final raiserName = (rMap['name'] ?? '').toString().trim();
        final resolvedFullName = (raiserName.isNotEmpty &&
                raiserName.toLowerCase() != 'hog raiser' &&
                raiserName.toUpperCase() != 'N/A')
            ? raiserName
            : (googleOrAppName.isNotEmpty && googleOrAppName.toLowerCase() != 'hog raiser'
                ? googleOrAppName
                : (raiserName.isNotEmpty ? raiserName : 'Hog Raiser'));

        final idStr = (rMap['hog_raiser_id'] ?? rMap['id'] ?? '').toString();
        if (idStr.isEmpty) continue;

        final assignedInfo = raiserAssignedBatchMap[idStr];
        final assignedBatchId = assignedInfo?['batch_id']?.toString();
        final assignedBatchName = assignedInfo?['batch_name']?.toString();
        final rStage = (rMap['lifecycle_stage'] ?? rMap['current_stage'] ?? '').toString().toLowerCase();
        final isRaiserStageCompleted = rStage.contains('lactat') || rStage.contains('sell') || rStage == 'completed';
        final isBatchCompleted = (assignedInfo?['is_completed'] == true) || isRaiserStageCompleted;

        final raiserEntry = {
          'id': idStr,
          'name': resolvedFullName,
          'pig_type': rMap['pig_type'] ?? 'Fattening',
          'phone': rMap['phone'] ?? 'N/A',
          'assigned_batch_id': assignedBatchId,
          'assigned_batch_name': assignedBatchName,
          'is_batch_completed': isBatchCompleted,
          'real_pk_col': 'hog_raiser_id',
        };
        parsedRaisers.add(raiserEntry);
        raisersMap[idStr] = raiserEntry;
      }

      final List<Map<String, dynamic>> parsedBatches = [];
      for (var b in batchesRaw) {
        if (b is! Map) continue;
        final bMap = Map<String, dynamic>.from(b);
        final bId = (bMap['batch_id'] ?? bMap['id'] ?? bMap['batch_number'] ?? bMap['batch_code'])?.toString() ?? '';
        if (bId.isEmpty) continue;
        final bName = bMap['batch_name']?.toString() ?? bMap['name']?.toString() ?? 'Batch $bId';

        // Find active assignment for this batch
        Map<String, dynamic>? matchingAssign;
        for (var a in assignmentsRaw) {
          if (a is Map && (a['batch_id']?.toString() == bId || a['id']?.toString() == bId)) {
            if ((a['status'] ?? '').toString().toLowerCase() == 'active') {
              matchingAssign = Map<String, dynamic>.from(a);
              break;
            }
            matchingAssign ??= Map<String, dynamic>.from(a);
          }
        }

        String raiserId = '';
        String raiserName = 'Unassigned';
        String pigType = 'Fattening';
        int hogCount = 0;

        if (matchingAssign != null) {
          final assignId = (matchingAssign['assignment_id'] ?? matchingAssign['id'])?.toString() ?? '';
          hogCount = assignmentHogCounts[assignId] ?? 0;
          raiserId = (matchingAssign['hog_raiser_id'] ?? '').toString();

          if (raisersMap.containsKey(raiserId)) {
            raiserName = raisersMap[raiserId]!['name'] ?? 'Hog Raiser';
            pigType = raisersMap[raiserId]!['pig_type'] ?? 'Fattening';
          }
        }

        parsedBatches.add({
          'batch_id': bId,
          'batch_name': bName,
          'display_label': bName,
          'raiser_id': raiserId,
          'raiser_name': raiserName,
          'pig_type': pigType,
          'hog_count': hogCount,
        });
      }

      // Sort raisers newest first (highest id at top, oldest created at bottom)
      parsedRaisers.sort((a, b) {
        final idA = int.tryParse(a['id'].toString()) ?? 0;
        final idB = int.tryParse(b['id'].toString()) ?? 0;
        return idB.compareTo(idA);
      });

      // Sort batches newest first (highest batch_id at top, oldest at bottom)
      parsedBatches.sort((a, b) {
        final idA = int.tryParse(a['batch_id'].toString()) ?? 0;
        final idB = int.tryParse(b['batch_id'].toString()) ?? 0;
        return idB.compareTo(idA);
      });

      if (_isEdit) {
        if (_selectedBatchId == null || _selectedBatchId == 'unassigned') {
          final bNameFromInv = widget.existingInvestment!.batchName;
          if (bNameFromInv != null && bNameFromInv.isNotEmpty) {
            final match = parsedBatches.firstWhere(
              (b) => b['batch_name'].toString().toLowerCase() == bNameFromInv.toLowerCase(),
              orElse: () => {},
            );
            if (match.isNotEmpty) {
              _selectedBatchId = match['batch_id'].toString();
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _activeRaisers = parsedRaisers;
          _activeBatches = [
            {
              'batch_id': 'unassigned',
              'batch_name': 'No Specific Batch (General Fund)',
              'display_label': 'General Fund (No Batch)',
              'raiser_id': '',
              'raiser_name': 'Unassigned',
              'pig_type': 'Fattening',
              'hog_count': 0,
              'is_assigned_elsewhere': false,
            },
            ...parsedBatches,
          ];
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Error in _fetchDropdownData: $e');
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;

    final parsedCapital = int.tryParse(_capitalCtrl.text.trim());
    final parsedTotalHog = int.tryParse(_totalHogCtrl.text.trim());

    if (parsedCapital == null || parsedCapital <= 0) {
      setState(() => _capitalError = 'Please enter a valid capital greater than ₱0.');
      return;
    }
    if (parsedTotalHog == null || parsedTotalHog <= 0) {
      setState(() => _totalHogError = 'Please enter total number of heads (min 1).');
      return;
    }

    final isRaiserUnassigned = _selectedRaiserId == 'unassigned' || _selectedRaiserId == null || _selectedRaiserId!.isEmpty;
    final isBatchUnassigned = _selectedBatchId == 'unassigned' || _selectedBatchId == null || _selectedBatchId!.isEmpty;

    // Each batch can only be assigned to one Hog Raiser, but a Hog Raiser can manage multiple active batches (e.g. Fattening and Sow/Breeding)

    // 1-IS-TO-1 STRICT VALIDATION: Batch cannot be assigned to multiple raisers
    if (!isBatchUnassigned && !isRaiserUnassigned) {
      final matchedBatch = _activeBatches.firstWhere(
        (b) => b['batch_id'].toString() == _selectedBatchId,
        orElse: () => {},
      );
      final assignedRaiserId = (matchedBatch['raiser_id'] ?? '').toString();
      if (assignedRaiserId.isNotEmpty && assignedRaiserId != 'unassigned' && assignedRaiserId != _selectedRaiserId && !_isEdit) {
        final rName = matchedBatch['raiser_name'] ?? 'another Hog Raiser';
        widget.onShowSnackBar(
          '${matchedBatch['batch_name']} is already assigned to $rName. Each batch belongs to 1 Hog Raiser (1:1 ratio).',
          isError: true,
        );
        return;
      }
    }

    setState(() {
      _capitalError = null;
      _totalHogError = null;
      _isSubmitting = true;
    });

    try {
      final raiserName = isRaiserUnassigned
          ? 'Unassigned'
          : (_activeRaisers.firstWhere(
              (r) => r['id'].toString() == _selectedRaiserId,
              orElse: () => {'name': 'Hog Raiser'},
            )['name'] ?? 'Hog Raiser');

      final batchName = isBatchUnassigned
          ? 'Unassigned'
          : (_activeBatches.firstWhere(
              (b) => b['batch_id'].toString() == _selectedBatchId,
              orElse: () => {'batch_name': 'Batch'},
            )['batch_name'] ?? 'Batch');

      final cleanTypes = _selectedHogTypes
          .map((s) => s.toLowerCase().contains('sow') || s.toLowerCase().contains('breed') ? 'Sow' : 'Fattening')
          .toSet()
          .toList();
      final hogTypeStr = cleanTypes.isNotEmpty ? cleanTypes.join(', ') : 'Fattening';

      // Batch-to-raiser validation before saving: ensures the selected batch is not already taken by another raiser
      if (!isRaiserUnassigned && !isBatchUnassigned && int.tryParse(_selectedRaiserId!) != null) {
        final parsedRaiserId = int.parse(_selectedRaiserId!);
        try {
          final batchAssigns = await _supabase
              .from('assignments')
              .select('assignment_id, hog_raiser_id')
              .eq('batch_id', _selectedBatchId!)
              .or('status.eq.active,status.eq.Active');

          for (final bA in (batchAssigns as List? ?? [])) {
            final assignedRaiserId = bA['hog_raiser_id'];
            if (assignedRaiserId != null && assignedRaiserId != parsedRaiserId && !_isEdit) {
              if (!mounted) return;
              setState(() => _isSubmitting = false);
              widget.onShowSnackBar(
                'This batch is already assigned to another Hog Raiser. Each batch belongs to 1 Hog Raiser (1:1 ratio).',
                isError: true,
              );
              return;
            }
          }
        } catch (valErr) {
          debugPrint('Notice during batch assignment pre-validation: $valErr');
        }
      }

      final payload = <String, dynamic>{
        'hog_raiser_id': isRaiserUnassigned ? null : _selectedRaiserId,
        'raiser_name': raiserName,
        'initial_capital': parsedCapital,
        'hog_type': hogTypeStr,
        'total_hog': parsedTotalHog,
        'investment_date': _isEdit
            ? widget.existingInvestment!.investmentDate.toIso8601String()
            : DateTime.now().toIso8601String(),
        if (!_isEdit) 'stage': 'active',
        if (!isBatchUnassigned && _selectedBatchId != null && _selectedBatchId != 'unassigned')
          'batch_id': _selectedBatchId,
        if (!isBatchUnassigned && _selectedBatchId != null && _selectedBatchId != 'unassigned' && batchName.isNotEmpty && batchName != 'Unassigned')
          'batch_name': batchName,
      };

      try {
        if (_isEdit) {
          await _supabase.from('investment_records').update(payload).eq('id', widget.existingInvestment!.id);
        } else {
          await _supabase.from('investment_records').insert(payload);
        }
      } catch (dbErr) {
        final errStr = dbErr.toString().toLowerCase();
        if (errStr.contains('batch_id') || errStr.contains('batch_name') || errStr.contains('pgrst204')) {
          final fallbackPayload = Map<String, dynamic>.from(payload)
            ..remove('batch_id')
            ..remove('batch_name');
          if (_isEdit) {
            await _supabase.from('investment_records').update(fallbackPayload).eq('id', widget.existingInvestment!.id);
          } else {
            await _supabase.from('investment_records').insert(fallbackPayload);
          }
        } else {
          rethrow;
        }
      }

      // Assign Hog Raiser to Batch in `assignments` table (1:1 linking)
      if (!isBatchUnassigned) {
        dynamic resolvedHogTypeId;
        try {
          final typeMatch = await _supabase
              .from('hog_types')
              .select('hog_type_id')
              .ilike('type_name', '%$hogTypeStr%')
              .maybeSingle();
          if (typeMatch != null) {
            resolvedHogTypeId = typeMatch['hog_type_id'];
          }
          if (resolvedHogTypeId == null) {
            final defaultType = await _supabase.from('hog_types').select('hog_type_id').limit(1).maybeSingle();
            if (defaultType != null) {
              resolvedHogTypeId = defaultType['hog_type_id'];
            }
          }
        } catch (htErr) {
          debugPrint('Notice resolving hog_type_id: $htErr');
        }

        final int finalHogTypeId = resolvedHogTypeId != null ? (resolvedHogTypeId as num).toInt() : 1;

        // Check if an assignment already exists for this batch
        final existingAssign = await _supabase
            .from('assignments')
            .select('assignment_id, hog_type_id, hog_raiser_id')
            .eq('batch_id', _selectedBatchId!)
            .limit(1)
            .maybeSingle();

        if (existingAssign != null) {
          final existingRaiserId = (existingAssign['hog_raiser_id'] ?? '').toString();
          if (existingRaiserId.isNotEmpty && !isRaiserUnassigned && _selectedRaiserId != existingRaiserId) {
            widget.onShowSnackBar('This batch is already assigned to another Hog Raiser. Each batch belongs to 1 Hog Raiser (1:1 ratio).', isError: true);
            setState(() => _isSubmitting = false);
            return;
          }
        }

        if (!isRaiserUnassigned && int.tryParse(_selectedRaiserId!) != null) {
          final parsedRaiserId = int.parse(_selectedRaiserId!);

          // 1 Raiser = 1 Batch: Conclude any previous active assignment for this raiser
          try {
            final prevAssigns = await _supabase
                .from('assignments')
                .select('assignment_id, hog_type_id, status')
                .eq('hog_raiser_id', parsedRaiserId)
                .neq('batch_id', _selectedBatchId!)
                .or('status.eq.active,status.eq.Active,status.eq.assigned');
            for (final pa in (prevAssigns as List? ?? [])) {
              if (pa is! Map) continue;
              await _supabase
                  .from('assignments')
                  .update({'status': 'completed'})
                  .eq('assignment_id', pa['assignment_id']);
            }
          } catch (prevErr) {
            debugPrint('Notice concluding previous assignments for raiser $parsedRaiserId: $prevErr');
          }

          final isSow = hogTypeStr.toLowerCase().contains('sow') || hogTypeStr.toLowerCase().contains('breed');
          final defaultStage = isSow ? 'Gilt' : 'Booster';

          dynamic targetAssignPk;
          if (existingAssign != null) {
            targetAssignPk = existingAssign['assignment_id'];
            final existingRaiserId = (existingAssign['hog_raiser_id'] ?? '').toString();
            await _supabase.from('assignments').update({
                if (existingRaiserId.isEmpty) 'hog_raiser_id': parsedRaiserId,
                'status': 'active',
                'hog_type_id': finalHogTypeId,
              }).eq('assignment_id', targetAssignPk);

            // Reactivate batch in batches table
            try {
              await _supabase.from('batches').update({'status': 'Active'}).eq('batch_id', _selectedBatchId!);
            } catch (_) {}

            // Seed hogs for the assignment
            try {
              final existingHogs = await _supabase.from('hogs').select('hog_id, stage_id, status').eq('assignment_id', targetAssignPk);
              final existingList = existingHogs as List;
              final hasCompletedHogs = existingList.any((h) {
                final st = h['stage_id'] as num?;
                return (st != null && st >= 6) || (h['status'] ?? '').toString().toLowerCase() == 'completed';
              });

              if (hasCompletedHogs && !_isEdit) {
                // Archive previous completed cycle hogs so fresh batch cycle starts cleanly
                await _supabase.from('hogs').update({
                  'status': 'completed',
                  'last_updated': DateTime.now().toIso8601String(),
                }).eq('assignment_id', targetAssignPk);

                for (int i = 0; i < parsedTotalHog; i++) {
                  await _supabase.from('hogs').insert({
                    'assignment_id': targetAssignPk,
                    'status': 'active',
                    'health_status': 'healthy',
                    'stage_id': 1,
                    'last_updated': DateTime.now().toIso8601String(),
                  });
                }
              } else {
                final activeExisting = existingList.where((h) => h['status'] != 'completed').toList();
                final needed = parsedTotalHog - activeExisting.length;
                if (needed > 0) {
                  for (int i = 0; i < needed; i++) {
                    await _supabase.from('hogs').insert({
                      'assignment_id': targetAssignPk,
                      'status': 'active',
                      'health_status': 'healthy',
                      'stage_id': 1,
                      'last_updated': DateTime.now().toIso8601String(),
                    });
                  }
                }
                // When starting a new investment cycle on this batch, update existing hogs to match
                if (!_isEdit && activeExisting.isNotEmpty) {
                  await _supabase.from('hogs').update({
                    'stage_id': 1,
                    'status': 'active',
                    'health_status': 'healthy',
                    'last_updated': DateTime.now().toIso8601String(),
                  }).eq('assignment_id', targetAssignPk);
                }
              }
            } catch (hErr) {
              debugPrint('Notice seeding hogs: $hErr');
            }
          } else {
            final assignRes = await _supabase.from('assignments').insert({
              'batch_id': _selectedBatchId,
              'hog_raiser_id': parsedRaiserId,
              'status': 'active',
              'hog_type_id': finalHogTypeId,
              'assigned_date': DateTime.now().toIso8601String().split('T').first,
            }).select('assignment_id').maybeSingle();

            // Reactivate batch in batches table
            try {
              await _supabase.from('batches').update({'status': 'Active'}).eq('batch_id', _selectedBatchId!);
            } catch (_) {}

            if (assignRes != null) {
              targetAssignPk = assignRes['assignment_id'];
              if (targetAssignPk != null) {
                try {
                  for (int i = 0; i < parsedTotalHog; i++) {
                    await _supabase.from('hogs').insert({
                      'assignment_id': targetAssignPk,
                      'status': 'active',
                      'health_status': 'healthy',
                      'stage_id': 1,
                      'last_updated': DateTime.now().toIso8601String(),
                    });
                  }
                } catch (_) {}
              }
            }
          }

          final String overallType = isSow ? 'Sow' : 'Fattening';

          await _supabase
              .from('hog_raisers')
              .update({
                'status': 'Active',
                'lifecycle_stage': defaultStage,
                'pig_type': overallType,
              })
              .eq('hog_raiser_id', parsedRaiserId);
        }
      } else if (!isRaiserUnassigned && int.tryParse(_selectedRaiserId!) != null) {
        // Fallback: If batch was left unassigned, attach newly added hogs to raiser's active assignment
        final parsedRaiserId = int.parse(_selectedRaiserId!);
        try {
          final raiserAssign = await _supabase
              .from('assignments')
              .select('assignment_id, batch_id')
              .eq('hog_raiser_id', parsedRaiserId)
              .order('assignment_id', ascending: false)
              .limit(1)
              .maybeSingle();

          if (raiserAssign != null) {
            final targetAssignId = raiserAssign['assignment_id'];
            final bId = raiserAssign['batch_id'];
            await _supabase.from('assignments').update({'status': 'active'}).eq('assignment_id', targetAssignId);
            if (bId != null) {
              try {
                await _supabase.from('batches').update({'status': 'Active'}).eq('batch_id', bId);
              } catch (_) {}
            }
            for (int i = 0; i < parsedTotalHog; i++) {
              await _supabase.from('hogs').insert({
                'assignment_id': targetAssignId,
                'status': 'active',
                'health_status': 'healthy',
                'stage_id': 1,
                'last_updated': DateTime.now().toIso8601String(),
              });
            }
          }
        } catch (_) {}
      }

      if (!mounted) return;
      widget.onShowSnackBar(
        _isEdit
            ? 'Investment updated successfully.'
            : (isRaiserUnassigned
                ? 'Investment created successfully.'
                : 'Investment for $batchName created and $raiserName assigned successfully.'),
      );
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      widget.onShowSnackBar('Operation failed: $e', isError: true);
    }
  }

  Widget _buildCheckboxOption({
    required String title,
    required bool isSelected,
    required VoidCallback onToggle,
  }) {
    final activeColor = _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary;
    final checkColor = _isDark ? const Color(0xFF132238) : Colors.white;
    final inactiveBorder = _isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 19,
              height: 19,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: isSelected ? activeColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? activeColor : inactiveBorder,
                  width: 1.8,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: checkColor,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: _isDark ? Colors.white : const Color(0xFF18314F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Skeleton for a single labeled form field (dropdown or text input).
  Widget _buildFormFieldSkeleton({
    required String label,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: _mutedColor,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        ShimmerBox(
          width: double.infinity,
          height: 48,
          borderRadius: BorderRadius.circular(10),
          isDark: _isDark,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    if (_isLoadingData) {
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
            child: ShimmerProvider(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header skeleton (Title + Close button)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(
                              width: isMobile ? 200 : 280,
                              height: isMobile ? 22 : 28,
                              borderRadius: BorderRadius.circular(6),
                              isDark: _isDark,
                            ),
                            const SizedBox(height: 8),
                            ShimmerBox(
                              width: isMobile ? 260 : 420,
                              height: 12,
                              borderRadius: BorderRadius.circular(4),
                              isDark: _isDark,
                            ),
                          ],
                        ),
                      ),
                      ShimmerBox(
                        width: isMobile ? 32 : 36,
                        height: isMobile ? 32 : 36,
                        borderRadius: BorderRadius.circular(8),
                        isDark: _isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Form Card skeleton
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
                        // SELECT BATCH TO FUND label + dropdown skeleton
                        _buildFormFieldSkeleton(
                          label: 'SELECT BATCH TO FUND *',
                          isMobile: isMobile,
                        ),
                        const SizedBox(height: 22),

                        // ASSIGN HOG RAISER label + dropdown skeleton
                        _buildFormFieldSkeleton(
                          label: 'ASSIGN HOG RAISER *',
                          isMobile: isMobile,
                        ),
                        const SizedBox(height: 22),

                        // INITIAL CAPITAL label + input skeleton
                        _buildFormFieldSkeleton(
                          label: 'INITIAL CAPITAL (PHP) *',
                          isMobile: isMobile,
                        ),
                        const SizedBox(height: 22),

                        // TOTAL HEADS label + input skeleton
                        _buildFormFieldSkeleton(
                          label: 'TOTAL HEADS *',
                          isMobile: isMobile,
                        ),
                        const SizedBox(height: 22),

                        // HOG TYPE label + checkbox skeletons
                        Text(
                          'HOG TYPE *',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: _mutedColor,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ShimmerBox(
                              width: 19,
                              height: 19,
                              borderRadius: BorderRadius.circular(5),
                              isDark: _isDark,
                            ),
                            const SizedBox(width: 10),
                            ShimmerBox(
                              width: 70,
                              height: 13,
                              borderRadius: BorderRadius.circular(4),
                              isDark: _isDark,
                            ),
                            const SizedBox(width: 24),
                            ShimmerBox(
                              width: 19,
                              height: 19,
                              borderRadius: BorderRadius.circular(5),
                              isDark: _isDark,
                            ),
                            const SizedBox(width: 10),
                            ShimmerBox(
                              width: 100,
                              height: 13,
                              borderRadius: BorderRadius.circular(4),
                              isDark: _isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons skeleton
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ShimmerBox(
                          height: 48,
                          borderRadius: BorderRadius.circular(10),
                          isDark: _isDark,
                        ),
                        const SizedBox(height: 10),
                        ShimmerBox(
                          height: 48,
                          borderRadius: BorderRadius.circular(10),
                          isDark: _isDark,
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ShimmerBox(
                          width: 100,
                          height: 48,
                          borderRadius: BorderRadius.circular(10),
                          isDark: _isDark,
                        ),
                        const SizedBox(width: 12),
                        ShimmerBox(
                          width: 170,
                          height: 48,
                          borderRadius: BorderRadius.circular(10),
                          isDark: _isDark,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
                          _isEdit ? 'Edit Investment' : 'Add New Investment',
                          style: GoogleFonts.plusJakartaSans(
                            color: _titleColor,
                            fontSize: isMobile ? 22 : 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isEdit
                              ? 'Update investment details, assigned raiser, and capital allocation.'
                              : 'Assign an authorized hog raiser, allocate capital, and fund a batch.',
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
                    tooltip: 'Back to investments',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Form Card Container
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
                    // SELECT BATCH TO FUND DROPDOWN (Searchable & Sorted Newest First)
                    Text(
                      'SELECT BATCH TO FUND *',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _mutedColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SearchableDropdownField<String>(
                      key: ValueKey('batch_dropdown_${_selectedBatchId}_${_activeBatches.length}'),
                      value: _activeBatches.any((b) => b['batch_id'].toString() == _selectedBatchId)
                          ? _selectedBatchId
                          : (_activeBatches.isNotEmpty ? _activeBatches.first['batch_id'].toString() : 'unassigned'),
                      unassignedValue: 'unassigned',
                      hintText: 'Select or search a batch to fund',
                      searchHintText: 'Type to search batch name or raiser...',
                      isDark: _isDark,
                      fieldBg: _fieldBg,
                      fieldBorder: _fieldBorder,
                      fieldFocus: _fieldFocus,
                      fieldText: _fieldText,
                      mutedColor: _mutedColor,
                      cardBg: _cardBg,
                      cardBorder: _cardBorder,
                      defaultPrefixIcon: Icons.layers_outlined,
                      items: _activeBatches.map((b) {
                        final isUnassigned = b['batch_id'] == 'unassigned';
                        final rName = (b['raiser_name'] ?? '').toString();
                        final hasRaiser = rName.isNotEmpty && rName != 'Unassigned';
                        final count = b['hog_count'] ?? 0;
                        return SearchableDropdownItem<String>(
                          value: b['batch_id'].toString(),
                          label: b['display_label'].toString(),
                          subtitle: isUnassigned
                              ? null
                              : (hasRaiser ? 'Raiser: $rName • $count hogs' : (count > 0 ? '$count hogs' : null)),
                          badge: hasRaiser ? rName : null,
                          badgeColor: hasRaiser
                              ? (_isDark ? const Color(0xFFCBD5E1) : PiggyTrunkTheme.ptPrimary)
                              : null,
                          icon: isUnassigned ? Icons.layers_clear_outlined : Icons.layers_outlined,
                          iconColor: isUnassigned
                              ? (_isDark ? const Color(0xFF94A3B8) : _mutedColor)
                              : (_isDark ? const Color(0xFF9CB0C9) : PiggyTrunkTheme.ptPrimary),
                          searchKeywords: '${b['batch_name']} $rName',
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _selectedBatchId = val;
                          if (val != 'unassigned') {
                            final matched = _activeBatches.firstWhere(
                              (b) => b['batch_id'].toString() == val,
                              orElse: () => {},
                            );
                            final rId = (matched['raiser_id'] ?? '').toString();
                            if (rId.isNotEmpty && rId != 'unassigned') {
                              if (_activeRaisers.any((r) => r['id'].toString() == rId)) {
                                _selectedRaiserId = rId;
                              }
                            }
                            final pt = (matched['pig_type'] ?? 'Fattening').toString().trim();
                            if (pt.isNotEmpty && pt != 'N/A') {
                              final parsed = pt.split(RegExp(r'[,;]')).map((s) => s.trim()).where((s) => s.isNotEmpty).map((s) => s.toLowerCase().contains('sow') ? 'Sow / Breeding' : 'Fattening').toSet().toList();
                              if (parsed.isNotEmpty) _selectedHogTypes = parsed;
                            }
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 22),

                    // ASSIGN HOG RAISER DROPDOWN (Searchable & Sorted Newest First)
                    Text(
                      'ASSIGN HOG RAISER *',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _mutedColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SearchableDropdownField<String>(
                      key: ValueKey('raiser_dropdown_${_selectedRaiserId}_${_activeRaisers.length}'),
                      value: _activeRaisers.any((r) => r['id'].toString() == _selectedRaiserId)
                          ? _selectedRaiserId
                          : 'unassigned',
                      unassignedValue: 'unassigned',
                      hintText: 'Select or search a hog raiser',
                      searchHintText: 'Type to search hog raiser by name...',
                      isDark: _isDark,
                      fieldBg: _fieldBg,
                      fieldBorder: _fieldBorder,
                      fieldFocus: _fieldFocus,
                      fieldText: _fieldText,
                      mutedColor: _mutedColor,
                      cardBg: _cardBg,
                      cardBorder: _cardBorder,
                      defaultPrefixIcon: Icons.person_outline_rounded,
                      items: [
                        SearchableDropdownItem<String>(
                          value: 'unassigned',
                          label: _activeRaisers.isEmpty
                              ? 'No Authorized Raisers (Unassigned)'
                              : 'Unassigned (General Pool)',
                          icon: Icons.person_off_outlined,
                          iconColor: _isDark ? const Color(0xFF94A3B8) : _mutedColor,
                          searchKeywords: 'unassigned general pool none',
                        ),
                        ..._activeRaisers.map((r) {
                          final rBatchId = r['assigned_batch_id']?.toString();
                          final hasBatch = rBatchId != null && rBatchId.isNotEmpty;
                          final assignedBatchName = r['assigned_batch_name'] ?? 'another Batch';
                          final isBatchCompleted = r['is_batch_completed'] == true;

                          final currentSelectedBatch = (_selectedBatchId != null && _selectedBatchId != 'unassigned')
                              ? _activeBatches.firstWhere((b) => b['batch_id'].toString() == _selectedBatchId, orElse: () => {})
                              : null;
                          final currentBatchRaiserId = (currentSelectedBatch?['raiser_id'] ?? '').toString();
                          final hasCurrentBatchRaiser = currentBatchRaiserId.isNotEmpty && currentBatchRaiserId != 'unassigned';
                          final bool isLockedOut = hasCurrentBatchRaiser && r['id'].toString() != currentBatchRaiserId;

                          final isAssignedToCurrent = hasBatch &&
                              _selectedBatchId != null &&
                              _selectedBatchId != 'unassigned' &&
                              rBatchId == _selectedBatchId;

                          String subText = '';
                          Color? bColor;
                          String? badgeText;
                          IconData itemIcon;
                          Color? iconCol;

                          if (isLockedOut) {
                            subText = 'Locked (Batch assigned to ${currentSelectedBatch!['raiser_name']})';
                            bColor = _isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
                            badgeText = '1:1 Locked';
                            itemIcon = Icons.lock_outline_rounded;
                            iconCol = _isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
                          } else if (isBatchCompleted) {
                            subText = 'Available (Completed $assignedBatchName)';
                            bColor = PiggyTrunkTheme.ptSuccess;
                            badgeText = 'Available';
                            itemIcon = Icons.check_circle_outline_rounded;
                            iconCol = PiggyTrunkTheme.ptSuccess;
                          } else if (isAssignedToCurrent) {
                            subText = 'Currently assigned to $assignedBatchName';
                            bColor = _isDark ? const Color(0xFFCBD5E1) : PiggyTrunkTheme.ptPrimary;
                            badgeText = assignedBatchName;
                            itemIcon = Icons.person_rounded;
                            iconCol = _isDark ? const Color(0xFF9CB0C9) : PiggyTrunkTheme.ptPrimary;
                          } else if (hasBatch) {
                            subText = 'Assigned to $assignedBatchName';
                            bColor = _isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
                            badgeText = assignedBatchName;
                            itemIcon = Icons.person_rounded;
                            iconCol = _isDark ? const Color(0xFF9CB0C9) : const Color(0xFF4B6281);
                          } else {
                            subText = 'Ready to assign';
                            bColor = null;
                            badgeText = null;
                            itemIcon = Icons.person_outline_rounded;
                            iconCol = _isDark ? const Color(0xFF9CB0C9) : const Color(0xFF64748B);
                          }

                          return SearchableDropdownItem<String>(
                            value: r['id'].toString(),
                            label: r['name'].toString(),
                            subtitle: subText.isNotEmpty ? subText : null,
                            badge: badgeText,
                            badgeColor: bColor,
                            isEnabled: !isLockedOut,
                            icon: itemIcon,
                            iconColor: iconCol,
                            searchKeywords: '${r['name']} $assignedBatchName ${r['pig_type'] ?? ''} ${isBatchCompleted ? 'available completed' : ''}',
                          );
                        }),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        // 1:1 Batch-to-Raiser Enforcement:
                        // If the currently selected batch is already assigned to a DIFFERENT raiser, prevent changing the raiser!
                        if (_selectedBatchId != null && _selectedBatchId != 'unassigned' && val != 'unassigned') {
                          final currentBatch = _activeBatches.firstWhere(
                            (b) => b['batch_id'].toString() == _selectedBatchId,
                            orElse: () => {},
                          );
                          final assignedRaiserId = (currentBatch['raiser_id'] ?? '').toString();
                          if (assignedRaiserId.isNotEmpty && assignedRaiserId != 'unassigned' && assignedRaiserId != val) {
                            final assignedRaiserName = currentBatch['raiser_name'] ?? 'another Hog Raiser';
                            widget.onShowSnackBar(
                              '${currentBatch['batch_name']} is already assigned to $assignedRaiserName. Each batch belongs to 1 Hog Raiser (1:1 ratio).',
                              isError: true,
                            );
                            return;
                          }
                        }

                        final matched = _activeRaisers.firstWhere(
                          (r) => r['id'].toString() == val,
                          orElse: () => {},
                        );
                        setState(() {
                          _selectedRaiserId = val;
                          if (val != 'unassigned') {
                            // If this raiser already has an active batch and no batch is currently selected, auto-select it!
                            final rBatchId = matched['assigned_batch_id']?.toString();
                            if (rBatchId != null && rBatchId.isNotEmpty && (_selectedBatchId == null || _selectedBatchId == 'unassigned')) {
                              if (_activeBatches.any((b) => b['batch_id'].toString() == rBatchId)) {
                                _selectedBatchId = rBatchId;
                              }
                            }
                            final pt = (matched['pig_type'] ?? '').toString().trim();
                            if (pt.isNotEmpty && pt != 'N/A') {
                              final parsed = pt.split(RegExp(r'[,;]')).map((s) => s.trim()).where((s) => s.isNotEmpty).map((s) => s.toLowerCase().contains('sow') ? 'Sow / Breeding' : 'Fattening').toSet().toList();
                              if (parsed.isNotEmpty) _selectedHogTypes = parsed;
                            }
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 22),

                    // Initial Capital
                    Text(
                      'INITIAL CAPITAL (PHP) *',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _mutedColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _capitalCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) {
                        if (_capitalError != null) setState(() => _capitalError = null);
                      },
                      style: GoogleFonts.plusJakartaSans(
                        color: _fieldText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: GoogleFonts.plusJakartaSans(color: _mutedColor, fontSize: 14),
                        prefixIcon: Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: Text(
                            '₱',
                            style: GoogleFonts.plusJakartaSans(
                              color: _mutedColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        filled: true,
                        fillColor: _fieldBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _capitalError != null ? const Color(0xFFE53E3E) : _fieldBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _capitalError != null ? const Color(0xFFE53E3E) : _fieldFocus,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    if (_capitalError != null) ...[
                      const SizedBox(height: 4),
                      Text(_capitalError!, style: const TextStyle(color: Color(0xFFE53E3E), fontSize: 11.5)),
                    ],
                    const SizedBox(height: 22),

                    // Total Heads
                    Text(
                      'TOTAL HEADS *',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _mutedColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _totalHogCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) {
                        if (_totalHogError != null) setState(() => _totalHogError = null);
                      },
                      style: GoogleFonts.plusJakartaSans(
                        color: _fieldText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: GoogleFonts.plusJakartaSans(color: _mutedColor, fontSize: 14),
                        prefixIcon: Icon(Icons.pets_rounded, size: 18, color: _mutedColor),
                        filled: true,
                        fillColor: _fieldBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _totalHogError != null ? const Color(0xFFE53E3E) : _fieldBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _totalHogError != null ? const Color(0xFFE53E3E) : _fieldFocus,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    if (_totalHogError != null) ...[
                      const SizedBox(height: 4),
                      Text(_totalHogError!, style: const TextStyle(color: Color(0xFFE53E3E), fontSize: 11.5)),
                    ],
                    const SizedBox(height: 22),

                    // Hog Types
                    Text(
                      'HOG TYPE *',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _mutedColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 24,
                      runSpacing: 10,
                      children: [
                        _buildCheckboxOption(
                          title: 'Fattening',
                          isSelected: _selectedHogTypes.contains('Fattening'),
                          onToggle: () {
                            setState(() {
                              if (_selectedHogTypes.contains('Fattening')) {
                                if (_selectedHogTypes.length > 1) _selectedHogTypes.remove('Fattening');
                              } else {
                                _selectedHogTypes.add('Fattening');
                              }
                            });
                          },
                        ),
                        _buildCheckboxOption(
                          title: 'Sow / Breeding',
                          isSelected: _selectedHogTypes.contains('Sow / Breeding'),
                          onToggle: () {
                            setState(() {
                              if (_selectedHogTypes.contains('Sow / Breeding')) {
                                if (_selectedHogTypes.length > 1) _selectedHogTypes.remove('Sow / Breeding');
                              } else {
                                _selectedHogTypes.add('Sow / Breeding');
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Responsive Action Buttons
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
                            _isSubmitting ? 'Saving...' : (_isEdit ? 'Save Changes' : 'Save Investment'),
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
                            _isSubmitting ? 'Saving...' : (_isEdit ? 'Save Changes' : 'Save Investment'),
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
