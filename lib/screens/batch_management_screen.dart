import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String? _loadError;

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
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      // 1. Fetch batches
      List<dynamic> batchesData = [];
      try {
        batchesData = await _supabase.from('batches').select('*');
      } catch (e) {
        debugPrint('Error fetching batches with select(*): $e');
        try {
          batchesData = await _supabase.from('batches').select();
        } catch (e2) {
          debugPrint('Error fetching batches fallback: $e2');
          _loadError = 'Batches query error: $e2';
        }
      }

      // 2. Fetch assignments directly
      List<dynamic> assignmentsData = [];
      try {
        assignmentsData = await _supabase.from('assignments').select('*');
      } catch (e) {
        debugPrint('Error fetching assignments: $e');
      }

      // 3. Fetch active authorized raisers
      List<dynamic> raisersData = [];
      try {
        raisersData = await _supabase.from('hog_raisers').select('*');
      } catch (e) {
        debugPrint('Error fetching raisers: $e');
      }

      final Map<String, String> raiserMap = {};
      final List<Map<String, dynamic>> parsedRaisers = [];
      for (var r in raisersData) {
        if (r is! Map) continue;
        final rMap = Map<String, dynamic>.from(r);
        final realPk = rMap['hog_raiser_id'] ?? rMap['id'];
        if (realPk != null) {
          final pkStr = realPk.toString();
          
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

          raiserMap[pkStr] = resolvedName;
          parsedRaisers.add({
            'id': realPk,
            'name': resolvedName,
            'phone': rMap['phone'] ?? 'N/A',
            'email': appUsers?['email'] ?? '',
          });
        }
      }

      final List<Map<String, dynamic>> parsedBatches = [];

      for (var b in batchesData) {
        if (b is! Map) continue;
        final bMap = Map<String, dynamic>.from(b);
        final bId = bMap['batch_id'] ?? bMap['id'] ?? bMap['batch_number'] ?? bMap['batch_code'];
        if (bId == null) continue;

        final rawStatus = (bMap['status'] ?? bMap['batch_status'] ?? '').toString().toLowerCase();
        if (rawStatus == 'archived' || rawStatus == 'deleted') continue;

        // Find assignment for this batch safely
        Map<String, dynamic>? matchingAssign;
        for (var a in assignmentsData) {
          if (a is Map && (a['batch_id']?.toString() == bId.toString() || a['id']?.toString() == bId.toString())) {
            if ((a['status'] ?? '').toString().toLowerCase() == 'active') {
              matchingAssign = Map<String, dynamic>.from(a);
              break;
            }
            matchingAssign ??= Map<String, dynamic>.from(a);
          }
        }

        String raiserName = 'Unassigned';
        dynamic raiserId;
        String batchStatus = 'Unassigned';

        if (matchingAssign != null) {
          final rawRaiserId = matchingAssign['hog_raiser_id'];
          if (rawRaiserId != null) {
            raiserId = rawRaiserId;
            raiserName = raiserMap[rawRaiserId.toString()] ?? 'Hog Raiser';
            batchStatus = 'Active';
          }
        }

        parsedBatches.add({
          'batch_id': bId,
          'batch_name': bMap['batch_name'] ?? bMap['name'] ?? 'Batch $bId',
          'date_created': (bMap['date_created'] ?? bMap['created_at'])?.toString() ?? 'N/A',
          'status': batchStatus,
          'assignment_id': matchingAssign?['assignment_id'],
          'raiser_id': raiserId,
          'raiser_name': raiserName,
        });
      }

      parsedBatches.sort((a, b) {
        final aId = int.tryParse(a['batch_id']?.toString() ?? '0') ?? 0;
        final bId = int.tryParse(b['batch_id']?.toString() ?? '0') ?? 0;
        return bId.compareTo(aId);
      });

      debugPrint('Loaded ${parsedBatches.length} batches and ${parsedRaisers.length} raisers');

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
          _loadError = 'Load error: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _showThemedSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        duration: Duration(seconds: isError ? 5 : 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                    errorMessage: _loadError,
                                    onRefresh: _loadData,
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
    final batchId = batch['batch_id'] ?? batch['id'];
    if (batchId == null) return;

    final confirmed = await SlideOverConfirmationDrawer.show(
      context: context,
      title: 'Archive Hog Batch',
      message: 'Are you sure you want to archive "$batchName"?',
      confirmButtonText: 'Archive Batch',
      actionType: SlideOverActionType.warning,
      customIcon: Icons.archive_outlined,
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        try {
          await _supabase.from('batches').update({'status': 'Archived'}).eq('batch_id', batchId);
        } catch (_) {
          await _supabase.from('batches').update({'status': 'Archived'}).eq('id', batchId);
        }

        try {
          await _supabase.from('assignments').update({'status': 'archived'}).eq('batch_id', batchId);
        } catch (_) {}

        try {
          await _supabase.from('investment_records').update({'stage': 'archived'}).eq('batch_id', batchId);
        } catch (_) {}

        _showThemedSnackBar('Batch "$batchName" archived successfully.');
        await _loadData();
      } catch (e) {
        _showThemedSnackBar('Archive failed: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _deleteBatch(Map<String, dynamic> batch) async {
    final batchName = batch['batch_name'] ?? 'Batch';
    final batchId = batch['batch_id'] ?? batch['id'];
    if (batchId == null) return;

    final confirmed = await SlideOverConfirmationDrawer.show(
      context: context,
      title: 'Delete Hog Batch',
      message: 'Are you sure you want to permanently delete "$batchName"?\nThis will also remove any linked assignment records for this batch.',
      confirmButtonText: 'Delete Permanently',
      actionType: SlideOverActionType.danger,
      customIcon: Icons.delete_outline_rounded,
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        // 1. Cascade delete child assignments, hogs, and requests to prevent foreign key violations
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

        // 2. Cascade delete investment records
        try {
          await _supabase.from('investment_records').delete().eq('batch_id', batchId);
        } catch (_) {}
        try {
          await _supabase.from('investments').delete().eq('batch_id', batchId);
        } catch (_) {}

        // 3. Delete from batches
        try {
          await _supabase.from('batches').delete().eq('batch_id', batchId);
        } catch (_) {
          await _supabase.from('batches').delete().eq('id', batchId);
        }

        _showThemedSnackBar('Batch "$batchName" deleted successfully from database.');
        await _loadData();
      } catch (e) {
        _showThemedSnackBar('Delete failed: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
