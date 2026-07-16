import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../main.dart';
import '../theme/app_text_styles.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';

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
    _subscribeToRaisers();
  }

  void _subscribeToRaisers() {
    _raisersSubscription = _supabase
        .channel('public:hog_raisers')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'hog_raisers',
          callback: (payload) {
            _loadRaisers(keyword: _searchCtrl.text);
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

  Future<void> _loadRaisers({String keyword = ''}) async {
    setState(() => _isLoading = true);
    try {
      dynamic query = _supabase
          .from('hog_raisers')
          .select('hog_raiser_id, name, address, phone, pig_type, status, account_status, lifecycle_stage, user_id, app_users!hog_raisers_user_id_fkey(email, supabase_user_id)');
      if (keyword.trim().isNotEmpty) {
        query = query.or('name.ilike.%$keyword%,address.ilike.%$keyword%,phone.ilike.%$keyword%');
      }
      final response = await query.order('name', ascending: true);

      if (!mounted) return;
      setState(() {
        _raisers = (response as List).cast<Map<String, dynamic>>().map((r) {
          final appUsers = r['app_users'] as Map<String, dynamic>?;
          return {
            ...r,
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
    return Scaffold(
      backgroundColor: _bgDark,
      body: Row(
        children: [
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
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
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
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
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
        Row(
          children: [
            _buildTabButton(0, 'Active Raisers', activeCount),
            const SizedBox(width: 12),
            _buildTabButton(1, 'Pending Approvals', pendingCount),
          ],
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
        minimumSize: const Size(180, 48),
      ),
      child: Text('$label ($count)', style: textStyle),
    );
  }

  Widget _tableHeader() {
    final headers = ['HOG RAISER', 'ADDRESS', 'PHONE NUMBER', 'PIG TYPE', 'STATUS', 'ACTIONS'];
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
    final raiserId = _parseId(row['id'] ?? row['hog_raiser_id']);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _cardBorder.withValues(alpha: 0.5)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Raiser - ${(row['name'] ?? '')}', style: AppTextStyles.body(_titleColor))),
              Expanded(child: Text((row['address'] ?? '').toString(), style: AppTextStyles.body(_titleColor))),
              Expanded(child: Text((row['phone'] ?? '').toString(), style: AppTextStyles.body(_titleColor))),
              Expanded(
                child: _currentTab == 1 && raiserId != null
                    ? Container(
                        padding: const EdgeInsets.only(right: 16),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<String>(
                            value: _selectedPigTypes[raiserId],
                            hint: Text(
                              'Select Type',
                              style: AppTextStyles.body(_hintText).copyWith(fontSize: 14),
                            ),
                            dropdownColor: _cardBg,
                            iconEnabledColor: _titleColor,
                            style: AppTextStyles.body(_fieldText).copyWith(fontSize: 14),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                            items: const ['Fattening', 'Sow']
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedPigTypes[raiserId] = val;
                              });
                            },
                          ),
                        ),
                      )
                    : Text((row['pig_type'] ?? '').toString(), style: AppTextStyles.body(_titleColor)),
              ),
              Expanded(child: Text((row['account_status'] ?? '').toString().toUpperCase(), style: AppTextStyles.body(_titleColor))),
              Expanded(
                child: (row['account_status'] ?? '').toString().toLowerCase() == 'pending'
                    ? Row(
                        children: [
                          IconButton(
                            onPressed: () => _approveRaiserDirectly(row),
                            icon: const Icon(Icons.check_circle_outline, size: 24, color: Colors.green),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Approve Raiser',
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () => _deleteRaiser(row),
                            icon: Icon(Icons.close_rounded, size: 24, color: _accentDark),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Reject',
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
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

    final selectedType = _selectedPigTypes[id];
    if (selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a Pig Type from the dropdown first.', style: AppTextStyles.body(Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final name = (row['name'] ?? '').toString();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cardBg,
        title: Text(
          'Approve Hog Raiser',
          style: AppTextStyles.jakarta(size: 18, weight: FontWeight.w700, color: _titleColor),
        ),
        content: Text(
          'Are you sure you want to approve "$name" as "$selectedType"?',
          style: AppTextStyles.body(_titleColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.button(Colors.white70),
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
      final pkCol = row['id'] != null ? 'id' : 'hog_raiser_id';
      final List<Future> updates = [
        _supabase.from('hog_raisers').update({
          'pig_type': selectedType,
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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cardBg,
        title: Text(
          'Reject Hog Raiser',
          style: AppTextStyles.jakarta(size: 18, weight: FontWeight.w700, color: _titleColor),
        ),
        content: Text(
          'Are you sure you want to reject "$name"?',
          style: AppTextStyles.body(_titleColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.button(Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Reject',
              style: AppTextStyles.button(Colors.white),
            ),
          ),
        ],
      ),
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
}
