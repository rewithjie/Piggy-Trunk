import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';
import '../widgets/slide_over_confirmation_drawer.dart';
import '../utils/responsive.dart';
import '../widgets/batch/batch_detail_drawer.dart';
import '../widgets/batch/batch_form_view.dart';
import '../widgets/batch/batch_table_view.dart';
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
  bool _showBatchForm = false;
  Map<String, dynamic>? _editingBatch;
  String _searchQuery = '';
  String _selectedStatusFilter = 'ALL';

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgDark => _isDark ? PiggyTrunkTheme.ptBgDark : PiggyTrunkTheme.ptBg;
  Color get _panelStart => _isDark ? const Color(0xFF1A2940) : Colors.white;
  Color get _panelEnd => _isDark ? const Color(0xFF0F1C2F) : Colors.white;
  Color get _panelBorder => _isDark ? const Color(0xFF2A3E5B) : const Color(0xFFC9D8EC);

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

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. Fetch batches
      List<dynamic> batchesData = [];
      try {
        batchesData = await _supabase
            .from('batches')
            .select('batch_id, batch_name, date_created')
            .order('date_created', ascending: false);
      } catch (e) {
        debugPrint('Error fetching batches: $e');
      }

      // 2. Fetch assignments
      List<dynamic> assignmentsData = [];
      try {
        assignmentsData = await _supabase
            .from('assignments')
            .select('assignment_id, batch_id, hog_raiser_id, status, hog_raisers(name, hog_raiser_id)');
      } catch (e) {
        debugPrint('Error fetching assignments: $e');
      }

      // 3. Fetch active authorized raisers
      List<dynamic> raisersData = [];
      try {
        raisersData = await _supabase
            .from('hog_raisers')
            .select('hog_raiser_id, name, phone, email, status, account_status');
      } catch (e) {
        debugPrint('Error fetching raisers: $e');
      }

      final List<Map<String, dynamic>> parsedBatches = [];

      for (var b in batchesData) {
        final bMap = Map<String, dynamic>.from(b as Map);
        final bId = bMap['batch_id'];

        // Find assignment for this batch
        final matchingAssign = assignmentsData.firstWhere(
          (a) => a['batch_id'] == bId && (a['status'] ?? '').toString().toLowerCase() == 'active',
          orElse: () => assignmentsData.firstWhere(
            (a) => a['batch_id'] == bId,
            orElse: () => null,
          ),
        );

        String raiserName = 'Unassigned';
        dynamic raiserId;

        if (matchingAssign != null) {
          final raiser = matchingAssign['hog_raisers'] as Map<String, dynamic>?;
          raiserName = raiser?['name'] ?? 'Hog Raiser';
          raiserId = matchingAssign['hog_raiser_id'];
        }

        parsedBatches.add({
          'batch_id': bId,
          'batch_name': bMap['batch_name'] ?? 'Batch $bId',
          'date_created': bMap['date_created']?.toString() ?? 'N/A',
          'status': matchingAssign != null ? 'Active' : 'Unassigned',
          'assignment_id': matchingAssign?['assignment_id'],
          'raiser_id': raiserId,
          'raiser_name': raiserName,
        });
      }

      final List<Map<String, dynamic>> parsedRaisers = [];
      for (var r in raisersData) {
        final rMap = Map<String, dynamic>.from(r as Map);
        final realPk = rMap['hog_raiser_id'];
        if (realPk != null) {
          parsedRaisers.add({
            'id': realPk,
            'name': rMap['name'] ?? 'Hog Raiser',
            'phone': rMap['phone'] ?? 'N/A',
            'email': rMap['email'] ?? '',
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _batchesList = parsedBatches;
        _activeRaisers = parsedRaisers;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error in _loadData: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showThemedSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? Colors.red : PiggyTrunkTheme.ptSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = Responsive.isSmallScreen(context);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: _bgDark,
      drawer: isSmall
          ? Drawer(
              backgroundColor: _panelStart,
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
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: _isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary,
                          ),
                        )
                      : _showBatchForm
                          ? BatchFormView(
                              onCancel: () => setState(() {
                                _showBatchForm = false;
                                _editingBatch = null;
                              }),
                              onBatchSaved: () {
                                setState(() {
                                  _showBatchForm = false;
                                  _editingBatch = null;
                                });
                                _loadData();
                              },
                              existingBatch: _editingBatch,
                              activeRaisers: _activeRaisers,
                              onShowSnackBar: _showThemedSnackBar,
                            )
                          : SingleChildScrollView(
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
                                  child: BatchTableView(
                                    batches: _batchesList,
                                    searchQuery: _searchQuery,
                                    selectedStatusFilter: _selectedStatusFilter,
                                    onSearchChanged: (val) => setState(() => _searchQuery = val),
                                    onFilterChanged: (val) => setState(() => _selectedStatusFilter = val),
                                    onCreateBatch: () => setState(() {
                                      _showBatchForm = true;
                                      _editingBatch = null;
                                    }),
                                    onViewDetails: (batch) => BatchDetailDrawer.show(
                                      context: context,
                                      batch: batch,
                                      onEdit: () => setState(() {
                                        _showBatchForm = true;
                                        _editingBatch = batch;
                                      }),
                                      onArchive: () => _archiveBatch(batch),
                                      onDelete: () => _deleteBatch(batch),
                                    ),
                                    onEditBatch: (batch) => setState(() {
                                      _showBatchForm = true;
                                      _editingBatch = batch;
                                    }),
                                    onArchiveBatch: _archiveBatch,
                                    onDeleteBatch: _deleteBatch,
                                  ),
                                ),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _archiveBatch(Map<String, dynamic> batch) async {
    final batchName = batch['batch_name'] ?? 'Batch';
    final batchId = batch['batch_id'];

    final confirmed = await SlideOverConfirmationDrawer.show(
      context: context,
      title: 'Archive Hog Batch',
      message: 'Are you sure you want to archive "$batchName"?',
      confirmButtonText: 'Archive Batch',
      actionType: SlideOverActionType.warning,
      customIcon: Icons.archive_outlined,
    );

    if (confirmed == true) {
      try {
        await _supabase.from('batches').update({'status': 'Archived'}).eq('batch_id', batchId);
        try {
          await _supabase.from('assignments').update({'status': 'archived'}).eq('batch_id', batchId);
        } catch (_) {}
        _showThemedSnackBar('Batch "$batchName" archived successfully.');
        _loadData();
      } catch (e) {
        _showThemedSnackBar('Archive failed: $e', isError: true);
      }
    }
  }

  void _deleteBatch(Map<String, dynamic> batch) async {
    final batchName = batch['batch_name'] ?? 'Batch';
    final batchId = batch['batch_id'];

    final confirmed = await SlideOverConfirmationDrawer.show(
      context: context,
      title: 'Delete Hog Batch',
      message: 'Are you sure you want to permanently delete "$batchName"?\nThis will also remove any linked assignment records for this batch.',
      confirmButtonText: 'Delete Permanently',
      actionType: SlideOverActionType.danger,
      customIcon: Icons.delete_outline_rounded,
    );

    if (confirmed == true) {
      try {
        // Cascade delete child assignments, hogs, and requests to prevent foreign key violations
        try {
          final assignmentsRes = await _supabase.from('assignments').select('assignment_id').eq('batch_id', batchId);
          final assignmentIds = (assignmentsRes as List).map((a) => a['assignment_id']).toList();

          for (var aId in assignmentIds) {
            try {
              await _supabase.from('stock_requests').delete().eq('assignment_id', aId);
            } catch (_) {}
            try {
              await _supabase.from('hogs').delete().eq('assignment_id', aId);
            } catch (_) {}
          }
          await _supabase.from('assignments').delete().eq('batch_id', batchId);
        } catch (cascadeErr) {
          debugPrint('Cascade cleanup assignments warning: $cascadeErr');
        }

        try {
          await _supabase.from('investment_records').delete().eq('batch_id', batchId);
        } catch (_) {}

        await _supabase.from('batches').delete().eq('batch_id', batchId);
        _showThemedSnackBar('Batch "$batchName" deleted successfully.');
        _loadData();
      } catch (e) {
        _showThemedSnackBar('Delete failed: $e', isError: true);
      }
    }
  }
}
