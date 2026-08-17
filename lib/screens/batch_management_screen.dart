import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';
import '../widgets/slide_over_confirmation_drawer.dart';
import '../utils/responsive.dart';
import '../main.dart';

class BatchManagementScreen extends StatefulWidget {
  const BatchManagementScreen({super.key});

  @override
  State<BatchManagementScreen> createState() => _BatchManagementScreenState();
}

class _BatchManagementScreenState extends State<BatchManagementScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _batchesList = [];
  List<Map<String, dynamic>> _activeRaisers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatusFilter = 'ALL';

  // Form State
  final TextEditingController _batchNameCtrl = TextEditingController();
  final TextEditingController _totalHogCtrl = TextEditingController();
  final TextEditingController _capitalCtrl = TextEditingController();
  String? _selectedRaiserId = 'unassigned';
  List<String> _selectedHogTypes = ['Fattening'];
  String? _batchNameError;
  String? _totalHogError;
  String? _capitalError;
  String? _hogTypeError;
  bool _isDrawerSaving = false;
  Map<String, dynamic>? _editingBatch;

  // Theme Helpers
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgDark => _isDark ? PiggyTrunkTheme.ptBgDark : PiggyTrunkTheme.ptBg;
  Color get _panelStart => _isDark ? const Color(0xFF1A2940) : Colors.white;
  Color get _panelEnd => _isDark ? const Color(0xFF0F1C2F) : Colors.white;
  Color get _panelBorder => _isDark ? const Color(0xFF2A3E5B) : const Color(0xFFC9D8EC);
  Color get _cardBg => _isDark ? const Color(0xFF132238) : Colors.white;
  Color get _cardBorder => _isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
  Color get _titleColor => _isDark ? Colors.white : const Color(0xFF18314F);
  Color get _headerText => _isDark ? const Color(0xFF94A3B8) : const Color(0xFF4B6281);
  Color get _fieldBg => _isDark ? const Color(0xFF1A2B44) : const Color(0xFFF5F8FE);
  Color get _fieldBorder => _isDark ? const Color(0xFF28405D) : const Color(0xFFC9D8EC);
  Color get _fieldFocus => _isDark ? const Color(0xFF88A7CE) : const Color(0xFF315C8F);
  Color get _fieldText => _isDark ? Colors.white : const Color(0xFF18314F);
  Color get _hintText => _isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);
  Color get _successDark => _isDark ? PiggyTrunkTheme.ptSuccessDark : PiggyTrunkTheme.ptSuccess;
  Color get _inProgressDark => _isDark ? PiggyTrunkTheme.ptInProgressDark : PiggyTrunkTheme.ptInProgress;

  @override
  void initState() {
    super.initState();
    final session = _supabase.auth.currentSession;
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }
    if (isInitialLaunch) {
      isInitialLaunch = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      });
      return;
    }
    _loadData();
  }

  @override
  void dispose() {
    _batchNameCtrl.dispose();
    _totalHogCtrl.dispose();
    _capitalCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch all batches with their assignments, raiser, and hogs
      final batchesRes = await _supabase
          .from('batches')
          .select('*, assignments(*, hog_raisers(*), hogs(*))')
          .order('date_created', ascending: false);

      final List<Map<String, dynamic>> parsedBatches = [];
      for (var b in batchesRes as List) {
        final bMap = Map<String, dynamic>.from(b as Map);
        final assignments = (bMap['assignments'] as List?) ?? [];
        Map<String, dynamic>? activeAssign;
        if (assignments.isNotEmpty) {
          activeAssign = assignments.firstWhere(
            (a) => (a['status'] ?? '').toString().toLowerCase() == 'active',
            orElse: () => assignments.first,
          );
        }

        final raiser = activeAssign != null ? (activeAssign['hog_raisers'] as Map<String, dynamic>?) : null;
        final hogs = activeAssign != null ? ((activeAssign['hogs'] as List?) ?? []) : [];

        bMap['active_assignment'] = activeAssign;
        bMap['raiser_name'] = raiser != null ? (raiser['name'] ?? 'Unassigned') : 'Unassigned';
        bMap['raiser_id'] = raiser != null ? (raiser['hog_raiser_id'] ?? raiser['id']) : null;
        bMap['pig_type'] = raiser != null ? (raiser['pig_type'] ?? 'Fattening') : 'Fattening';
        bMap['hog_count'] = hogs.isNotEmpty ? hogs.length : (activeAssign != null ? (activeAssign['total_hogs'] ?? 0) : 0);
        bMap['status'] = activeAssign != null ? (activeAssign['status'] ?? 'Active') : 'Unassigned';

        parsedBatches.add(bMap);
      }

      // 2. Fetch active authorized hog raisers for dropdown
      await _fetchActiveRaisers();

      if (!mounted) return;
      setState(() {
        _batchesList = parsedBatches;
      });
    } catch (e) {
      debugPrint('Error loading batch data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchActiveRaisers() async {
    try {
      dynamic res;
      try {
        res = await _supabase
            .from('hog_raisers')
            .select('hog_raiser_id, name, pig_type, status, account_status, app_users!hog_raisers_user_id_fkey(name, email)')
            .order('name', ascending: true);
      } catch (_) {
        res = await _supabase
            .from('hog_raisers')
            .select('hog_raiser_id, name, pig_type, status, account_status')
            .order('name', ascending: true);
      }

      final List<Map<String, dynamic>> activeRows = [];
      for (var r in (res as List)) {
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

        activeRows.add({
          'id': idStr,
          'name': resolvedFullName,
          'pig_type': rMap['pig_type'] ?? 'Fattening',
          'real_pk_col': rMap['id'] != null ? 'id' : 'hog_raiser_id',
        });
      }

      _activeRaisers = [
        {'id': 'unassigned', 'name': 'Unassigned (Pool Batch)'},
        ...activeRows,
      ];
    } catch (e) {
      debugPrint('Error fetching raisers: $e');
      _activeRaisers = [
        {'id': 'unassigned', 'name': 'Unassigned (Pool Batch)'}
      ];
    }
  }

  // Filtered Batches
  List<Map<String, dynamic>> get _filteredBatches {
    return _batchesList.where((b) {
      final name = (b['batch_name'] ?? '').toString().toLowerCase();
      final raiser = (b['raiser_name'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase().trim();

      final matchesQuery = q.isEmpty || name.contains(q) || raiser.contains(q);
      if (!matchesQuery) return false;

      final status = (b['status'] ?? '').toString().toUpperCase();
      if (_selectedStatusFilter == 'ALL') return true;
      if (_selectedStatusFilter == 'ACTIVE') return status == 'ACTIVE';
      if (_selectedStatusFilter == 'COMPLETED') return status == 'COMPLETED';
      if (_selectedStatusFilter == 'UNASSIGNED') return status == 'UNASSIGNED' || (b['raiser_id'] == null);
      return true;
    }).toList();
  }

  // Open Drawer for Create / Edit
  Future<void> _openBatchDrawer({Map<String, dynamic>? existing}) async {
    _editingBatch = existing;
    _batchNameError = null;
    _totalHogError = null;
    _hogTypeError = null;

    // Refresh active raisers list before opening drawer
    await _fetchActiveRaisers();

    if (existing != null) {
      _batchNameCtrl.text = (existing['batch_name'] ?? '').toString();
      _totalHogCtrl.text = (existing['hog_count'] ?? 0).toString();
      final existingRaiserId = existing['raiser_id']?.toString();
      _selectedRaiserId = (existingRaiserId != null && existingRaiserId.isNotEmpty) ? existingRaiserId : 'unassigned';

      final pigTypeStr = (existing['pig_type'] ?? 'Fattening').toString();
      _selectedHogTypes = pigTypeStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (_selectedHogTypes.isEmpty) _selectedHogTypes = ['Fattening'];

      // Fetch associated investment capital if present
      if (_selectedRaiserId != null && _selectedRaiserId != 'unassigned') {
        try {
          final inv = await _supabase
              .from('investment_records')
              .select('initial_capital')
              .eq('hog_raiser_id', _selectedRaiserId!)
              .maybeSingle();
          if (inv != null && inv['initial_capital'] != null) {
            _capitalCtrl.text = inv['initial_capital'].toString();
          } else {
            _capitalCtrl.text = '';
          }
        } catch (_) {
          _capitalCtrl.text = '';
        }
      } else {
        _capitalCtrl.text = '';
      }
    } else {
      final nextNum = _batchesList.length + 1;
      _batchNameCtrl.text = 'Batch ${DateTime.now().year}-$nextNum';
      _totalHogCtrl.text = '';
      _capitalCtrl.text = '';
      _selectedRaiserId = 'unassigned';
      _selectedHogTypes = ['Fattening'];
    }

    if (!mounted) return;
    final isMobile = MediaQuery.of(context).size.width < 720;
    if (isMobile) {
      _showBatchBottomSheet(existing);
    } else {
      _showBatchSideDrawer(existing);
    }
  }

  void _showBatchSideDrawer(Map<String, dynamic>? existing) {
    final isEdit = existing != null;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: isEdit ? 'Edit Batch' : 'Create Batch',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
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
                width: 480,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: _cardBg,
                  border: Border(left: BorderSide(color: _cardBorder, width: 1.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(-4, 0),
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
                                    color: _isDark ? const Color(0xFF2563EB).withValues(alpha: 0.25) : PiggyTrunkTheme.ptPrimary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isEdit ? Icons.edit_note_rounded : Icons.layers_rounded,
                                    color: _isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary,
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
                                          color: _titleColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isEdit ? 'Update batch details and raiser assignment' : 'Define batch code, assigned raiser, and heads',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: _hintText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  icon: Icon(Icons.close_rounded, color: _hintText, size: 22),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Close panel',
                                ),
                              ],
                            ),
                          ),
                          Divider(color: _cardBorder.withValues(alpha: 0.5), height: 1),

                          // Form Content
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: _buildDrawerFormContent(
                                drawerCtx: dialogContext,
                                isEdit: isEdit,
                                isMobile: false,
                                setDrawerState: setDrawerState,
                              ),
                            ),
                          ),

                          // Footer Actions
                          Divider(color: _cardBorder.withValues(alpha: 0.5), height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isDrawerSaving ? null : () => Navigator.pop(dialogContext),
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
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    onPressed: _isDrawerSaving ? null : () => _handleSaveBatch(dialogContext, setDrawerState),
                                    icon: _isDrawerSaving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : Icon(isEdit ? Icons.save_rounded : Icons.add_rounded, size: 18),
                                    label: Text(
                                      _isDrawerSaving ? 'Saving...' : (isEdit ? 'Save Changes' : 'Create Batch'),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isDark ? PiggyTrunkTheme.ptSurface : PiggyTrunkTheme.ptPrimary,
                                      foregroundColor: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
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

  void _showBatchBottomSheet(Map<String, dynamic>? existing) {
    final isEdit = existing != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setDrawerState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: _cardBorder, width: 1.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _hintText.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        isEdit ? 'Edit Hog Batch' : 'Create New Hog Batch',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _titleColor,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: Icon(Icons.close_rounded, color: _hintText, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                Divider(color: _cardBorder.withValues(alpha: 0.5), height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildDrawerFormContent(
                      drawerCtx: sheetContext,
                      isEdit: isEdit,
                      isMobile: true,
                      setDrawerState: setDrawerState,
                    ),
                  ),
                ),
                Divider(color: _cardBorder.withValues(alpha: 0.5), height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isDrawerSaving ? null : () => Navigator.pop(sheetContext),
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
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isDrawerSaving ? null : () => _handleSaveBatch(sheetContext, setDrawerState),
                          icon: _isDrawerSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Icon(isEdit ? Icons.save_rounded : Icons.add_rounded, size: 18),
                          label: Text(
                            _isDrawerSaving ? 'Saving...' : (isEdit ? 'Save Changes' : 'Create Batch'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isDark ? PiggyTrunkTheme.ptSurface : PiggyTrunkTheme.ptPrimary,
                            foregroundColor: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerFormContent({
    required BuildContext drawerCtx,
    required bool isEdit,
    required bool isMobile,
    required StateSetter setDrawerState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. BATCH NAME / CODE
        Text(
          'BATCH NAME / CODE',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: _headerText,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _batchNameCtrl,
          onChanged: (_) {
            if (_batchNameError != null) setDrawerState(() => _batchNameError = null);
          },
          style: GoogleFonts.plusJakartaSans(
            color: _fieldText,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          decoration: _createInputDecoration('e.g. Batch Alpha 2026', hasError: _batchNameError != null).copyWith(
            prefixIcon: Icon(Icons.tag_rounded, color: _isDark ? const Color(0xFF60A5FA) : _headerText, size: 20),
          ),
        ),
        if (_batchNameError != null) _buildInlineError(_batchNameError!),
        const SizedBox(height: 20),

        // 2. ASSIGNED HOG RAISER
        Text(
          'ASSIGNED HOG RAISER',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: _headerText,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: _createInputDecoration('Select authorized raiser').copyWith(
            prefixIcon: Icon(Icons.person_outline_rounded, color: _isDark ? const Color(0xFF60A5FA) : _headerText, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _activeRaisers.any((r) => r['id'].toString() == _selectedRaiserId)
                  ? _selectedRaiserId
                  : 'unassigned',
              isExpanded: true,
              menuMaxHeight: 260,
              borderRadius: BorderRadius.circular(12),
              dropdownColor: _fieldBg,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: _hintText),
              style: GoogleFonts.plusJakartaSans(color: _fieldText, fontSize: 14, fontWeight: FontWeight.w600),
              items: _activeRaisers
                  .map((raiser) => DropdownMenuItem<String>(
                        value: raiser['id'].toString(),
                        child: Text(
                          (raiser['name'] ?? '').toString(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _fieldText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                setDrawerState(() {
                  _selectedRaiserId = value;
                  if (value != null && value != 'unassigned') {
                    final matched = _activeRaisers.firstWhere((r) => r['id'].toString() == value, orElse: () => {});
                    final pt = matched['pig_type']?.toString();
                    if (pt != null && pt.isNotEmpty && pt != 'Auto-populated' && pt != 'N/A') {
                      final types = pt.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                      if (types.isNotEmpty) {
                        _selectedHogTypes = types;
                      }
                    }
                  }
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 3. TOTAL HOGS (HEADS)
        Text(
          'TOTAL HOGS (HEADS)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: _headerText,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _totalHogCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) {
            if (_totalHogError != null) setDrawerState(() => _totalHogError = null);
          },
          style: GoogleFonts.plusJakartaSans(
            color: _fieldText,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          decoration: _createInputDecoration('0', hasError: _totalHogError != null).copyWith(
            suffixIcon: Container(
              width: 72,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF4FD),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                border: Border(
                  left: BorderSide(color: _fieldBorder),
                ),
              ),
              child: Text(
                'Heads',
                style: GoogleFonts.plusJakartaSans(
                  color: _isDark ? const Color(0xFFCBD5E1) : _fieldText,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            suffixIconConstraints: const BoxConstraints(minWidth: 72, minHeight: 48),
          ),
        ),
        if (_totalHogError != null) _buildInlineError(_totalHogError!),
        const SizedBox(height: 20),

        // 4. INITIAL CAPITAL (PHP)
        Text(
          'INITIAL CAPITAL (PHP)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: _headerText,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _capitalCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) {
            if (_capitalError != null) setDrawerState(() => _capitalError = null);
          },
          style: GoogleFonts.plusJakartaSans(
            color: _fieldText,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          decoration: _createInputDecoration('0.00', hasError: _capitalError != null).copyWith(
            prefixIcon: Container(
              width: 48,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF4FD),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
                border: Border(
                  right: BorderSide(color: _fieldBorder),
                ),
              ),
              child: Text(
                '₱',
                style: GoogleFonts.plusJakartaSans(
                  color: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ),
        if (_capitalError != null) _buildInlineError(_capitalError!),
        const SizedBox(height: 20),

        // 4. HOG TYPE ASSIGNMENT
        Text(
          'HOG TYPE ASSIGNMENT',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: _headerText,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        if (_hogTypeError != null) ...[
          _buildInlineError(_hogTypeError!),
          const SizedBox(height: 6),
        ],
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  setDrawerState(() {
                    _hogTypeError = null;
                    if (_selectedHogTypes.contains('Fattening')) {
                      if (_selectedHogTypes.length > 1) _selectedHogTypes.remove('Fattening');
                    } else {
                      _selectedHogTypes.add('Fattening');
                    }
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: _selectedHogTypes.contains('Fattening')
                        ? (_isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEEF4FD))
                        : _fieldBg,
                    border: Border.all(
                      color: _selectedHogTypes.contains('Fattening')
                          ? (_isDark ? Colors.white : PiggyTrunkTheme.ptPrimary)
                          : _fieldBorder,
                      width: _selectedHogTypes.contains('Fattening') ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedHogTypes.contains('Fattening') ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        color: _selectedHogTypes.contains('Fattening')
                            ? (_isDark ? Colors.white : PiggyTrunkTheme.ptPrimary)
                            : _hintText,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fattening',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: _selectedHogTypes.contains('Fattening') ? FontWeight.w700 : FontWeight.w500,
                            color: _selectedHogTypes.contains('Fattening')
                                ? (_isDark ? Colors.white : PiggyTrunkTheme.ptPrimary)
                                : (_isDark ? const Color(0xFF94A3B8) : const Color(0xFF4B6281)),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () {
                  setDrawerState(() {
                    _hogTypeError = null;
                    if (_selectedHogTypes.contains('Sow / Breeding')) {
                      if (_selectedHogTypes.length > 1) _selectedHogTypes.remove('Sow / Breeding');
                    } else {
                      _selectedHogTypes.add('Sow / Breeding');
                    }
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: _selectedHogTypes.contains('Sow / Breeding')
                        ? (_isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEEF4FD))
                        : _fieldBg,
                    border: Border.all(
                      color: _selectedHogTypes.contains('Sow / Breeding')
                          ? (_isDark ? Colors.white : PiggyTrunkTheme.ptPrimary)
                          : _fieldBorder,
                      width: _selectedHogTypes.contains('Sow / Breeding') ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedHogTypes.contains('Sow / Breeding') ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        color: _selectedHogTypes.contains('Sow / Breeding')
                            ? (_isDark ? Colors.white : PiggyTrunkTheme.ptPrimary)
                            : _hintText,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sow / Breeding',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: _selectedHogTypes.contains('Sow / Breeding') ? FontWeight.w700 : FontWeight.w500,
                            color: _selectedHogTypes.contains('Sow / Breeding')
                                ? (_isDark ? Colors.white : PiggyTrunkTheme.ptPrimary)
                                : (_isDark ? const Color(0xFF94A3B8) : const Color(0xFF4B6281)),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleSaveBatch(BuildContext drawerCtx, StateSetter setDrawerState) async {
    final batchName = _batchNameCtrl.text.trim();
    final parsedTotalHog = int.tryParse(_totalHogCtrl.text.trim());

    String? nameErr;
    String? totalHogErr;
    String? hogTypeErr;

    if (batchName.isEmpty) {
      nameErr = 'Please enter a batch name or code.';
    }

    if (parsedTotalHog == null || parsedTotalHog <= 0) {
      totalHogErr = 'Please enter valid total hogs count (min 1).';
    }

    if (_selectedHogTypes.isEmpty) {
      hogTypeErr = 'Please select at least one Hog Type.';
    }

    if (nameErr != null || totalHogErr != null || hogTypeErr != null) {
      setDrawerState(() {
        _batchNameError = nameErr;
        _totalHogError = totalHogErr;
        _hogTypeError = hogTypeErr;
      });
      return;
    }

    setDrawerState(() {
      _batchNameError = null;
      _totalHogError = null;
      _hogTypeError = null;
      _isDrawerSaving = true;
    });

    final isUnassigned = _selectedRaiserId == 'unassigned';
    final hogTypeStr = _selectedHogTypes.join(', ');
    final isEdit = _editingBatch != null;

    try {
      dynamic batchId;

      if (isEdit) {
        batchId = _editingBatch!['batch_id'];
        await _supabase.from('batches').update({
          'batch_name': batchName,
        }).eq('batch_id', batchId);
      } else {
        final batchRes = await _supabase.from('batches').insert({
          'batch_name': batchName,
          'date_created': DateTime.now().toIso8601String().split('T').first,
        }).select('batch_id').maybeSingle();

        if (batchRes != null && batchRes['batch_id'] != null) {
          batchId = batchRes['batch_id'];
        }
      }

      if (!isUnassigned && int.tryParse(_selectedRaiserId!) != null) {
        final parsedRaiserId = int.parse(_selectedRaiserId!);

        // 1. Check or Create/Update Assignment
        dynamic assignId;
        final existingAssign = await _supabase
            .from('assignments')
            .select('assignment_id')
            .eq('hog_raiser_id', parsedRaiserId)
            .eq('status', 'active')
            .maybeSingle();

        if (existingAssign != null) {
          assignId = existingAssign['assignment_id'];
          if (batchId != null) {
            await _supabase.from('assignments').update({
              'batch_id': batchId,
            }).eq('assignment_id', assignId);
          }
        } else {
          final assignPayload = <String, dynamic>{
            'hog_raiser_id': parsedRaiserId,
            'status': 'active',
            'start_date': DateTime.now().toIso8601String().split('T').first,
          };
          if (batchId != null) assignPayload['batch_id'] = batchId;

          final newAssignRes = await _supabase
              .from('assignments')
              .insert(assignPayload)
              .select('assignment_id')
              .maybeSingle();

          if (newAssignRes != null) {
            assignId = newAssignRes['assignment_id'];
          }
        }

        // 2. Generate / Update Hogs
        if (assignId != null && !isEdit) {
          final count = parsedTotalHog ?? 5;
          final List<Map<String, dynamic>> hogsToInsert = [];
          for (int i = 1; i <= count; i++) {
            hogsToInsert.add({
              'assignment_id': assignId,
              'tag_number': 'HOG-$parsedRaiserId-$i',
              'status': 'active',
              'health_status': 'Healthy',
              'current_weight': 15.0,
            });
          }
          if (hogsToInsert.isNotEmpty) {
            await _supabase.from('hogs').insert(hogsToInsert);
          }
        }

        // 3. Update Hog Raiser info
        final raiserRow = _activeRaisers.firstWhere(
          (r) => r['id'].toString() == _selectedRaiserId,
          orElse: () => {},
        );
        final pkCol = raiserRow['real_pk_col'] ?? (raiserRow['id'] != null ? 'id' : 'hog_raiser_id');
        await _supabase
            .from('hog_raisers')
            .update({
              'lifecycle_stage': 'Booster',
              'pig_type': hogTypeStr,
            })
            .eq(pkCol, parsedRaiserId);

        // 4. Auto-sync with investment_records table
        try {
          final parsedCapital = double.tryParse(_capitalCtrl.text.trim()) ?? ((parsedTotalHog ?? 5) * 3000.0);
          final raiserName = raiserRow['name']?.toString() ?? 'Hog Raiser';

          final existingInv = await _supabase
              .from('investment_records')
              .select('id')
              .eq('hog_raiser_id', parsedRaiserId.toString())
              .maybeSingle();

          if (existingInv != null) {
            await _supabase.from('investment_records').update({
              'initial_capital': parsedCapital,
              'hog_type': hogTypeStr,
              'total_hog': parsedTotalHog ?? 5,
              'raiser_name': raiserName,
              'stage': 'active',
            }).eq('id', existingInv['id']);
          } else {
            await _supabase.from('investment_records').insert({
              'hog_raiser_id': parsedRaiserId.toString(),
              'raiser_name': raiserName,
              'initial_capital': parsedCapital,
              'hog_type': hogTypeStr,
              'total_hog': parsedTotalHog ?? 5,
              'investment_date': DateTime.now().toIso8601String(),
              'stage': 'active',
            });
          }
        } catch (invErr) {
          debugPrint('Investment auto-sync notice: $invErr');
        }
      }

      setDrawerState(() => _isDrawerSaving = false);
      if (drawerCtx.mounted) Navigator.pop(drawerCtx);

      await _loadData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'Batch updated successfully.' : 'Batch created and assigned successfully!',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          backgroundColor: PiggyTrunkTheme.ptSuccess,
        ),
      );
    } catch (e) {
      setDrawerState(() => _isDrawerSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteBatch(Map<String, dynamic> batch) async {
    final name = (batch['batch_name'] ?? 'Batch').toString();
    final confirm = await SlideOverConfirmationDrawer.show(
      context: context,
      title: 'Delete Hog Batch',
      message: 'Are you sure you want to delete "$name"? Associated assignments and active hogs may be affected.',
      actionType: SlideOverActionType.danger,
      userName: name,
      userRole: 'Batch Record',
      confirmButtonText: 'Yes, Delete',
      cancelButtonText: 'Cancel',
    );

    if (confirm != true) return;

    try {
      final batchId = batch['batch_id'];
      if (batchId != null) {
        await _supabase.from('batches').delete().eq('batch_id', batchId);
      }
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Batch deleted successfully.', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          backgroundColor: PiggyTrunkTheme.ptSuccess,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  InputDecoration _createInputDecoration(String hint, {bool hasError = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(color: _hintText, fontSize: 14, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: _fieldBg,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: hasError ? const Color(0xFFE53E3E) : _fieldBorder,
          width: hasError ? 1.5 : 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: hasError ? const Color(0xFFE53E3E) : _fieldFocus,
          width: hasError ? 1.5 : 1,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildInlineError(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 2, bottom: 2),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFE53E3E)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFE53E3E)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = Responsive.isSmallScreen(context);

    return Scaffold(
      backgroundColor: _bgDark,
      drawer: isSmall
          ? Drawer(
              backgroundColor: _cardBg,
              child: AdminSidebar(
                currentRoute: '/batches',
                onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
                isDrawer: true,
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isSmall)
            AdminSidebar(
              currentRoute: '/batches',
              onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
            ),
          Expanded(
            child: Column(
              children: [
                const ScreenTopBar(),
                Expanded(child: _buildMainContent(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalBatches = _batchesList.length;
    final activeBatches = _batchesList.where((b) => (b['status'] ?? '').toString().toUpperCase() == 'ACTIVE').length;
    final totalHogs = _batchesList.fold<int>(0, (sum, b) => sum + (b['hog_count'] as int? ?? 0));
    final unassignedBatches = _batchesList.where((b) => b['raiser_id'] == null).length;

    return SingleChildScrollView(
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
              // 1. Metric Overview Cards
              _buildMetricsRow(totalBatches, activeBatches, totalHogs, unassignedBatches, isMobile),
              const SizedBox(height: 24),

              // 2. Main Table Card
              Container(
                decoration: BoxDecoration(
                  color: _cardBg,
                  border: Border.all(color: _cardBorder, width: 1),
                  borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
                ),
                padding: EdgeInsets.all(isMobile ? 14 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header & Action Row
                    if (isMobile)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Batch Management',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _titleColor,
                              letterSpacing: -0.04,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _openBatchDrawer(),
                              icon: const Icon(Icons.add_rounded, size: 20),
                              label: Text(
                                'Create Batch',
                                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              style: _primaryButtonStyle(minWidth: 0),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Batch Management',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: _titleColor,
                                  letterSpacing: -0.04,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Create and assign batches of hogs to active authorized raisers',
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: _headerText),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _openBatchDrawer(),
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: Text(
                              'Create Batch',
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            style: _primaryButtonStyle(minWidth: 160),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),

                    // Search and Filters
                    _buildSearchAndFilters(isMobile),
                    const SizedBox(height: 16),

                    // Data Table
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final tableWidth = constraints.maxWidth > 950 ? constraints.maxWidth : 950.0;
                        final batches = _filteredBatches;

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: tableWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTableHeader(),
                                if (batches.isEmpty)
                                  Container(
                                    width: tableWidth,
                                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: _cardBorder.withValues(alpha: 0.7))),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'No batches found matching criteria.',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: _titleColor),
                                      ),
                                    ),
                                  )
                                else
                                  ...List.generate(
                                    batches.length,
                                    (index) => _buildTableRow(context, batches[index], index),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
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

  Widget _buildMetricsRow(int total, int active, int hogs, int unassigned, bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricCard('Total Batches', '$total', Icons.layers_rounded, _isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary)),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricCard('Active Batches', '$active', Icons.check_circle_rounded, PiggyTrunkTheme.ptSuccess)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildMetricCard('Total Hogs', '$hogs heads', Icons.pets_rounded, const Color(0xFFFFAA00))),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricCard('Unassigned', '$unassigned', Icons.pending_outlined, const Color(0xFFF43F5E))),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _buildMetricCard('Total Batches', '$total', Icons.layers_rounded, _isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary)),
        const SizedBox(width: 14),
        Expanded(child: _buildMetricCard('Active Batches', '$active', Icons.check_circle_rounded, PiggyTrunkTheme.ptSuccess)),
        const SizedBox(width: 14),
        Expanded(child: _buildMetricCard('Total Hogs Assigned', '$hogs heads', Icons.pets_rounded, const Color(0xFFFFAA00))),
        const SizedBox(width: 14),
        Expanded(child: _buildMetricCard('Unassigned Pool', '$unassigned', Icons.pending_outlined, const Color(0xFFF43F5E))),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border.all(color: _cardBorder, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: _headerText),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: _titleColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isMobile) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: isMobile ? double.infinity : 280,
          height: 42,
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: GoogleFonts.plusJakartaSans(color: _fieldText, fontSize: 13.5, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Search batch or raiser...',
              hintStyle: GoogleFonts.plusJakartaSans(color: _hintText, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, size: 18, color: _hintText),
              filled: true,
              fillColor: _fieldBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _fieldBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _fieldFocus)),
            ),
          ),
        ),
        _buildFilterChip('ALL', 'All Batches'),
        _buildFilterChip('ACTIVE', 'Active'),
        _buildFilterChip('COMPLETED', 'Completed'),
        _buildFilterChip('UNASSIGNED', 'Unassigned'),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedStatusFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedStatusFilter = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (_isDark ? Colors.white : PiggyTrunkTheme.ptPrimary)
              : (_isDark ? const Color(0xFF1E2F47) : const Color(0xFFEEF4FD)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.transparent : _fieldBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? (_isDark ? PiggyTrunkTheme.ptPrimary : Colors.white)
                : _headerText,
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF1E2D44) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _headerTitle('BATCH NAME / CODE')),
          Expanded(flex: 3, child: _headerTitle('ASSIGNED RAISER')),
          Expanded(flex: 2, child: _headerTitle('HOG TYPE', align: TextAlign.center)),
          Expanded(flex: 2, child: _headerTitle('HEADS (HOGS)', align: TextAlign.center)),
          Expanded(flex: 2, child: _headerTitle('DATE CREATED', align: TextAlign.center)),
          Expanded(flex: 2, child: _headerTitle('STATUS', align: TextAlign.center)),
          Expanded(flex: 2, child: _headerTitle('ACTIONS', align: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _headerTitle(String text, {TextAlign align = TextAlign.left}) {
    return Text(
      text,
      textAlign: align,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: _headerText,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, Map<String, dynamic> batch, int index) {
    final batchName = (batch['batch_name'] ?? 'Batch').toString();
    final raiserName = (batch['raiser_name'] ?? 'Unassigned').toString();
    final isUnassigned = batch['raiser_id'] == null;
    final pigType = (batch['pig_type'] ?? 'Fattening').toString();
    final hogCount = batch['hog_count'] ?? 0;
    final dateStr = (batch['date_created'] ?? '').toString();
    final status = (batch['status'] ?? 'Active').toString().toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _cardBorder.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          // Batch Name
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(Icons.layers_rounded, size: 18, color: _isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    batchName,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: _titleColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Assigned Raiser
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(isUnassigned ? Icons.person_off_rounded : Icons.person_rounded, size: 16, color: isUnassigned ? Colors.orangeAccent : _headerText),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    raiserName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isUnassigned ? Colors.orangeAccent : _titleColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Hog Type
          Expanded(
            flex: 2,
            child: Center(
              child: _buildHogTypeBadge(pigType),
            ),
          ),
          // Heads
          Expanded(
            flex: 2,
            child: Text(
              '$hogCount heads',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: _titleColor),
            ),
          ),
          // Date Created
          Expanded(
            flex: 2,
            child: Text(
              dateStr.isNotEmpty ? dateStr : 'N/A',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: _headerText),
            ),
          ),
          // Status Badge
          Expanded(
            flex: 2,
            child: Center(
              child: _buildStatusBadge(status),
            ),
          ),
          // Actions
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _openBatchDrawer(existing: batch),
                  icon: Icon(Icons.edit_outlined, size: 20, color: _headerText),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Edit Batch',
                ),
                const SizedBox(width: 14),
                IconButton(
                  onPressed: () => _deleteBatch(batch),
                  icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFFF758C)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Delete Batch',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHogTypeBadge(String hogType) {
    final isBreeding = hogType.toLowerCase().contains('breed') || hogType.toLowerCase().contains('sow');
    final bg = isBreeding
        ? (_isDark ? const Color(0xFF581C87).withValues(alpha: 0.45) : Colors.purple.withValues(alpha: 0.12))
        : (_isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.45) : const Color(0xFFEFF6FF));
    final fg = isBreeding
        ? (_isDark ? const Color(0xFFD8B4FE) : Colors.purple)
        : (_isDark ? const Color(0xFF93C5FD) : const Color(0xFF18314F));
    final border = isBreeding
        ? (_isDark ? const Color(0xFFA855F7).withValues(alpha: 0.6) : Colors.purple.withValues(alpha: 0.3))
        : (_isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.6) : const Color(0xFF93C5FD));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        hogType,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;

    if (status == 'ACTIVE') {
      bg = _successDark.withValues(alpha: 0.2);
      fg = _successDark;
    } else if (status == 'COMPLETED') {
      bg = _inProgressDark.withValues(alpha: 0.2);
      fg = _inProgressDark;
    } else {
      bg = Colors.orange.withValues(alpha: 0.2);
      fg = Colors.orangeAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle({double minWidth = 0}) {
    return ElevatedButton.styleFrom(
      backgroundColor: _isDark ? PiggyTrunkTheme.ptSurface : PiggyTrunkTheme.ptPrimary,
      foregroundColor: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      elevation: 0,
      minimumSize: Size(minWidth, 42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
