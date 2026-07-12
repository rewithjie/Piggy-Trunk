import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';

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
  int _mortalityCount = 0;

  // Allocation values
  double _fatteningCapital = 0;
  double _sowCapital = 0;
  DateTime? _startOfInvestment;
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
          _mortalityCount = (response['mortality_count'] as num?)?.toInt() ?? 0;
          _fatteningCapital = (response['fattening_capital'] as num?)?.toDouble() ?? 0;
          _sowCapital = (response['sow_capital'] as num?)?.toDouble() ?? 0;
          final rawDate = response['start_of_investment'];
          if (rawDate != null) {
            _startOfInvestment = DateTime.tryParse(rawDate.toString());
          }
        });
      }

      final raisersRes = await _supabase
          .from('hog_raisers')
          .select('id, hog_raiser_id, name, pig_type, status, account_status, lifecycle_stage')
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
            .select('id, hog_raiser_id, name, pig_type, status, account_status, lifecycle_stage')
            .eq('account_status', 'active')
            .order('name', ascending: true),
      ]);

      if (!mounted) return;

      final raisers = results[0] as List;
      final batches = results[1] as List;
      final investmentRows = results[2] as List;
      final deadHogs = results[3] as List;
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
        _mortalityCount = deadHogs.length;
        _fatteningCapital = fatteningCapital;
        _sowCapital = sowCapital;
        _startOfInvestment = earliest;
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatPercent(double capital, double total) {
    if (total == 0) return '0%';
    return '${((capital / total) * 100).toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      backgroundColor: _bgDark,
      body: Row(
        children: [
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
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final contentWidth = constraints.maxWidth > 1400
                                  ? 1400.0
                                  : constraints.maxWidth;
                              return Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  width: contentWidth,
                                  decoration: BoxDecoration(
                                    color: _surfaceDark.withValues(alpha: 0.5),
                                    border: Border.all(
                                      color: _borderDark,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.all(32),
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
                                              fontSize: 30,
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
                                      const SizedBox(height: 24),

                                      /// KPI CARDS ROW
                                      _buildKpiCardsRow(),
                                      const SizedBox(height: 32),

                                      /// INVESTMENT ALLOCATION SECTION
                                      _buildInvestmentAllocationSection(),
                                      const SizedBox(height: 32),

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
    final kpiData = [
      {
        'label': 'START OF INVESTMENT',
        'value': _formatDate(_startOfInvestment),
      },
      {
        'label': 'NUMBER OF HOG BATCH',
        'value': _batchCount.toString(),
      },
      {
        'label': 'TOTAL CURRENT INVESTMENT',
        'value': _formatCurrency(_totalCapital),
      },
      {
        'label': 'NUMBER OF MORTALITY',
        'value': _mortalityCount.toString(),
      },
    ];
    const cardWidth = 320.0;
    const spacing = 16.0;
    final totalWidth = kpiData.length * cardWidth + (kpiData.length - 1) * spacing;

    return LayoutBuilder(
      builder: (context, constraints) {
        final groupWidth = totalWidth <= constraints.maxWidth ? totalWidth : constraints.maxWidth;
        return Center(
          child: SizedBox(
            width: groupWidth,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  kpiData.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(
                      right: index < kpiData.length - 1 ? spacing : 0,
                    ),
                    child: SizedBox(
                        width: cardWidth,
                        child: _buildKpiCard(
                          label: kpiData[index]['label'] as String,
                          value: kpiData[index]['value'] as String,
                        )),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Individual KPI Card
  Widget _buildKpiCard({required String label, required String value}) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _mutedDark,
              letterSpacing: 0.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  /// INVESTMENT ALLOCATION SECTION — now driven by live Supabase data
  Widget _buildInvestmentAllocationSection() {
    final fatteningPercent = _formatPercent(_fatteningCapital, _totalCapital);
    final sowPercent = _formatPercent(_sowCapital, _totalCapital);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1100;
        final cardWidth = isDesktop ? (constraints.maxWidth - 104) / 2 : 420.0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
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
                  Text(
                    'INVESTMENT ALLOCATION',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    'Total: ${_formatCurrency(_totalCapital)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _mutedDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_activeRaisers} active raiser${_activeRaisers == 1 ? '' : 's'}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _mutedDark,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 24,
                  runSpacing: 16,
                  children: [
                    _buildAllocationCard(
                      title: 'FATTENING',
                      percentage: fatteningPercent,
                      amount: _formatCurrency(_fatteningCapital),
                      width: cardWidth,
                    ),
                    _buildAllocationCard(
                      title: 'SOW',
                      percentage: sowPercent,
                      amount: _formatCurrency(_sowCapital),
                      width: cardWidth,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Individual Allocation Card with Top Border Accent
  Widget _buildAllocationCard({
    required String title,
    required String percentage,
    required String amount,
    required double width,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Card Content
          Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _mutedDark,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  percentage,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  amount,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ACTIVE HOG RAISERS PROGRESS SECTION - Displays progress map below investment allocation
  Widget _buildActiveRaisersSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
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
                        Text(
                          'Raiser - $name',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
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
                    _buildLifecycleMap(currentStage.toString()),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLifecycleMap(String currentStage) {
    final List<String> lifecycleStages = [
      'Booster',
      'Pre-Starter',
      'Starter',
      'Grower',
      'Finisher',
      'Selling'
    ];
    final activeIndex = lifecycleStages.indexWhere((stage) => stage.toLowerCase() == currentStage.toLowerCase());
    final normalizedIndex = activeIndex < 0 ? 0 : activeIndex;

    return Row(
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
          bgColor = const Color(0xFFF97316);
          fgColor = Colors.white;
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
                radius: 22,
                backgroundColor: bgColor,
                child: Icon(icon, size: 22, color: fgColor),
              ),
              const SizedBox(height: 10),
              Text(
                stage,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
