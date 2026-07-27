import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';
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
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({String keyword = ''}) async {
    setState(() => _isLoading = true);
    try {
      dynamic query = _supabase
          .from('app_users')
          .select('user_id, name, email, role, status, created_at')
          .inFilter('role', ['partner', 'cashier']);

      if (keyword.trim().isNotEmpty) {
        query = query.or('name.ilike.%$keyword%,email.ilike.%$keyword%');
      }

      final response = await query.order('name', ascending: true);
      if (mounted) {
        setState(() {
          _users = (response as List).cast<Map<String, dynamic>>();
          _loadErrorMessage = null;
        });
      }
    } catch (e) {
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

  Future<void> _approveUser(int userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cardBg,
        title: Text(
          'Confirm Approval',
          style: AppTextStyles.jakarta(size: 18, weight: FontWeight.w700, color: _titleColor),
        ),
        content: Text(
          'Are you sure you want to approve the account for "$name"?',
          style: AppTextStyles.body(_titleColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.button(_hintText),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Approve',
              style: AppTextStyles.button(Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _supabase
          .from('app_users')
          .update({'status': 'active'})
          .eq('user_id', userId);

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

  Future<void> _suspendUser(int userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cardBg,
        title: Text(
          'Confirm Suspend',
          style: AppTextStyles.jakarta(size: 18, weight: FontWeight.w700, color: _titleColor),
        ),
        content: Text(
          'Are you sure you want to suspend the account for "$name"?',
          style: AppTextStyles.body(_titleColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.button(_hintText),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Suspend',
              style: AppTextStyles.button(Colors.white),
            ),
          ),
        ],
      ),
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
    return Scaffold(
      backgroundColor: _bgDark,
      body: Row(
        children: [
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
                          padding: const EdgeInsets.all(18),
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 1340),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [_panelStart, _panelEnd]),
                                border: Border.all(color: _panelBorder, width: 1),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 26),
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
    // Counts for tabs
    final activePartnersCount = _users.where((u) {
      final r = u['role']?.toString().toLowerCase() ?? '';
      final s = u['status']?.toString().toLowerCase() ?? '';
      return r == 'partner' && s == 'active';
    }).length;

    final pendingPartnersCount = _users.where((u) {
      final r = u['role']?.toString().toLowerCase() ?? '';
      final s = u['status']?.toString().toLowerCase() ?? '';
      return r == 'partner' && s == 'pending';
    }).length;

    final activeCashiersCount = _users.where((u) {
      final r = u['role']?.toString().toLowerCase() ?? '';
      final s = u['status']?.toString().toLowerCase() ?? '';
      return r == 'cashier' && s == 'active';
    }).length;

    final pendingCashiersCount = _users.where((u) {
      final r = u['role']?.toString().toLowerCase() ?? '';
      final s = u['status']?.toString().toLowerCase() ?? '';
      return r == 'cashier' && s == 'pending';
    }).length;

    // Filter list by selected tab
    final filtered = _users.where((u) {
      final r = u['role']?.toString().toLowerCase() ?? '';
      final s = u['status']?.toString().toLowerCase() ?? '';
      
      if (_currentTab == 0) return r == 'partner' && s == 'active';
      if (_currentTab == 1) return r == 'partner' && s == 'pending';
      if (_currentTab == 2) return r == 'cashier' && s == 'active';
      return r == 'cashier' && s == 'pending';
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
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _cardBorder),
          ),
          padding: const EdgeInsets.all(20),
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
                  ElevatedButton(
                    onPressed: () => _loadUsers(keyword: _searchCtrl.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDark ? PiggyTrunkTheme.ptSurface : PiggyTrunkTheme.ptPrimary,
                      foregroundColor: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                      minimumSize: const Size(100, 48),
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
              _tableHeader(),
              const SizedBox(height: 8),
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
    final headers = ['FULL NAME', 'EMAIL ADDRESS', 'ROLE TYPE', 'STATUS', 'ACTIONS'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _cardBorder))),
      child: Row(
        children: headers
            .map(
              (h) => Expanded(
                child: Text(
                  h,
                  style: AppTextStyles.tableHeader(_hintText),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _tableRow(Map<String, dynamic> row) {
    final userId = int.tryParse(row['user_id'].toString()) ?? 0;
    final name = row['name']?.toString() ?? '';
    final email = row['email']?.toString() ?? '';
    final role = row['role']?.toString().toUpperCase() ?? '';
    final status = row['status']?.toString().toUpperCase() ?? '';

    final String roleLower = row['role']?.toString().toLowerCase() ?? '';
    final String prefix = roleLower == 'partner' ? 'Partner Investor - ' : 'Cashier - ';
    final displayName = '$prefix$name';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _cardBorder.withValues(alpha: 0.5)))),
      child: Row(
        children: [
          Expanded(child: Text(displayName, style: AppTextStyles.body(_titleColor))),
          Expanded(child: Text(email, style: AppTextStyles.body(_titleColor))),
          Expanded(child: Text(role, style: AppTextStyles.body(_titleColor))),
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'ACTIVE' 
                        ? PiggyTrunkTheme.ptSuccess.withValues(alpha: 0.1) 
                        : PiggyTrunkTheme.ptAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: status == 'ACTIVE' ? PiggyTrunkTheme.ptSuccess : PiggyTrunkTheme.ptAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (status == 'PENDING')
                  IconButton(
                    onPressed: () => _approveUser(userId, name),
                    icon: const Icon(Icons.check_circle_outline, size: 24, color: Colors.green),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Approve User',
                  )
                else if (status == 'ACTIVE')
                  IconButton(
                    onPressed: () => _suspendUser(userId, name),
                    icon: const Icon(Icons.block, size: 24, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Suspend User',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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
