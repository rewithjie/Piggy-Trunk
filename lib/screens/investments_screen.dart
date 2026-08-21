import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/investment_model.dart';
import '../theme/app_theme.dart';
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

  Future<void> _loadInvestments() async {
    setState(() => _isLoading = true);
    try {
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

        loaded.add(Investment.fromJson(rMap));
      }

      if (!mounted) return;
      setState(() => investments = loaded);
    } catch (e) {
      debugPrint('Error loading investments: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
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
