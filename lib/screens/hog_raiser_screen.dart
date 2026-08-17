import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../main.dart';
import '../theme/app_text_styles.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';
import '../widgets/slide_over_confirmation_drawer.dart';
import '../utils/responsive.dart';

class HogRaiserScreen extends StatefulWidget {
  const HogRaiserScreen({super.key});

  @override
  State<HogRaiserScreen> createState() => _HogRaiserScreenState();
}

class _HogRaiserScreenState extends State<HogRaiserScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _raisers = [];
  bool _isLoading = true;
  int _currentTab = 0; // 0 = Active, 1 = Pending
  String? _loadErrorMessage;
  final Map<int, String?> _selectedPigTypes = {};

  RealtimeChannel? _raisersSubscription;
  bool _hasCheckedRouteArgs = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgDark => _isDark ? PiggyTrunkTheme.ptBgDark : PiggyTrunkTheme.ptBg;
  Color get _accentDark => _isDark ? PiggyTrunkTheme.ptAccentDark : PiggyTrunkTheme.ptAccent;
  Color get _panelStart => _isDark ? const Color(0xFF1A2940) : Colors.white;
  Color get _panelEnd => _isDark ? const Color(0xFF0F1C2F) : Colors.white;
  Color get _panelBorder => _isDark ? const Color(0xFF2A3E5B) : const Color(0xFFE3EAF3);
  Color get _cardBg => _isDark ? const Color(0xFF132238) : Colors.white;
  Color get _cardBorder => _isDark ? const Color(0xFF27405F) : const Color(0xFFC6D8EF);
  Color get _titleColor => _isDark ? Colors.white : const Color(0xFF18314F);
  Color get _fieldBg => _isDark ? const Color(0xFF1A2B44) : const Color(0xFFEEF4FD);
  Color get _fieldBorder => _isDark ? const Color(0xFF28405D) : const Color(0xFFB4C9E6);
  Color get _fieldFocus => _isDark ? const Color(0xFF88A7CE) : const Color(0xFF315C8F);
  Color get _fieldText => _isDark ? const Color(0xFFE6F1FF) : const Color(0xFF18314F);
  Color get _hintText => _isDark ? const Color(0xFF8FA7C4) : const Color(0xFF5D7391);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCheckedRouteArgs) {
      _hasCheckedRouteArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == 'pending' || args == 'pending_raiser') {
        setState(() => _currentTab = 1);
      }
    }
  }

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
    _loadRaisers();
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    _raisersSubscription = _supabase
        .channel('public:hog_raisers')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'hog_raisers',
          callback: (payload) {
            _loadRaisers(silent: true);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    if (_raisersSubscription != null) {
      _supabase.removeChannel(_raisersSubscription!);
    }
    super.dispose();
  }

  Future<void> _loadRaisers({String? keyword, bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _loadErrorMessage = null;
      });
    }

    try {
      try {
        final pendingAppUsers = await _supabase
            .from('app_users')
            .select('user_id, name, email, status, role')
            .or('role.ilike.%raiser%,role.ilike.%hog_raiser%');

        for (final au in (pendingAppUsers as List)) {
          final uid = au['user_id'];
          final uStatus = (au['status'] ?? 'Pending').toString();
          if (uid != null) {
            final exists = await _supabase
                .from('hog_raisers')
                .select('hog_raiser_id')
                .eq('user_id', uid)
                .maybeSingle();

            if (exists == null) {
              await _supabase.from('hog_raisers').insert({
                'user_id': uid,
                'name': au['name'] ?? au['email']?.toString().split('@').first ?? 'Hog Raiser',
                'phone': 'N/A',
                'address': 'N/A',
                'status': 'Inactive',
                'account_status': uStatus,
                'pig_type': 'N/A',
                'lifecycle_stage': 'N/A',
              });
            }
          }
        }
      } catch (syncErr) {
        debugPrint('Notice during raiser sync: $syncErr');
      }

      dynamic query = _supabase
          .from('hog_raisers')
          .select('hog_raiser_id, name, address, phone, pig_type, status, account_status, lifecycle_stage, user_id, app_users!hog_raisers_user_id_fkey(name, email, supabase_user_id)');
      if (keyword != null && keyword.trim().isNotEmpty) {
        query = query.or('name.ilike.%$keyword%,address.ilike.%$keyword%,phone.ilike.%$keyword%');
      }
      final response = await query.order('name', ascending: true);

      if (!mounted) return;
      setState(() {
        _raisers = (response as List).cast<Map<String, dynamic>>().map((r) {
          final appUsers = r['app_users'] as Map<String, dynamic>?;
          final googleOrAppName = (appUsers?['name'] ?? '').toString().trim();
          final raiserName = (r['name'] ?? '').toString().trim();
          final resolvedFullName = googleOrAppName.isNotEmpty && googleOrAppName.toLowerCase() != 'hog raiser'
              ? googleOrAppName
              : (raiserName.isNotEmpty ? raiserName : 'Hog Raiser');

          return {
            ...r,
            'name': resolvedFullName,
            'email': appUsers?['email'] ?? '',
            'supabase_user_id': appUsers?['supabase_user_id'],
          };
        }).where((r) => r['supabase_user_id'] != null).toList();

        // Populate initial pig types state
        for (final r in _raisers) {
          final id = _parseId(r['id'] ?? r['hog_raiser_id']);
          if (id != null) {
            final isPending = (r['account_status'] ?? '').toString().toLowerCase() == 'pending';
            // Only initialize if not already tracked or if it's a fresh load
            if (!_selectedPigTypes.containsKey(id)) {
              _selectedPigTypes[id] = isPending ? null : r['pig_type']?.toString();
            }
          }
        }
        
        _loadErrorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadErrorMessage = 'Load failed: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int? _parseId(dynamic rawId) {
    if (rawId == null) return null;
    if (rawId is int) return rawId;
    return int.tryParse(rawId.toString());
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = Responsive.isSmallScreen(context);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: _bgDark,
      drawer: isSmall
          ? Drawer(
              backgroundColor: _cardBg,
              child: AdminSidebar(
                currentRoute: '/raisers',
                onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
                isDrawer: true,
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isSmall)
            AdminSidebar(
              currentRoute: '/raisers',
              onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
            ),
          Expanded(
            child: Column(
              children: [
                const ScreenTopBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(isMobile ? 12 : 18),
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 1340),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [_panelStart, _panelEnd]),
                                border: Border.all(color: _panelBorder, width: 1),
                                borderRadius: BorderRadius.circular(isMobile ? 16 : 30),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 14 : 26,
                                vertical: isMobile ? 16 : 26,
                              ),
                              child: _buildListView(),
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

  Widget _buildListView() {
    final isMobile = Responsive.isMobile(context);
    final activeCount = _raisers.where((r) => (r['account_status'] ?? '').toString().toLowerCase() == 'active').length;
    final pendingCount = _raisers.where((r) => (r['account_status'] ?? '').toString().toLowerCase() == 'pending').length;

    final filteredRaisers = _raisers.where((r) {
      final status = (r['account_status'] ?? '').toString().toLowerCase();
      final tabStatus = _currentTab == 0 ? 'active' : 'pending';
      return status == tabStatus;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hog Raiser Management',
          style: AppTextStyles.pageTitle(_titleColor),
        ),
        if (_loadErrorMessage != null) ...[
          const SizedBox(height: 10),
          _buildErrorBanner(_loadErrorMessage!),
        ],
        const SizedBox(height: 20),
        isMobile
            ? Row(
                children: [
                  Expanded(child: _buildTabButton(0, 'Active Raisers', activeCount, isMobile: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTabButton(1, 'Pending Approvals', pendingCount, isMobile: true)),
                ],
              )
            : Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  _buildTabButton(0, 'Active Raisers', activeCount),
                  _buildTabButton(1, 'Pending Approvals', pendingCount),
                ],
              ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
            border: Border.all(color: _cardBorder),
          ),
          padding: EdgeInsets.all(isMobile ? 14 : 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: AppTextStyles.body(_fieldText),
                      decoration: InputDecoration(
                        hintText: 'Search raisers...',
                        hintStyle: AppTextStyles.body(_hintText),
                        prefixIcon: Icon(Icons.search, color: _hintText),
                        filled: true,
                        fillColor: _fieldBg,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _fieldBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _fieldFocus),
                        ),
                      ),
                      onSubmitted: (value) => _loadRaisers(keyword: value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _loadRaisers(keyword: _searchCtrl.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDark ? PiggyTrunkTheme.ptSurface : PiggyTrunkTheme.ptPrimary,
                      foregroundColor: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                      minimumSize: Size(isMobile ? 76 : 90, isMobile ? 44 : 48),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Search',
                      style: AppTextStyles.button(_isDark ? PiggyTrunkTheme.ptPrimary : Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final tableWidth = constraints.maxWidth > 800 ? constraints.maxWidth : 800.0;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _tableHeader(),
                          const SizedBox(height: 4),
                          if (filteredRaisers.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 50),
                              child: Center(
                                child: Text(
                                  _currentTab == 0 ? 'No active raisers found' : 'No pending approvals',
                                  style: AppTextStyles.jakarta(size: 20, weight: FontWeight.w700, color: _titleColor),
                                ),
                              ),
                            )
                          else
                            ...filteredRaisers.map(_tableRow),
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
    );
  }

  Widget _buildTabButton(int index, String label, int count, {bool isMobile = false}) {
    final isSelected = _currentTab == index;
    final textStyle = AppTextStyles.jakarta(
      size: isMobile ? 12 : 14,
      weight: isSelected ? FontWeight.w800 : FontWeight.w600,
      color: isSelected 
          ? (_isDark ? PiggyTrunkTheme.ptPrimary : Colors.white) 
          : _hintText,
    );
    return ElevatedButton(
      onPressed: () => setState(() => _currentTab = index),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected 
            ? (_isDark ? Colors.white : PiggyTrunkTheme.ptPrimary) 
            : (_isDark ? const Color(0xFF1E2F47) : const Color(0xFFEEF4FD)),
        foregroundColor: isSelected 
            ? (_isDark ? PiggyTrunkTheme.ptPrimary : Colors.white) 
            : _titleColor,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 16, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: Size(isMobile ? 0 : 180, isMobile ? 44 : 48),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text('$label ($count)', style: textStyle),
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF1B2E48) : const Color(0xFFEDF4FC),
        border: Border(bottom: BorderSide(color: _cardBorder, width: 1.2)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('NAME', style: AppTextStyles.tableHeader(_hintText)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('ADDRESS', style: AppTextStyles.tableHeader(_hintText)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('PHONE NUMBER', style: AppTextStyles.tableHeader(_hintText)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('STATUS', style: AppTextStyles.tableHeader(_hintText)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text('ACTIONS', style: AppTextStyles.tableHeader(_hintText)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableRow(Map<String, dynamic> row) {
    final isPending = (row['account_status'] ?? '').toString().toLowerCase() == 'pending';
    final statusText = (row['account_status'] ?? '').toString().toUpperCase();
    final statusColor = statusText == 'ACTIVE' || statusText == 'APPROVED'
        ? PiggyTrunkTheme.ptSuccess
        : (statusText == 'PENDING' ? const Color(0xFFFFAA00) : Colors.redAccent);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _cardBorder.withValues(alpha: 0.5))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                (row['name'] ?? '').toString(),
                style: AppTextStyles.body(_titleColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                (row['address'] ?? '').toString(),
                style: AppTextStyles.body(_titleColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                (row['phone'] ?? '').toString(),
                style: AppTextStyles.body(_titleColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: AppTextStyles.jakarta(
                      color: statusColor,
                      size: 11,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: isPending
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _showRaiserDetails(row),
                          icon: const Icon(Icons.visibility_outlined, size: 20, color: Colors.blueAccent),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'View Details',
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: () => _approveRaiserDirectly(row),
                          icon: const Icon(Icons.check_circle_outline, size: 22, color: Colors.green),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Approve Raiser',
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _deleteRaiser(row),
                          icon: const Icon(Icons.cancel_outlined, size: 22, color: Colors.redAccent),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Reject Registration',
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _showRaiserDetails(row),
                          icon: const Icon(Icons.visibility_outlined, size: 20, color: Colors.blueAccent),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'View Details',
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: () => _showEditRaiserDialog(row),
                          icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.amber),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Edit Raiser',
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: () => _archiveRaiser(row),
                          icon: const Icon(Icons.archive_outlined, size: 20, color: Colors.orangeAccent),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Archive Raiser',
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _accentDark.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentDark.withValues(alpha: 0.55)),
      ),
      child: Text(
        message,
        style: AppTextStyles.jakarta(
          size: 13,
          weight: FontWeight.w600,
          color: _titleColor,
        ),
      ),
    );
  }


  Future<void> _approveRaiserDirectly(Map<String, dynamic> row) async {
    final id = _parseId(row['id'] ?? row['hog_raiser_id']);
    final userId = _parseId(row['user_id']);
    if (id == null) return;

    final name = (row['name'] ?? '').toString();
    final email = (row['email'] ?? '').toString();

    final confirm = await SlideOverConfirmationDrawer.show(
      context: context,
      title: 'Approve Hog Raiser',
      message: 'Are you sure you want to approve and activate the hog raiser account for "$name"?',
      actionType: SlideOverActionType.success,
      userName: name,
      userEmail: email.isNotEmpty ? email : null,
      userRole: 'Hog Raiser',
      confirmButtonText: 'Yes, Approve',
      cancelButtonText: 'Cancel',
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final pkCol = row['id'] != null ? 'id' : 'hog_raiser_id';
      final List<Future> updates = [
        _supabase.from('hog_raisers').update({
          'status': 'Active',
          'account_status': 'active',
        }).eq(pkCol, id),
      ];

      if (userId != null) {
        updates.add(
          _supabase.from('app_users').update({
            'status': 'active',
          }).eq('user_id', userId),
        );
      }

      await Future.wait(updates);
      await _loadRaisers(keyword: _searchCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Raiser "$name" approved successfully.', style: AppTextStyles.body(Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approval failed: $e', style: AppTextStyles.body(Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRaiser(Map<String, dynamic> row) async {
    final id = _parseId(row['id'] ?? row['hog_raiser_id']);
    final userId = _parseId(row['user_id']);
    if (id == null) return;
    final name = (row['name'] ?? '').toString();
    final email = (row['email'] ?? '').toString();

    final confirm = await SlideOverConfirmationDrawer.show(
      context: context,
      title: 'Reject Hog Raiser',
      message: 'Are you sure you want to reject the registration for "$name"? This will permanently delete their registration record.',
      actionType: SlideOverActionType.danger,
      userName: name,
      userEmail: email.isNotEmpty ? email : null,
      userRole: 'Hog Raiser',
      confirmButtonText: 'Yes, Reject',
      cancelButtonText: 'Cancel',
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      if (userId != null) {
        await _supabase.from('app_users').delete().eq('user_id', userId);
      } else {
        final pkCol = row['id'] != null ? 'id' : 'hog_raiser_id';
        await _supabase.from('hog_raisers').delete().eq(pkCol, id);
      }
      await _loadRaisers(keyword: _searchCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Raiser registration rejected successfully.', style: AppTextStyles.body(Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rejection failed: $e', style: AppTextStyles.body(Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _archiveRaiser(Map<String, dynamic> row) async {
    final id = _parseId(row['id'] ?? row['hog_raiser_id']);
    final userId = _parseId(row['user_id']);
    if (id == null) return;
    final name = (row['name'] ?? '').toString();
    final email = (row['email'] ?? '').toString();

    final confirm = await SlideOverConfirmationDrawer.show(
      context: context,
      title: 'Archive Hog Raiser',
      message: 'Are you sure you want to archive the record for "$name"?',
      actionType: SlideOverActionType.warning,
      userName: name,
      userEmail: email.isNotEmpty ? email : null,
      userRole: 'Hog Raiser',
      confirmButtonText: 'Yes, Archive',
      cancelButtonText: 'Cancel',
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final pkCol = row['id'] != null ? 'id' : 'hog_raiser_id';
      final List<Future> updates = [
        _supabase.from('hog_raisers').update({
          'status': 'Archived',
        }).eq(pkCol, id),
      ];

      if (userId != null) {
        updates.add(
          _supabase.from('app_users').update({
            'status': 'archived',
          }).eq('user_id', userId),
        );
      }

      await Future.wait(updates);
      await _loadRaisers(keyword: _searchCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Raiser "$name" archived successfully.', style: AppTextStyles.body(Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Archive failed: $e', style: AppTextStyles.body(Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRaiserDetails(Map<String, dynamic> row) {
    final isMobile = MediaQuery.of(context).size.width < 720;
    if (isMobile) {
      _showRaiserBottomSheet(row);
    } else {
      _showRaiserSideDrawer(row);
    }
  }

  String? _getAvatarUrl(Map<String, dynamic> row) {
    final appUsers = row['app_users'] as Map<String, dynamic>?;
    final metadata = row['raw_user_meta_data'] as Map<String, dynamic>?;
    final dynamic candidate = row['profile_picture'] ??
        row['avatar_url'] ??
        row['photo_url'] ??
        row['image_url'] ??
        row['profile_image'] ??
        row['picture'] ??
        appUsers?['profile_picture'] ??
        appUsers?['avatar_url'] ??
        appUsers?['photo_url'] ??
        appUsers?['image_url'] ??
        appUsers?['profile_image'] ??
        appUsers?['picture'] ??
        metadata?['avatar_url'] ??
        metadata?['picture'] ??
        metadata?['profile_picture'];

    if (candidate != null) {
      final str = candidate.toString().trim();
      if (str.startsWith('http://') || str.startsWith('https://')) {
        return str;
      }
    }
    return null;
  }

  Widget _buildAvatarWidget({
    required String initials,
    String? avatarUrl,
    double size = 68,
    double fontSize = 20,
  }) {
    final hasUrl = avatarUrl != null && avatarUrl.isNotEmpty;
    final isDark = _isDark;
    final bgColor = isDark ? Colors.white : PiggyTrunkTheme.ptPrimary;
    final borderColor = isDark ? Colors.white : PiggyTrunkTheme.ptPrimary;
    final textColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : PiggyTrunkTheme.ptPrimary).withValues(alpha: isDark ? 0.25 : 0.15),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: hasUrl
          ? Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  initials,
                  style: AppTextStyles.jakarta(
                    size: fontSize,
                    weight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: SizedBox(
                    width: size * 0.35,
                    height: size * 0.35,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  ),
                );
              },
            )
          : Center(
              child: Text(
                initials,
                style: AppTextStyles.jakarta(
                  size: fontSize,
                  weight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
    );
  }

  void _showRaiserBottomSheet(Map<String, dynamic> row) {
    final name = (row['name'] ?? 'Hog Raiser').toString();
    final email = (row['email'] ?? 'N/A').toString();
    final phone = (row['phone'] ?? 'N/A').toString();
    final address = (row['address'] ?? 'N/A').toString();
    final pigType = (row['pig_type'] ?? 'N/A').toString();
    final status = (row['account_status'] ?? row['status'] ?? 'Active').toString().toUpperCase();
    final isPending = status == 'PENDING';
    final avatarUrl = _getAvatarUrl(row);

    final statusColor = status == 'ACTIVE' || status == 'APPROVED'
        ? PiggyTrunkTheme.ptSuccess
        : (status == 'PENDING' ? const Color(0xFFFFAA00) : Colors.redAccent);

    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join('').toUpperCase()
        : 'HR';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                      'Raiser Profile',
                      style: AppTextStyles.jakarta(
                        size: 17,
                        weight: FontWeight.w800,
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
                  child: Column(
                    children: [
                      _buildAvatarWidget(initials: initials, avatarUrl: avatarUrl, size: 64, fontSize: 20),
                      const SizedBox(height: 10),
                      Text(
                        name,
                        style: AppTextStyles.jakarta(size: 17, weight: FontWeight.w800, color: _titleColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: AppTextStyles.jakarta(size: 13, weight: FontWeight.w500, color: _hintText),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: AppTextStyles.jakarta(
                            color: statusColor,
                            size: 11,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: _isDark ? const Color(0xFF1B2E48) : const Color(0xFFF6F9FD),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _cardBorder.withValues(alpha: 0.5)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Column(
                          children: [
                            _drawerDetailRow('Name', name),
                            _drawerDivider(),
                            _drawerDetailRow('Email', email),
                            _drawerDivider(),
                            _drawerDetailRow('Phone', phone),
                            _drawerDivider(),
                            _drawerDetailRow('Address', address),
                            _drawerDivider(),
                            _drawerDetailRow('Pig Type', pigType),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(color: _cardBorder.withValues(alpha: 0.5), height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (isPending) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _deleteRaiser(row);
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
                            side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'Reject',
                            style: AppTextStyles.jakarta(
                              size: 13,
                              weight: FontWeight.w800,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _approveRaiserDirectly(row);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Approve',
                            style: AppTextStyles.jakarta(
                              size: 13,
                              weight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ] else
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PiggyTrunkTheme.ptPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Close',
                            style: AppTextStyles.jakarta(
                              size: 13,
                              weight: FontWeight.w800,
                              color: Colors.white,
                            ),
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
    );
  }

  void _showRaiserSideDrawer(Map<String, dynamic> row) {
    final name = (row['name'] ?? 'Hog Raiser').toString();
    final email = (row['email'] ?? 'N/A').toString();
    final phone = (row['phone'] ?? 'N/A').toString();
    final address = (row['address'] ?? 'N/A').toString();
    final pigType = (row['pig_type'] ?? 'N/A').toString();
    final status = (row['account_status'] ?? row['status'] ?? 'Active').toString().toUpperCase();
    final isPending = status == 'PENDING';
    final avatarUrl = _getAvatarUrl(row);

    final statusColor = status == 'ACTIVE' || status == 'APPROVED'
        ? PiggyTrunkTheme.ptSuccess
        : (status == 'PENDING' ? const Color(0xFFFFAA00) : Colors.redAccent);

    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join('').toUpperCase()
        : 'HR';

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Raiser Details',
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
                width: 420,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: _cardBg,
                  border: Border(left: BorderSide(color: _cardBorder, width: 1.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(-4, 0),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Text(
                              'Raiser Profile',
                              style: AppTextStyles.jakarta(
                                size: 17,
                                weight: FontWeight.w800,
                                color: _titleColor,
                              ),
                            ),
                            const Spacer(),
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
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Column(
                                  children: [
                                    _buildAvatarWidget(initials: initials, avatarUrl: avatarUrl, size: 68, fontSize: 22),
                                    const SizedBox(height: 12),
                                    Text(
                                      name,
                                      style: AppTextStyles.jakarta(
                                        size: 18,
                                        weight: FontWeight.w800,
                                        color: _titleColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      email,
                                      style: AppTextStyles.jakarta(
                                        size: 13,
                                        weight: FontWeight.w500,
                                        color: _hintText,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        status,
                                        style: AppTextStyles.jakarta(
                                          color: statusColor,
                                          size: 11,
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),
                              Text(
                                'PROFILE DETAILS',
                                style: AppTextStyles.jakarta(
                                  size: 11,
                                  weight: FontWeight.w800,
                                  color: _hintText,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: _isDark ? const Color(0xFF1B2E48) : const Color(0xFFF6F9FD),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _cardBorder.withValues(alpha: 0.5)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Column(
                                  children: [
                                    _drawerDetailRow('Name', name),
                                    _drawerDivider(),
                                    _drawerDetailRow('Email', email),
                                    _drawerDivider(),
                                    _drawerDetailRow('Phone', phone),
                                    _drawerDivider(),
                                    _drawerDetailRow('Address', address),
                                    _drawerDivider(),
                                    _drawerDetailRow('Pig Type', pigType),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(color: _cardBorder.withValues(alpha: 0.5), height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            if (isPending) ...[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                    _deleteRaiser(row);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
                                    side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text(
                                    'Reject',
                                    style: AppTextStyles.jakarta(
                                      size: 13,
                                      weight: FontWeight.w800,
                                      color: const Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                    _approveRaiserDirectly(row);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF16A34A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Approve',
                                    style: AppTextStyles.jakarta(
                                      size: 13,
                                      weight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ] else
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: PiggyTrunkTheme.ptPrimary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Close',
                                    style: AppTextStyles.jakarta(
                                      size: 13,
                                      weight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
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
          ),
        );
      },
    );
  }

  Widget _drawerDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.jakarta(size: 13, weight: FontWeight.w600, color: _hintText),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.jakarta(size: 13, weight: FontWeight.w700, color: _titleColor),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerDivider() {
    return Divider(color: _cardBorder.withValues(alpha: 0.35), height: 1);
  }

  void _showEditRaiserDialog(Map<String, dynamic> row) {
    final id = _parseId(row['id'] ?? row['hog_raiser_id']);
    final userId = _parseId(row['user_id']);
    if (id == null) return;

    final initialName = (row['name'] ?? '').toString();
    final initialPhone = (row['phone'] ?? '').toString();
    final initialAddress = (row['address'] ?? '').toString();
    final status = (row['status'] ?? 'Active').toString().toUpperCase();

    final nameCtrl = TextEditingController(text: initialName == 'N/A' ? '' : initialName);
    final phoneCtrl = TextEditingController(text: initialPhone == 'N/A' ? '' : initialPhone);
    final addressCtrl = TextEditingController(text: initialAddress == 'N/A' ? '' : initialAddress);

    final initials = initialName.trim().isNotEmpty && initialName != 'N/A'
        ? initialName.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join('').toUpperCase()
        : 'HR';

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Edit Hog Raiser',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, anim1, anim2) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final surfaceColor = isDark ? const Color(0xFF0F172A) : Colors.white;
        final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
        final titleTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final mutedTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final fieldBgColor = isDark ? const Color(0xFF131F33) : const Color(0xFFF8FAFC);
        final fieldBorderColor = isDark ? const Color(0xFF223552) : const Color(0xFFCBD5E1);

        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final drawerWidth = isMobile ? screenWidth : 420.0;

        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: drawerWidth,
              height: double.infinity,
              decoration: BoxDecoration(
                color: surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
                    blurRadius: 32,
                    spreadRadius: 2,
                    offset: const Offset(-6, 0),
                  ),
                ],
                border: Border(
                  left: BorderSide(color: borderColor, width: 1.2),
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================== DRAWER HEADER ====================
                    Container(
                      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 20, 18, isMobile ? 12 : 16, 16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF112240) : const Color(0xFFDBEAFE),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBFDBFE),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit_note_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Edit Hog Raiser Details',
                                style: AppTextStyles.jakarta(
                                  size: 17,
                                  weight: FontWeight.w800,
                                  color: titleTextColor,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: mutedTextColor, size: 20),
                            tooltip: 'Close',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ],
                      ),
                    ),

                    // ==================== FORM BODY ====================
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Raiser Profile Header Card
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF131F33) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isDark ? const Color(0xFF223552) : const Color(0xFFE2E8F0), width: 1),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E3352) : const Color(0xFFEFF6FF),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.6) : const Color(0xFF93C5FD),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        initials,
                                        style: AppTextStyles.jakarta(
                                          size: 15,
                                          weight: FontWeight.w800,
                                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          initialName.isEmpty ? 'Hog Raiser' : initialName,
                                          style: AppTextStyles.jakarta(
                                            size: 14.5,
                                            weight: FontWeight.w700,
                                            color: titleTextColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: status == 'ACTIVE'
                                                ? PiggyTrunkTheme.ptSuccess.withValues(alpha: 0.15)
                                                : Colors.orangeAccent.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: status == 'ACTIVE' ? PiggyTrunkTheme.ptSuccess : Colors.orangeAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Full Name Field
                            Text(
                              'Full Name',
                              style: AppTextStyles.jakarta(
                                size: 12.5,
                                weight: FontWeight.w700,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: nameCtrl,
                              style: AppTextStyles.body(titleTextColor),
                              decoration: InputDecoration(
                                hintText: 'Enter raiser full name',
                                hintStyle: AppTextStyles.body(mutedTextColor),
                                prefixIcon: Icon(Icons.person_outline_rounded, size: 18, color: mutedTextColor),
                                filled: true,
                                fillColor: fieldBgColor,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: fieldBorderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Phone Number Field
                            Text(
                              'Phone Number',
                              style: AppTextStyles.jakarta(
                                size: 12.5,
                                weight: FontWeight.w700,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: phoneCtrl,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(11),
                              ],
                              style: AppTextStyles.body(titleTextColor),
                              decoration: InputDecoration(
                                hintText: 'Enter phone number (e.g. 09123456789)',
                                hintStyle: AppTextStyles.body(mutedTextColor),
                                prefixIcon: Icon(Icons.phone_outlined, size: 18, color: mutedTextColor),
                                filled: true,
                                fillColor: fieldBgColor,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: fieldBorderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Address / Farm Location Field
                            Text(
                              'Address / Farm Location',
                              style: AppTextStyles.jakarta(
                                size: 12.5,
                                weight: FontWeight.w700,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: addressCtrl,
                              maxLines: 3,
                              style: AppTextStyles.body(titleTextColor),
                              decoration: InputDecoration(
                                hintText: 'Enter complete street address / barangay / municipality',
                                hintStyle: AppTextStyles.body(mutedTextColor),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(bottom: 36),
                                  child: Icon(Icons.location_on_outlined, size: 18, color: mutedTextColor),
                                ),
                                filled: true,
                                fillColor: fieldBgColor,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: fieldBorderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ==================== DRAWER FOOTER ACTIONS ====================
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        border: Border(top: BorderSide(color: borderColor, width: 1)),
                      ),
                      child: Row(
                        children: [
                          // Cancel Button
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                foregroundColor: isDark ? Colors.white : const Color(0xFF334155),
                                side: BorderSide(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                  width: 1,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: AppTextStyles.jakarta(
                                  size: 13.5,
                                  weight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Save Changes Button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.pop(dialogContext);
                                setState(() => _isLoading = true);
                                try {
                                  final pkCol = row['id'] != null ? 'id' : 'hog_raiser_id';
                                  await _supabase.from('hog_raisers').update({
                                    'name': nameCtrl.text.trim(),
                                    'phone': phoneCtrl.text.trim(),
                                    'address': addressCtrl.text.trim(),
                                  }).eq(pkCol, id);

                                  if (userId != null) {
                                    try {
                                      await _supabase.from('app_users').update({
                                        'name': nameCtrl.text.trim(),
                                      }).eq('user_id', userId);
                                    } catch (_) {}
                                  }

                                  await _loadRaisers(keyword: _searchCtrl.text);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Hog raiser profile updated successfully.', style: AppTextStyles.body(Colors.white)),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Update failed: $e', style: AppTextStyles.body(Colors.white)),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } finally {
                                  if (mounted) setState(() => _isLoading = false);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                              label: Text(
                                'Save Changes',
                                style: AppTextStyles.jakarta(
                                  size: 13.5,
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                ),
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
      },
      transitionBuilder: (dialogContext, anim, secondaryAnim, child) {
        final curvedAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnim),
          child: child,
        );
      },
    );
  }
}
