import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';
import '../utils/responsive.dart';
import '../main.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;

  // KPI values
  int _activeRaisers = 0;
  int _batchCount = 0;
  double _totalCapital = 0;

  // Allocation values
  double _fatteningCapital = 0;
  double _sowCapital = 0;
  List<Map<String, dynamic>> _activeRaisersList = [];

  // Theme-aware color getters
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgDark => _isDark ? PiggyTrunkTheme.ptBgDark : PiggyTrunkTheme.ptBg;
  Color get _surfaceDark => _isDark ? PiggyTrunkTheme.ptSurfaceDark : PiggyTrunkTheme.ptSurface;
  Color get _borderDark => _isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
  Color get _textDark => _isDark ? PiggyTrunkTheme.ptTextDark : PiggyTrunkTheme.ptText;
  Color get _mutedDark => _isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;

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
    isInitialLaunch = false;
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('dashboard_summary')
          .select()
          .maybeSingle();

      final invRecordsRes = await _supabase
          .from('investment_records')
          .select('hog_raiser_id, id');
      final realBatchCount = (invRecordsRes as List).length;
      final activeRaiserIdsWithInvestments = invRecordsRes
          .map((inv) => inv['hog_raiser_id'].toString())
          .toSet();

      if (response != null) {
        setState(() {
          _activeRaisers = (response['active_raisers'] as num?)?.toInt() ?? 0;
          _batchCount = realBatchCount;
          _totalCapital = (response['total_capital'] as num?)?.toDouble() ?? 0;
          _fatteningCapital = (response['fattening_capital'] as num?)?.toDouble() ?? 0;
          _sowCapital = (response['sow_capital'] as num?)?.toDouble() ?? 0;
        });
      }

      final raisersRes = await _supabase
          .from('hog_raisers')
          .select('hog_raiser_id, name, pig_type, status, account_status, lifecycle_stage')
          .eq('account_status', 'active')
          .order('name', ascending: true);

      if (mounted) {
        setState(() {
          _activeRaisersList = (raisersRes as List)
              .cast<Map<String, dynamic>>()
              .where((r) {
                final rId = (r['id'] ?? r['hog_raiser_id'] ?? '').toString();
                return activeRaiserIdsWithInvestments.contains(rId);
              })
              .toList();
        });
      }
    } catch (e) {
      // If dashboard_summary view doesn't exist yet (SQL not run),
      // fall back to individual table queries
      await _loadDashboardFallback();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Fallback: query each table individually if the dashboard_summary view
  /// hasn't been created in Supabase yet.
  Future<void> _loadDashboardFallback() async {
    try {
      final results = await Future.wait([
        _supabase
            .from('hog_raisers')
            .select('hog_raiser_id')
            .eq('account_status', 'active'),
        _supabase.from('investment_records').select('id'),
        _supabase.from('investment_records').select('hog_raiser_id, investment_date, initial_capital, hog_type'),
        _supabase.from('hogs').select('hog_id').eq('status', 'dead'),
        _supabase
            .from('hog_raisers')
            .select('hog_raiser_id, name, pig_type, status, account_status, lifecycle_stage')
            .eq('account_status', 'active')
            .order('name', ascending: true),
      ]);

      if (!mounted) return;

      final raisers = results[0] as List;
      final batches = results[1] as List;
      final investmentRows = results[2] as List;
      final activeRaisers = results[4] as List;

      double totalCapital = 0;
      double fatteningCapital = 0;
      double sowCapital = 0;
      DateTime? earliest;

      for (final row in investmentRows) {
        final amt = (row['initial_capital'] as num?)?.toDouble() ?? 0;
        totalCapital += amt;
        final ht = (row['hog_type'] ?? '').toString().toLowerCase();
        if (ht == 'fattening') fatteningCapital += amt;
        if (ht == 'sow') sowCapital += amt;
        final rawDate = row['investment_date'];
        if (rawDate != null) {
          final d = DateTime.tryParse(rawDate.toString());
          if (d != null && (earliest == null || d.isBefore(earliest))) {
            earliest = d;
          }
        }
      }

      final activeRaiserIdsWithInvestments = investmentRows
          .map((inv) => inv['hog_raiser_id']?.toString() ?? '')
          .toSet();

      final filteredActiveRaisers = activeRaisers.where((r) {
        final rId = (r['id'] ?? r['hog_raiser_id'] ?? '').toString();
        return activeRaiserIdsWithInvestments.contains(rId);
      }).toList();

      setState(() {
        _activeRaisers = raisers.length;
        _batchCount = batches.length;
        _totalCapital = totalCapital;
        _fatteningCapital = fatteningCapital;
        _sowCapital = sowCapital;
        _activeRaisersList = filteredActiveRaisers.cast<Map<String, dynamic>>();
      });
    } catch (_) {
      // Leave defaults at 0 if fallback also fails
    }
  }

  String _formatCurrency(double value) {
    if (value == 0) return '₱0';
    final formatted = value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '₱$formatted';
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = Responsive.isSmallScreen(context);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: _bgDark,
      drawer: isSmall
          ? Drawer(
              backgroundColor: _surfaceDark,
              child: AdminSidebar(
                currentRoute: '/dashboard',
                onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
                isDrawer: true,
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isSmall)
            AdminSidebar(
              currentRoute: '/dashboard',
              onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
            ),
          Expanded(
            child: Column(
              children: [
                /// REUSABLE TOP BAR
                const ScreenTopBar(),
                /// MAIN DASHBOARD CONTENT
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(isMobile ? 14 : 16),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final contentWidth = constraints.maxWidth > 1400
                                  ? 1400.0
                                  : constraints.maxWidth;
                              return Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  width: contentWidth,
                                  decoration: isMobile
                                      ? null
                                      : BoxDecoration(
                                          color: _surfaceDark.withValues(alpha: 0.5),
                                          border: Border.all(
                                            color: _borderDark,
                                            width: 1,
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                  padding: EdgeInsets.all(isMobile ? 0 : 32),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      /// Dashboard Title + Refresh
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Dashboard',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: isMobile ? 22 : 30,
                                              fontWeight: FontWeight.w800,
                                              color: _textDark,
                                              letterSpacing: -0.04,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: _loadDashboardData,
                                            icon: Icon(Icons.refresh_rounded,
                                                color: _mutedDark),
                                            tooltip: 'Refresh',
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: isMobile ? 14 : 24),

                                      /// KPI CARDS ROW
                                      _buildKpiCardsRow(),
                                      SizedBox(height: isMobile ? 20 : 32),

                                      /// INVESTMENT ALLOCATION SECTION
                                      _buildInvestmentAllocationSection(),
                                      SizedBox(height: isMobile ? 20 : 32),

                                      /// ACTIVE HOG RAISERS PROGRESS SECTION
                                      _buildActiveRaisersSection(),
                                    ],
                                  ),
                                ),
                              );
                            },
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

  /// KPI CARDS ROW — now driven by live Supabase data
  Widget _buildKpiCardsRow() {
    final isMobile = Responsive.isMobile(context);
    final kpiData = [
      {
        'label': 'NUMBER OF HOG BATCH',
        'value': _batchCount.toString(),
      },
      {
        'label': 'TOTAL CURRENT INVESTMENT',
        'value': _formatCurrency(_totalCapital),
      },
    ];

    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            label: kpiData[0]['label'] as String,
            value: kpiData[0]['value'] as String,
            isMobile: isMobile,
          ),
        ),
        SizedBox(width: isMobile ? 12 : 20),
        Expanded(
          child: _buildKpiCard(
            label: kpiData[1]['label'] as String,
            value: kpiData[1]['value'] as String,
            isMobile: isMobile,
          ),
        ),
      ],
    );
  }

  /// Individual KPI Card
  Widget _buildKpiCard({
    required String label,
    required String value,
    bool isMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: _surfaceDark,
        border: Border.all(
          color: _borderDark,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: _mutedDark,
              letterSpacing: 0.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isMobile ? 8 : 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 22 : 28,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// INVESTMENT ALLOCATION SECTION — now driven by live Supabase data
  Widget _buildInvestmentAllocationSection() {
    final isMobile = Responsive.isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 14 : 32),
      decoration: BoxDecoration(
        color: _surfaceDark.withValues(alpha: 0.2),
        border: Border.all(
          color: _borderDark,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'INVESTMENT ALLOCATION',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Total: ${_formatCurrency(_totalCapital)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 11 : 13,
                  fontWeight: FontWeight.w600,
                  color: _mutedDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$_activeRaisers active raiser${_activeRaisers == 1 ? '' : 's'}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.w500,
              color: _mutedDark,
            ),
          ),
          SizedBox(height: isMobile ? 14 : 20),
          Row(
            children: [
              Expanded(
                child: _buildAllocationCard(
                  title: 'FATTENING',
                  amount: _formatCurrency(_fatteningCapital),
                  isMobile: isMobile,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 24),
              Expanded(
                child: _buildAllocationCard(
                  title: 'SOW',
                  amount: _formatCurrency(_sowCapital),
                  isMobile: isMobile,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Individual Allocation Card with Top Border Accent
  Widget _buildAllocationCard({
    required String title,
    required String amount,
    double? width,
    bool isMobile = false,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _surfaceDark,
        border: Border.all(
          color: _borderDark,
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(isMobile ? 14 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 11 : 14,
              fontWeight: FontWeight.w700,
              color: _mutedDark,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 20 : 26,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ACTIVE HOG RAISERS PROGRESS SECTION - Displays progress map below investment allocation
  Widget _buildActiveRaisersSection() {
    final isMobile = Responsive.isMobile(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      decoration: BoxDecoration(
        color: _surfaceDark.withValues(alpha: 0.2),
        border: Border.all(
          color: _borderDark,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE HOG RAISERS PROGRESS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textDark,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Monitor lifecycle stages of all approved active raisers',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _mutedDark,
            ),
          ),
          const SizedBox(height: 24),
          if (_activeRaisersList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No active raisers found.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _mutedDark,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activeRaisersList.length,
              separatorBuilder: (context, index) => Divider(
                color: _borderDark.withValues(alpha: 0.5),
                height: 32,
              ),
              itemBuilder: (context, index) {
                final raiser = _activeRaisersList[index];
                final name = raiser['name'] ?? '';
                final pigType = raiser['pig_type'] ?? '';
                final currentStage = raiser['lifecycle_stage'] ?? 'Booster';
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Raiser - $name',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            pigType.toString().toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _isDark ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildLifecycleMap(currentStage.toString(), pigType.toString()),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLifecycleMap(String currentStage, String pigType) {
    final List<String> lifecycleStages = pigType.toLowerCase() == 'sow'
        ? ['Booster', 'Pre-Starter', 'Starter', 'Grower', 'Breeder', 'Lactation']
        : ['Booster', 'Pre-Starter', 'Starter', 'Grower', 'Finisher', 'Selling'];
    final activeIndex = lifecycleStages.indexWhere((stage) => stage.toLowerCase() == currentStage.toLowerCase());
    final normalizedIndex = activeIndex < 0 ? 0 : activeIndex;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 540),
        child: Row(
          children: List.generate(lifecycleStages.length, (index) {
            final stage = lifecycleStages[index];
            final isDone = index < normalizedIndex;
            final isCurrent = index == normalizedIndex;

            Color bgColor;
            Color fgColor;
            IconData icon;
            if (isDone) {
              bgColor = const Color(0xFF10B981);
              fgColor = Colors.white;
              icon = Icons.check;
            } else if (isCurrent) {
              bgColor = _isDark ? PiggyTrunkTheme.ptPrimaryDark : PiggyTrunkTheme.ptPrimary;
              fgColor = _isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
              icon = Icons.priority_high_rounded;
            } else {
              bgColor = _isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
              fgColor = Colors.white;
              icon = Icons.radio_button_unchecked;
            }

            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: bgColor,
                    child: Icon(icon, size: 20, color: fgColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
