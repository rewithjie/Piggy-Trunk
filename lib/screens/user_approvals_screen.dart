import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';
import '../widgets/slide_over_confirmation_drawer.dart';
import '../services/email_service.dart';
import '../utils/responsive.dart';
import '../main.dart';

class UserApprovalsScreen extends StatefulWidget {
  const UserApprovalsScreen({super.key});

  @override
  State<UserApprovalsScreen> createState() => _UserApprovalsScreenState();
}

class _UserApprovalsScreenState extends State<UserApprovalsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  int _currentTab = 0; // 0 = Active Partners, 1 = Pending Partners, 2 = Active Cashiers, 3 = Pending Cashiers
  String? _loadErrorMessage;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgDark => _isDark ? PiggyTrunkTheme.ptBgDark : PiggyTrunkTheme.ptBg;
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

  RealtimeChannel? _appUsersChannel;
  bool _hasCheckedRouteArgs = false;

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
    _loadUsers();
    _subscribeToAppUsers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCheckedRouteArgs) {
      _hasCheckedRouteArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == 'pending_partner' || args == 'pending') {
        setState(() => _currentTab = 1);
      } else if (args == 'pending_cashier') {
        setState(() => _currentTab = 3);
      }
    }
  }

  void _subscribeToAppUsers() {
    _appUsersChannel = _supabase
        .channel('public:app_users_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'app_users',
          callback: (payload) {
            if (mounted) {
              _loadUsers(keyword: _searchCtrl.text);
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _appUsersChannel?.unsubscribe();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({String keyword = ''}) async {
    setState(() => _isLoading = true);
    try {
      dynamic query = _supabase
          .from('app_users')
          .select('user_id, name, email, role, status, created_at');

      if (keyword.trim().isNotEmpty) {
        query = query.or('name.ilike.%$keyword%,email.ilike.%$keyword%');
      }

      final response = await query.order('user_id', ascending: false);
      final list = (response as List).cast<Map<String, dynamic>>();
      debugPrint('UserApprovalsScreen loaded ${list.length} app_users: $list');

      if (mounted) {
        setState(() {
          _users = list.where((u) {
            final r = u['role']?.toString().toLowerCase() ?? '';
            return r != 'admin';
          }).toList();
          _loadErrorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('UserApprovalsScreen _loadUsers error: $e');
      if (mounted) {
        setState(() {
          _loadErrorMessage = 'Load failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _approveUser(int userId, String name, {String? email, String? role}) async {
    final targetUser = _users.firstWhere((u) => u['user_id'] == userId, orElse: () => <String, dynamic>{});
    final userEmail = email ?? targetUser['email']?.toString() ?? '';
    final userRole = role ?? targetUser['role']?.toString() ?? 'User';
    final avatarUrl = (targetUser['avatar_url'] ?? targetUser['profile_picture'] ?? targetUser['photo_url'])?.toString();

    final confirm = await SlideOverConfirmationDrawer.show(
      context: context,
      title: 'Confirm Approval',
      message: 'Are you sure you want to approve the account for "$name"? They will receive an activation email immediately.',
      actionType: SlideOverActionType.success,
      userName: name,
      userEmail: userEmail,
      userRole: userRole,
      avatarUrl: avatarUrl,
      confirmButtonText: 'Yes, Approve',
      cancelButtonText: 'Cancel',
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _supabase
          .from('app_users')
          .update({'status': 'active'})
          .eq('user_id', userId);

      try {
        await _supabase
            .from('cashiers')
            .update({'status': 'active'})
            .eq('user_id', userId);
      } catch (_) {}

      try {
        await _supabase
            .from('partner_investors')
            .update({'status': 'active'})
            .eq('user_id', userId);
      } catch (_) {}

      try {
        await _supabase
            .from('hog_raisers')
            .update({'account_status': 'active', 'status': 'Active'})
            .eq('user_id', userId);
      } catch (_) {}

      // Trigger Resend Account Approval Email
      try {
        final email = targetUser['email']?.toString() ?? '';
        final role = targetUser['role']?.toString() ?? 'user';
        if (email.isNotEmpty) {
          EmailService().sendAccountApprovalEmail(
            recipientEmail: email,
            recipientName: name,
            role: role,
          );
        }
      } catch (e) {
        debugPrint("Notice: Failed to send approval email: $e");
      }

      // Clear pending registration notification for this user
      try {
        if (userEmail.isNotEmpty) {
          await _supabase
              .from('admin_notifications')
              .delete()
              .eq('metadata->>email', userEmail)
              .eq('type', 'user_registration');
        }
      } catch (_) {}

      await _loadUsers(keyword: _searchCtrl.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User "$name" approved successfully.', style: AppTextStyles.body(Colors.white)),
          backgroundColor: PiggyTrunkTheme.ptSuccess,
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

  Future<void> _rejectUser(int userId, String name, {String? email, String? role}) async {
    final targetUser = _users.firstWhere((u) => u['user_id'] == userId, orElse: () => <String, dynamic>{});
    final userEmail = email ?? targetUser['email']?.toString() ?? '';
    final userRole = role ?? targetUser['role']?.toString() ?? 'User';
    final avatarUrl = (targetUser['avatar_url'] ?? targetUser['profile_picture'] ?? targetUser['photo_url'])?.toString();

    final confirm = await SlideOverConfirmationDrawer.show(
      context: context,
      title: 'Confirm Rejection',
      message: 'Are you sure you want to reject the registration for "$name"? This will delete their pending registration record.',
      actionType: SlideOverActionType.danger,
      userName: name,
      userEmail: userEmail,
      userRole: userRole,
      avatarUrl: avatarUrl,
      confirmButtonText: 'Yes, Reject',
      cancelButtonText: 'Cancel',
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _supabase.from('app_users').delete().eq('user_id', userId);
      try {
        await _supabase.from('cashiers').delete().eq('user_id', userId);
      } catch (_) {}
      try {
        await _supabase.from('partner_investors').delete().eq('user_id', userId);
      } catch (_) {}
      try {
        await _supabase.from('hog_raisers').delete().eq('user_id', userId);
      } catch (_) {}

      // Clear pending registration notification for this user
      try {
        if (userEmail.isNotEmpty) {
          await _supabase
              .from('admin_notifications')
              .delete()
              .eq('metadata->>email', userEmail)
              .eq('type', 'user_registration');
        }
      } catch (_) {}

      await _loadUsers(keyword: _searchCtrl.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration for "$name" rejected successfully.', style: AppTextStyles.body(Colors.white)),
          backgroundColor: Colors.redAccent,
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

  Future<void> _suspendUser(int userId, String name, {String? email, String? role}) async {
    final targetUser = _users.firstWhere((u) => u['user_id'] == userId, orElse: () => <String, dynamic>{});
    final userEmail = email ?? targetUser['email']?.toString() ?? '';
    final userRole = role ?? targetUser['role']?.toString() ?? 'User';
    final avatarUrl = (targetUser['avatar_url'] ?? targetUser['profile_picture'] ?? targetUser['photo_url'])?.toString();

    final confirm = await SlideOverConfirmationDrawer.show(
      context: context,
      title: 'Confirm Suspend',
      message: 'Are you sure you want to suspend the account for "$name"? They will be blocked from logging in.',
      actionType: SlideOverActionType.danger,
      userName: name,
      userEmail: userEmail,
      userRole: userRole,
      avatarUrl: avatarUrl,
      confirmButtonText: 'Yes, Suspend',
      cancelButtonText: 'Cancel',
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _supabase
          .from('app_users')
          .update({'status': 'suspended'})
          .eq('user_id', userId);

      await _loadUsers(keyword: _searchCtrl.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User "$name" suspended successfully.', style: AppTextStyles.body(Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Suspend failed: $e', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              backgroundColor: _cardBg,
              child: AdminSidebar(
                currentRoute: '/users',
                onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
                isDrawer: true,
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isSmall)
            AdminSidebar(
              currentRoute: '/users',
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
          )
        ],
      ),
    );
  }

  Widget _buildListView() {
    final isMobile = Responsive.isMobile(context);

    // Counts for tabs
    final activePartnersCount = _users.where((u) {
      final r = u['role']?.toString().toLowerCase() ?? '';
      final s = u['status']?.toString().toLowerCase() ?? '';
      return (r.contains('partner') || r == 'investor') && (s == 'active' || s == 'approved');
    }).length;

    final pendingPartnersCount = _users.where((u) {
      final r = u['role']?.toString().toLowerCase() ?? '';
      final s = u['status']?.toString().toLowerCase() ?? '';
      return (r.contains('partner') || r == 'investor') && (s == 'pending');
    }).length;

    final activeCashiersCount = _users.where((u) {
      final r = u['role']?.toString().toLowerCase() ?? '';
      final s = u['status']?.toString().toLowerCase() ?? '';
      return r.contains('cashier') && (s == 'active' || s == 'approved');
    }).length;

    final pendingCashiersCount = _users.where((u) {
      final r = u['role']?.toString().toLowerCase() ?? '';
      final s = u['status']?.toString().toLowerCase() ?? '';
      return r.contains('cashier') && (s == 'pending');
    }).length;

    // Filter list by selected tab
    final filtered = _users.where((u) {
      final r = u['role']?.toString().toLowerCase() ?? '';
      final s = u['status']?.toString().toLowerCase() ?? '';
      
      if (_currentTab == 0) return (r.contains('partner') || r == 'investor') && (s == 'active' || s == 'approved');
      if (_currentTab == 1) return (r.contains('partner') || r == 'investor') && s == 'pending';
      if (_currentTab == 2) return r.contains('cashier') && (s == 'active' || s == 'approved');
      return r.contains('cashier') && s == 'pending';
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Management',
          style: AppTextStyles.pageTitle(_titleColor),
        ),
        if (_loadErrorMessage != null) ...[
          const SizedBox(height: 10),
          _buildErrorBanner(_loadErrorMessage!),
        ],
        const SizedBox(height: 20),
        // Tab selectors
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTabButton(0, 'Active Partner Investors', activePartnersCount),
              const SizedBox(width: 12),
              _buildTabButton(1, 'Pending Partner Investors', pendingPartnersCount),
              const SizedBox(width: 12),
              _buildTabButton(2, 'Active Cashiers', activeCashiersCount),
              const SizedBox(width: 12),
              _buildTabButton(3, 'Pending Cashiers', pendingCashiersCount),
            ],
          ),
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
              // Search controls
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: AppTextStyles.body(_fieldText),
                      decoration: InputDecoration(
                        hintText: 'Search by name or email...',
                        hintStyle: AppTextStyles.body(_hintText),
                        prefixIcon: Icon(Icons.search, color: _hintText),
                        filled: true,
                        fillColor: _fieldBg,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _fieldBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _fieldFocus),
                        ),
                      ),
                      onSubmitted: (value) => _loadUsers(keyword: value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _loadUsers(keyword: _searchCtrl.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDark ? PiggyTrunkTheme.ptSurface : PiggyTrunkTheme.ptPrimary,
                      foregroundColor: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                      minimumSize: const Size(90, 48),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.search, size: 18),
                    label: Text(
                      'Search',
                      style: AppTextStyles.button(_isDark ? PiggyTrunkTheme.ptPrimary : Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _loadUsers(keyword: _searchCtrl.text),
                    icon: Icon(Icons.refresh_rounded, color: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary, size: 24),
                    tooltip: 'Refresh Users List',
                    style: IconButton.styleFrom(
                      backgroundColor: _isDark ? const Color(0xFF1E2F47) : const Color(0xFFEEF4FD),
                      minimumSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final tableWidth = constraints.maxWidth > 850 ? constraints.maxWidth : 850.0;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _tableHeader(),
                          const SizedBox(height: 4),
                          if (filtered.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 50),
                              child: Center(
                                child: Text(
                                  _currentTab == 0 || _currentTab == 2
                                      ? 'No active users found'
                                      : 'No pending approvals',
                                  style: AppTextStyles.jakarta(size: 20, weight: FontWeight.w700, color: _titleColor),
                                ),
                              ),
                            )
                          else
                            ...filtered.map(_tableRow),
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

  Widget _buildTabButton(int index, String label, int count) {
    final isSelected = _currentTab == index;
    final textStyle = AppTextStyles.jakarta(
      size: 14,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(185, 48),
      ),
      child: Text('$label ($count)', style: textStyle),
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
              child: Text('FULL NAME', style: AppTextStyles.tableHeader(_hintText)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('EMAIL ADDRESS', style: AppTextStyles.tableHeader(_hintText)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('ROLE TYPE', style: AppTextStyles.tableHeader(_hintText)),
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
            flex: 2,
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
    final userId = int.tryParse(row['user_id'].toString()) ?? 0;
    final name = (row['name']?.toString() ?? '').trim();
    final email = row['email']?.toString() ?? '';
    final roleRaw = (row['role'] ?? 'User').toString();
    final role = roleRaw.toLowerCase() == 'partner'
        ? 'Partner Investor'
        : (roleRaw.toLowerCase() == 'cashier'
            ? 'Cashier'
            : (roleRaw.toLowerCase().contains('raiser') ? 'Hog Raiser' : roleRaw));
    final status = row['status']?.toString().toUpperCase() ?? 'ACTIVE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _cardBorder.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                name.isEmpty ? 'User' : name,
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
                email,
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
                role,
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
                    color: status == 'ACTIVE' 
                        ? PiggyTrunkTheme.ptSuccess.withValues(alpha: 0.15) 
                        : PiggyTrunkTheme.ptAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: status == 'ACTIVE' ? PiggyTrunkTheme.ptSuccess : PiggyTrunkTheme.ptAccent,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _showUserDetails(row),
                    icon: Icon(Icons.visibility_outlined, size: 20, color: _isDark ? const Color(0xFF94A3B8) : const Color(0xFF4B6281)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'View Details',
                  ),
                  const SizedBox(width: 10),
                  if (status == 'PENDING') ...[
                    IconButton(
                      onPressed: () => _approveUser(userId, name, email: email, role: role),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 21, color: PiggyTrunkTheme.ptSuccess),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Approve User',
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () => _rejectUser(userId, name, email: email, role: role),
                      icon: const Icon(Icons.cancel_outlined, size: 21, color: Color(0xFFFF758C)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Reject Registration',
                    ),
                  ] else if (status == 'ACTIVE')
                    IconButton(
                      onPressed: () => _suspendUser(userId, name, email: email, role: role),
                      icon: const Icon(Icons.block_rounded, size: 20, color: Color(0xFFFF758C)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Suspend User',
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> row) {
    final isMobile = MediaQuery.of(context).size.width < 720;
    if (isMobile) {
      _showUserBottomSheet(row);
    } else {
      _showUserSideDrawer(row);
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
    const bgColor = Colors.white;
    final borderColor = isDark ? Colors.white : const Color(0xFF18314F);
    final textColor = isDark ? const Color(0xFF0F172A) : const Color(0xFF18314F);

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
            color: (isDark ? Colors.white : const Color(0xFF18314F)).withValues(alpha: isDark ? 0.25 : 0.12),
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

  void _showUserBottomSheet(Map<String, dynamic> row) {
    final userId = int.tryParse(row['user_id'].toString()) ?? 0;
    final name = (row['name'] ?? 'User').toString();
    final email = (row['email'] ?? 'N/A').toString();
    final roleRaw = (row['role'] ?? 'User').toString();
    final status = (row['status'] ?? 'Active').toString().toUpperCase();
    final createdAt = (row['created_at'] ?? 'N/A').toString().split('T').first;
    final isPending = status == 'PENDING';
    final avatarUrl = _getAvatarUrl(row);

    final roleDisplay = roleRaw.toLowerCase() == 'partner'
        ? 'Partner Investor'
        : (roleRaw.toLowerCase() == 'cashier'
            ? 'Cashier'
            : (roleRaw.toLowerCase().contains('raiser') ? 'Hog Raiser' : roleRaw));

    final statusColor = status == 'ACTIVE' || status == 'APPROVED'
        ? PiggyTrunkTheme.ptSuccess
        : (status == 'PENDING' ? const Color(0xFFFFAA00) : Colors.redAccent);

    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join('').toUpperCase()
        : 'US';

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
                      'User Account Profile',
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
                            _drawerDetailRow('Full Name', name),
                            _drawerDivider(),
                            _drawerDetailRow('Email Address', email),
                            _drawerDivider(),
                            _drawerDetailRow('Role Type', roleDisplay),
                            _drawerDivider(),
                            _drawerDetailRow('Registered', createdAt),
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
                            _rejectUser(userId, name);
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
                            _approveUser(userId, name);
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
                    ] else ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _suspendUser(userId, name);
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
                            side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'Suspend Account',
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserSideDrawer(Map<String, dynamic> row) {
    final userId = int.tryParse(row['user_id'].toString()) ?? 0;
    final name = (row['name'] ?? 'User').toString();
    final email = (row['email'] ?? 'N/A').toString();
    final roleRaw = (row['role'] ?? 'User').toString();
    final status = (row['status'] ?? 'Active').toString().toUpperCase();
    final createdAt = (row['created_at'] ?? 'N/A').toString().split('T').first;
    final isPending = status == 'PENDING';
    final avatarUrl = _getAvatarUrl(row);

    final roleDisplay = roleRaw.toLowerCase() == 'partner'
        ? 'Partner Investor'
        : (roleRaw.toLowerCase() == 'cashier'
            ? 'Cashier'
            : (roleRaw.toLowerCase().contains('raiser') ? 'Hog Raiser' : roleRaw));

    final statusColor = status == 'ACTIVE' || status == 'APPROVED'
        ? PiggyTrunkTheme.ptSuccess
        : (status == 'PENDING' ? const Color(0xFFFFAA00) : Colors.redAccent);

    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join('').toUpperCase()
        : 'US';

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'User Details',
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
                              'User Account Profile',
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
                                'ACCOUNT INFORMATION',
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
                                    _drawerDetailRow('Full Name', name),
                                    _drawerDivider(),
                                    _drawerDetailRow('Email Address', email),
                                    _drawerDivider(),
                                    _drawerDetailRow('Role Type', roleDisplay),
                                    _drawerDivider(),
                                    _drawerDetailRow('Registered', createdAt),
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
                                    _rejectUser(userId, name);
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
                                    _approveUser(userId, name);
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
                            ] else ...[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                    _suspendUser(userId, name);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
                                    side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text(
                                    'Suspend Account',
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

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: GoogleFonts.plusJakartaSans(color: Colors.red, fontWeight: FontWeight.bold),
      ),
    );
  }
}
