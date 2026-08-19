import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../main.dart';
import '../theme/app_text_styles.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';
import '../widgets/slide_over_confirmation_drawer.dart';
import '../utils/responsive.dart';
import '../widgets/hog_raiser/raiser_profile_drawer.dart';
import '../widgets/hog_raiser/edit_raiser_drawer.dart';
import '../widgets/hog_raiser/active_raisers_tab.dart';

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
  int _currentTab = 0; // 0 = Active, 1 = Pending, 2 = Archived
  String? _loadErrorMessage;

  RealtimeChannel? _raisersSubscription;
  bool _hasCheckedRouteArgs = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgDark => _isDark ? PiggyTrunkTheme.ptBgDark : PiggyTrunkTheme.ptBg;
  Color get _accentDark => _isDark ? PiggyTrunkTheme.ptAccentDark : PiggyTrunkTheme.ptAccent;
  Color get _panelStart => _isDark ? const Color(0xFF1A2940) : Colors.white;
  Color get _panelEnd => _isDark ? const Color(0xFF0F1C2F) : Colors.white;
  Color get _panelBorder => _isDark ? const Color(0xFF2A3E5B) : const Color(0xFFE3EAF3);
  Color get _cardBg => _isDark ? const Color(0xFF132238) : Colors.white;
  Color get _titleColor => _isDark ? Colors.white : const Color(0xFF18314F);
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

      final Map<String, String> avatarMap = {};
      try {
        final storageFiles = await _supabase.storage.from('profile_pictures').list(path: 'avatars');
        for (final file in storageFiles) {
          final fname = file.name;
          final match = RegExp(r'^avatar-(\d+)-').firstMatch(fname);
          if (match != null) {
            final id = match.group(1)!;
            final existing = avatarMap[id];
            if (existing == null || fname.compareTo(existing) > 0) {
              avatarMap[id] = fname;
            }
          }
        }
      } catch (_) {}

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

          final raiserIdStr = (r['hog_raiser_id'] ?? r['id'] ?? '').toString();
          final userIdStr = (r['user_id'] ?? '').toString();
          String? resolvedAvatarUrl;

          final matchedFile = avatarMap[raiserIdStr] ?? avatarMap[userIdStr];
          if (matchedFile != null) {
            resolvedAvatarUrl = _supabase.storage.from('profile_pictures').getPublicUrl('avatars/$matchedFile');
          }

          return {
            ...r,
            'name': resolvedFullName,
            'email': appUsers?['email'] ?? '',
            'supabase_user_id': appUsers?['supabase_user_id'],
            'avatar_url': resolvedAvatarUrl ?? r['avatar_url'],
          };
        }).where((r) => r['supabase_user_id'] != null).toList();

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

  void _showThemedSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.body(Colors.white)),
        backgroundColor: isError ? Colors.red : PiggyTrunkTheme.ptSuccess,
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
                              child: _buildMainContent(),
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

  Widget _buildMainContent() {
    final isMobile = Responsive.isMobile(context);
    final activeCount = _raisers.where((r) {
      final status = (r['status'] ?? '').toString().toLowerCase();
      final accStatus = (r['account_status'] ?? '').toString().toLowerCase();
      if (status == 'archived' || accStatus == 'archived') return false;
      if (status == 'pending' || accStatus == 'pending') return false;
      return status == 'active' || accStatus == 'active' || accStatus == 'approved';
    }).length;

    final pendingCount = _raisers.where((r) {
      final status = (r['status'] ?? '').toString().toLowerCase();
      final accStatus = (r['account_status'] ?? '').toString().toLowerCase();
      if (status == 'archived' || accStatus == 'archived') return false;
      return status == 'pending' || accStatus == 'pending';
    }).length;

    final archivedCount = _raisers.where((r) {
      final status = (r['status'] ?? '').toString().toLowerCase();
      final accStatus = (r['account_status'] ?? '').toString().toLowerCase();
      return status == 'archived' || accStatus == 'archived';
    }).length;

    final filteredRaisers = _raisers.where((r) {
      final status = (r['status'] ?? '').toString().toLowerCase();
      final accStatus = (r['account_status'] ?? '').toString().toLowerCase();
      final isArchived = status == 'archived' || accStatus == 'archived';
      final isPending = !isArchived && (status == 'pending' || accStatus == 'pending');
      final isActive = !isArchived && !isPending && (status == 'active' || accStatus == 'active' || accStatus == 'approved');

      if (_currentTab == 0) return isActive;
      if (_currentTab == 1) return isPending;
      return isArchived;
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
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabButton(0, 'Active Raisers', activeCount, isMobile: true),
                    const SizedBox(width: 8),
                    _buildTabButton(1, 'Pending Approvals', pendingCount, isMobile: true),
                    const SizedBox(width: 8),
                    _buildTabButton(2, 'Archived', archivedCount, isMobile: true),
                  ],
                ),
              )
            : Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  _buildTabButton(0, 'Active Raisers', activeCount),
                  _buildTabButton(1, 'Pending Approvals', pendingCount),
                  _buildTabButton(2, 'Archived', archivedCount),
                ],
              ),
        const SizedBox(height: 20),
        ActiveRaisersTab(
          raisers: filteredRaisers,
          currentTab: _currentTab,
          searchCtrl: _searchCtrl,
          onSearch: (keyword) => _loadRaisers(keyword: keyword),
          onShowDetails: (row) => RaiserProfileDrawer.show(
            context: context,
            row: row,
            onApprove: _approveRaiserDirectly,
            onDelete: _deleteRaiser,
          ),
          onEditRaiser: (row) => EditRaiserDrawer.show(
            context: context,
            row: row,
            onUpdated: () => _loadRaisers(keyword: _searchCtrl.text),
            onShowSnackBar: _showThemedSnackBar,
          ),
          onArchiveRaiser: _archiveRaiser,
          onRestoreRaiser: _restoreRaiser,
          onDeleteRaiser: _deleteRaiser,
          onApproveRaiser: _approveRaiserDirectly,
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
      _showThemedSnackBar('Raiser "$name" approved successfully.');
    } catch (e) {
      _showThemedSnackBar('Approval failed: $e', isError: true);
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
      _showThemedSnackBar('Raiser registration rejected successfully.');
    } catch (e) {
      _showThemedSnackBar('Rejection failed: $e', isError: true);
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
          'account_status': 'Archived',
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
      _showThemedSnackBar('Raiser "$name" archived successfully.');
    } catch (e) {
      _showThemedSnackBar('Archive failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreRaiser(Map<String, dynamic> row) async {
    final id = _parseId(row['id'] ?? row['hog_raiser_id']);
    final userId = _parseId(row['user_id']);
    if (id == null) return;
    final name = (row['name'] ?? '').toString();

    setState(() => _isLoading = true);
    try {
      final pkCol = row['id'] != null ? 'id' : 'hog_raiser_id';
      final List<Future> updates = [
        _supabase.from('hog_raisers').update({
          'status': 'Active',
          'account_status': 'Approved',
        }).eq(pkCol, id),
      ];

      if (userId != null) {
        updates.add(
          _supabase.from('app_users').update({
            'status': 'approved',
          }).eq('user_id', userId),
        );
      }

      await Future.wait(updates);
      await _loadRaisers(keyword: _searchCtrl.text);
      _showThemedSnackBar('Raiser "$name" restored successfully.');
    } catch (e) {
      _showThemedSnackBar('Restore failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
