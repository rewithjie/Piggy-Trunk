import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/investment_model.dart';
import '../theme/app_theme.dart';
import '../utils/app_toast.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';
import '../widgets/slide_over_confirmation_drawer.dart';
import '../utils/responsive.dart';
import '../widgets/investment/investment_form_view.dart';
import '../widgets/investment/investment_table_view.dart';
import '../main.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Investment> investments = [];
  List<Map<String, dynamic>> partnerInvestments = [];
  bool _isLoading = true;
  bool _showInvestmentForm = false;
  Investment? _editingInvestment;

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
    _loadInvestments();
  }

  String _cleanBatchName(String raw) {
    final clean = raw.trim();
    final uuidRegex = RegExp(r'\s*\([0-9a-fA-F-]{10,}\)\s*$');
    if (uuidRegex.hasMatch(clean)) {
      return clean.replaceAll(uuidRegex, '').trim();
    }
    return clean;
  }

  Future<void> _loadInvestments() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Batches
      List<dynamic> batchesRaw = [];
      try {
        batchesRaw = await _supabase.from('batches').select('batch_id, batch_name, date_created');
      } catch (bErr) {
        debugPrint('Error fetching batches: $bErr');
      }

      final Map<String, String> batchesMap = {
        for (var b in batchesRaw)
          (b['batch_id'] ?? b['id'] ?? '').toString(): _cleanBatchName((b['batch_name'] ?? 'Batch #${b['batch_id']}').toString())
      };

      // 2. Fetch Assignments
      List<dynamic> assignmentsRaw = [];
      try {
        assignmentsRaw = await _supabase.from('assignments').select('assignment_id, batch_id, hog_raiser_id, status, assigned_date');
      } catch (aErr) {
        debugPrint('Error fetching assignments: $aErr');
      }

      // 3. Fetch Direct Investment Records
      dynamic response;
      try {
        response = await _supabase
            .from('investment_records')
            .select('*, hog_raisers(name, app_users(name))');
      } catch (e1) {
        debugPrint('Notice joining hog_raisers on investment_records: $e1. Retrying basic...');
        try {
          response = await _supabase
              .from('investment_records')
              .select('*, hog_raisers(name)');
        } catch (e2) {
          debugPrint('Notice loading with hog_raisers: $e2. Retrying plain select...');
          response = await _supabase.from('investment_records').select('*');
        }
      }

      final List<Investment> loaded = [];
      for (var row in (response as List? ?? [])) {
        final rMap = Map<String, dynamic>.from(row as Map);
        final raiser = rMap['hog_raisers'] as Map<String, dynamic>?;
        final appUsers = raiser?['app_users'] as Map<String, dynamic>?;
        final appName = appUsers?['name']?.toString().trim();
        final raiserName = raiser?['name']?.toString().trim();

        if (appName != null && appName.isNotEmpty && appName.toLowerCase() != 'hog raiser') {
          rMap['raiser_name'] = appName;
        } else if (raiserName != null && raiserName.isNotEmpty) {
          rMap['raiser_name'] = raiserName;
        }

        final recId = (rMap['id'] ?? '').toString();
        final raiserId = (rMap['hog_raiser_id'] ?? '').toString();
        final invDate = (rMap['investment_date'] ?? '').toString();

        String? matchedBatchName;
        String? matchedBatchId;

        // A. Direct batch_name / batch_id
        if (rMap['batch_name'] != null && rMap['batch_name'].toString().isNotEmpty) {
          matchedBatchName = _cleanBatchName(rMap['batch_name'].toString());
        }
        if (rMap['batch_id'] != null && rMap['batch_id'].toString().isNotEmpty) {
          matchedBatchId = rMap['batch_id'].toString();
          matchedBatchName ??= batchesMap[matchedBatchId];
        }

        // B. Auto-generated batch matching record UUID
        if (matchedBatchName == null && recId.isNotEmpty) {
          for (var b in batchesRaw) {
            final bName = (b['batch_name'] ?? '').toString();
            if (bName.contains('($recId)')) {
              matchedBatchName = _cleanBatchName(bName);
              matchedBatchId = (b['batch_id'] ?? b['id'])?.toString();
              break;
            }
          }
        }

        // C. Match from assignments for this raiser
        if (matchedBatchName == null && raiserId.isNotEmpty) {
          Map<String, dynamic>? bestAssign;
          for (var a in assignmentsRaw) {
            if (a is! Map) continue;
            final aRaiserId = (a['hog_raiser_id'] ?? '').toString();
            if (aRaiserId == raiserId) {
              final aDate = (a['assigned_date'] ?? '').toString();
              if (invDate.isNotEmpty && aDate.startsWith(invDate.split('T').first)) {
                bestAssign = Map<String, dynamic>.from(a);
                break;
              }
              if ((a['status'] ?? '').toString().toLowerCase() == 'active') {
                bestAssign ??= Map<String, dynamic>.from(a);
              } else {
                bestAssign ??= Map<String, dynamic>.from(a);
              }
            }
          }

          if (bestAssign != null) {
            final bId = (bestAssign['batch_id'] ?? '').toString();
            matchedBatchId = bId;
            matchedBatchName = batchesMap[bId];
          }
        }

        rMap['batch_name'] = matchedBatchName ?? 'Unassigned';
        rMap['batch_id'] = matchedBatchId;
        loaded.add(Investment.fromJson(rMap));
      }

      // Fetch partner investor submissions from `investments` table with resilient lookup
      List<Map<String, dynamic>> loadedPartnerInv = [];
      try {
        final rawInvestments = await _supabase
            .from('investments')
            .select('*')
            .order('date_invested', ascending: false);

        List<dynamic> partnerInvestorsRaw = [];
        try {
          partnerInvestorsRaw = await _supabase.from('partner_investors').select('*');
        } catch (_) {}

        List<dynamic> appUsersRaw = [];
        try {
          appUsersRaw = await _supabase.from('app_users').select('user_id, name, email');
        } catch (_) {}

        final Map<String, Map<String, dynamic>> usersMap = {
          for (var u in appUsersRaw)
            (u['user_id'] ?? '').toString(): Map<String, dynamic>.from(u)
        };

        final Map<String, Map<String, dynamic>> partnersMap = {
          for (var p in partnerInvestorsRaw)
            (p['partner_investor_id'] ?? p['id'] ?? '').toString(): Map<String, dynamic>.from(p)
        };

        for (var row in (rawInvestments as List? ?? [])) {
          final pMap = Map<String, dynamic>.from(row as Map);
          final pInvId = (pMap['partner_investor_id'] ?? '').toString();
          final bId = (pMap['batch_id'] ?? '').toString();

          final partnerRec = partnersMap[pInvId];
          final userId = (partnerRec?['user_id'] ?? '').toString();
          final userRec = usersMap[userId];

          final partnerName = (userRec?['name'] ?? userRec?['email'] ?? 'Partner Investor #$pInvId').toString();
          final batchName = batchesMap[bId] ?? 'Batch #$bId';

          pMap['partner_name'] = partnerName;
          pMap['batch_name'] = batchName;
          loadedPartnerInv.add(pMap);
        }
      } catch (pErr) {
        debugPrint('Error loading partner investments: $pErr');
      }

      if (!mounted) return;
      setState(() {
        investments = loaded;
        partnerInvestments = loadedPartnerInv;
      });
    } catch (e) {
      debugPrint('Error loading investments: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approvePartnerInvestment(int investmentId) async {
    try {
      await _supabase
          .from('investments')
          .update({'status': 'active'})
          .eq('investment_id', investmentId);
      _showThemedSnackBar('Partner Investment approved and activated!');
      _loadInvestments();
    } catch (e) {
      _showThemedSnackBar('Approval failed: $e', isError: true);
    }
  }

  Future<void> _rejectPartnerInvestment(int investmentId) async {
    try {
      await _supabase
          .from('investments')
          .update({'status': 'rejected'})
          .eq('investment_id', investmentId);
      _showThemedSnackBar('Partner Investment declined.');
      _loadInvestments();
    } catch (e) {
      _showThemedSnackBar('Decline failed: $e', isError: true);
    }
  }

  void _showThemedSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      AppToast.error(context, message);
    } else {
      AppToast.success(context, message);
    }
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
                currentRoute: '/investments',
                onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
                isDrawer: true,
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isSmall)
            AdminSidebar(
              currentRoute: '/investments',
              onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
            ),
          Expanded(
            child: Column(
              children: [
                const ScreenTopBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _showInvestmentForm
                          ? InvestmentFormView(
                              onCancel: () => setState(() {
                                _showInvestmentForm = false;
                                _editingInvestment = null;
                              }),
                              onSaved: () {
                                setState(() {
                                  _showInvestmentForm = false;
                                  _editingInvestment = null;
                                });
                                _loadInvestments();
                              },
                              existingInvestment: _editingInvestment,
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
                                  child: InvestmentTableView(
                                    investments: investments,
                                    partnerInvestments: partnerInvestments,
                                    onAddInvestment: () => setState(() {
                                      _showInvestmentForm = true;
                                      _editingInvestment = null;
                                    }),
                                    onEditInvestment: (item) => setState(() {
                                      _showInvestmentForm = true;
                                      _editingInvestment = item;
                                    }),
                                    onArchiveInvestment: _archiveInvestment,
                                    onDeleteInvestment: _deleteInvestment,
                                    onApprovePartnerInvestment: _approvePartnerInvestment,
                                    onRejectPartnerInvestment: _rejectPartnerInvestment,
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

  void _archiveInvestment(Investment item) async {
    final confirmed = await SlideOverConfirmationDrawer.show(
      context: context,
      title: 'Archive Investment',
      message: 'Are you sure you want to archive the investment record for "${item.raiserName}"?',
      confirmButtonText: 'Archive',
      actionType: SlideOverActionType.warning,
      customIcon: Icons.archive_outlined,
    );

    if (confirmed == true) {
      try {
        await _supabase.from('investment_records').update({'stage': 'archived'}).eq('id', item.id);
        _showThemedSnackBar('Investment archived successfully.');
        _loadInvestments();
      } catch (e) {
        _showThemedSnackBar('Archive failed: $e', isError: true);
      }
    }
  }

  void _deleteInvestment(Investment item) async {
    final confirmed = await SlideOverConfirmationDrawer.show(
      context: context,
      title: 'Delete Investment',
      message: 'Are you sure you want to permanently delete this investment record for "${item.raiserName}"?',
      confirmButtonText: 'Delete Permanently',
      actionType: SlideOverActionType.danger,
      customIcon: Icons.delete_outline_rounded,
    );

    if (confirmed == true) {
      try {
        await _supabase.from('investment_records').delete().eq('id', item.id);
        _showThemedSnackBar('Investment deleted.');
        _loadInvestments();
      } catch (e) {
        _showThemedSnackBar('Delete failed: $e', isError: true);
      }
    }
  }
}
