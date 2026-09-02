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
      // 1. Load active raisers
      final raisersRes = await _supabase
          .from('hog_raisers')
          .select('hog_raiser_id, name, pig_type, status, account_status, lifecycle_stage')
          .or('account_status.ilike.active,account_status.ilike.approved')
          .order('name', ascending: true);

      // 2. Load investment records to compute Admin Initial Capital & batch count
      final invRecordsRes = await _supabase
          .from('investment_records')
          .select('hog_raiser_id, id, initial_capital, hog_type, stage, investment_date')
          .order('investment_date', ascending: false);

      final invList = (invRecordsRes as List? ?? []);
      double calculatedInitialCapital = 0;
      double calculatedFatteningInitialCapital = 0;
      double calculatedSowInitialCapital = 0;
      final Map<String, String> raiserInvestmentTypeMap = {};

      for (var inv in invList) {
        if (inv is! Map) continue;
        final rawCap = inv['initial_capital'];
        final amt = rawCap is num
            ? rawCap.toDouble()
            : double.tryParse(rawCap?.toString() ?? '0') ?? 0;
        calculatedInitialCapital += amt;

        final ht = (inv['hog_type'] ?? '').toString().toLowerCase();
        if (ht.contains('sow') || ht.contains('inahin')) {
          calculatedSowInitialCapital += amt;
        } else {
          calculatedFatteningInitialCapital += amt;
        }

        final rId = inv['hog_raiser_id']?.toString() ?? '';
        final rawHt = (inv['hog_type'] ?? '').toString().trim();
        if (rId.isNotEmpty && rawHt.isNotEmpty && !raiserInvestmentTypeMap.containsKey(rId)) {
          raiserInvestmentTypeMap[rId] = rawHt;
        }
      }

      // 3. Load product prices to price stock requests accurately
      final Map<String, double> productPriceMap = {};
      try {
        final productsRes = await _supabase
            .from('inventory_products')
            .select('id, name, price, category');
        for (var p in (productsRes as List? ?? [])) {
          if (p is! Map) continue;
          final pName = (p['name'] ?? '').toString().trim().toLowerCase();
          final pCat = (p['category'] ?? '').toString().trim().toLowerCase();
          final pPrice = (p['price'] as num?)?.toDouble() ?? 0.0;
          if (pName.isNotEmpty && pPrice > 0) productPriceMap[pName] = pPrice;
          if (pCat.isNotEmpty && pPrice > 0 && !productPriceMap.containsKey(pCat)) {
            productPriceMap[pCat] = pPrice;
          }
        }
      } catch (pErr) {
        debugPrint('Notice loading product prices for dashboard: $pErr');
      }

      const double defaultFeedPrice = 1650.0;
      double calculatedStocksProvided = 0;
      double calculatedFatteningStocks = 0;
      double calculatedSowStocks = 0;

      // 4. Load approved stock requests (Stocks provided for Hog Raisers)
      try {
        final stockReqRes = await _supabase
            .from('stock_requests')
            .select('request_id, hog_raiser_id, category, quantity, feed_type, status')
            .eq('status', 'approved');

        for (var req in (stockReqRes as List? ?? [])) {
          if (req is! Map) continue;
          final qty = (req['quantity'] as num?)?.toDouble() ?? 1.0;
          final fType = (req['feed_type'] ?? '').toString().trim().toLowerCase();
          final cat = (req['category'] ?? '').toString().trim().toLowerCase();
          final rId = (req['hog_raiser_id'] ?? '').toString();

          final unitPrice = productPriceMap[fType] ??
              productPriceMap[cat] ??
              defaultFeedPrice;

          final totalReqValue = qty * unitPrice;
          calculatedStocksProvided += totalReqValue;

          final raiserType = (raiserInvestmentTypeMap[rId] ?? '').toLowerCase();
          if (raiserType.contains('sow') || raiserType.contains('inahin')) {
            calculatedSowStocks += totalReqValue;
          } else {
            calculatedFatteningStocks += totalReqValue;
          }
        }
      } catch (sErr) {
        debugPrint('Notice loading stock requests for dashboard: $sErr');
      }

      // 5. Also include sales marked as raiser_distribution if any
      try {
        final distSalesRes = await _supabase
            .from('sales')
            .select('total_amount, hog_raiser_id, type')
            .eq('type', 'raiser_distribution');

        for (var s in (distSalesRes as List? ?? [])) {
          if (s is! Map) continue;
          final amt = (s['total_amount'] as num?)?.toDouble() ?? 0.0;
          final rId = (s['hog_raiser_id'] ?? '').toString();
          calculatedStocksProvided += amt;
          final raiserType = (raiserInvestmentTypeMap[rId] ?? '').toLowerCase();
          if (raiserType.contains('sow') || raiserType.contains('inahin')) {
            calculatedSowStocks += amt;
          } else {
            calculatedFatteningStocks += amt;
          }
        }
      } catch (salesErr) {
        debugPrint('Notice loading distribution sales for dashboard: $salesErr');
      }

      final double calculatedTotalCapital = calculatedInitialCapital + calculatedStocksProvided;
      final double calculatedFatteningCapital = calculatedFatteningInitialCapital + calculatedFatteningStocks;
      final double calculatedSowCapital = calculatedSowInitialCapital + calculatedSowStocks;

      if (mounted) {
        final list = (raisersRes as List? ?? []).whereType<Map>().map((r) {
          final copy = Map<String, dynamic>.from(r);
          final idStr = (copy['hog_raiser_id'] ?? '').toString();
          String rawType = (copy['pig_type'] ?? '').toString().trim();
          if ((rawType.isEmpty || rawType.toUpperCase() == 'N/A') && raiserInvestmentTypeMap.containsKey(idStr)) {
            rawType = raiserInvestmentTypeMap[idStr]!;
          }

          final cleanParts = rawType
              .split(RegExp(r'[,;]'))
              .map((p) => p.trim())
              .where((p) =>
                  p.isNotEmpty &&
                  p.toUpperCase() != 'N/A' &&
                  p.toLowerCase() != 'null' &&
                  p.toUpperCase() != 'NONE' &&
                  p.toUpperCase() != 'UNASSIGNED')
              .map((s) {
                final l = s.toLowerCase();
                if (l.contains('sow') || l.contains('breed')) return 'Sow';
                if (l.contains('fatten')) return 'Fattening';
                return s;
              })
              .toSet()
              .toList();

          final cleanedType = cleanParts.isEmpty ? 'N/A' : cleanParts.join(', ');
          copy['pig_type'] = cleanedType;

          return copy;
        }).toList();

        setState(() {
          _activeRaisers = list.length;
          _batchCount = invList.length; // strictly admin batch investments (partner investor excluded)
          _totalCapital = calculatedTotalCapital;
          _fatteningCapital = calculatedFatteningCapital;
          _sowCapital = calculatedSowCapital;
          _activeRaisersList = list;
        });
      }
    } catch (e) {
      debugPrint('Notice loading dashboard data: $e. Using fallback...');
      await _loadDashboardFallback();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Fallback: query each table individually if needed
  Future<void> _loadDashboardFallback() async {
    try {
      final results = await Future.wait([
        _supabase
            .from('hog_raisers')
            .select('hog_raiser_id')
            .or('account_status.ilike.active,account_status.ilike.approved'),
        _supabase.from('investment_records').select('id'),
        _supabase.from('investment_records').select('hog_raiser_id, investment_date, initial_capital, hog_type'),
        _supabase.from('hogs').select('hog_id').eq('status', 'dead'),
        _supabase
            .from('hog_raisers')
            .select('hog_raiser_id, name, pig_type, status, account_status, lifecycle_stage')
            .or('account_status.ilike.active,account_status.ilike.approved')
            .order('name', ascending: true),
      ]);

      if (!mounted) return;

      final raisers = results[0] as List;
      final batches = results[1] as List;
      final investmentRows = results[2] as List;
      final activeRaisers = (results[4] as List).cast<Map<String, dynamic>>();

      double initialCapital = 0;
      double fatteningInitialCapital = 0;
      double sowInitialCapital = 0;
      final Map<String, String> raiserInvestmentTypeMap = {};

      for (final row in investmentRows) {
        if (row is! Map) continue;
        final rawCap = row['initial_capital'];
        final amt = rawCap is num
            ? rawCap.toDouble()
            : double.tryParse(rawCap?.toString() ?? '0') ?? 0;
        initialCapital += amt;
        final ht = (row['hog_type'] ?? '').toString().toLowerCase();
        if (ht.contains('sow') || ht.contains('inahin')) {
          sowInitialCapital += amt;
        } else {
          fatteningInitialCapital += amt;
        }

        final rId = row['hog_raiser_id']?.toString() ?? '';
        final rawHt = (row['hog_type'] ?? '').toString().trim();
        if (rId.isNotEmpty && rawHt.isNotEmpty && !raiserInvestmentTypeMap.containsKey(rId)) {
          raiserInvestmentTypeMap[rId] = rawHt;
        }
      }

      double stocksProvided = 0;
      double fatteningStocks = 0;
      double sowStocks = 0;

      try {
        final stockReqRes = await _supabase
            .from('stock_requests')
            .select('hog_raiser_id, category, quantity, feed_type, status')
            .eq('status', 'approved');

        for (var req in (stockReqRes as List? ?? [])) {
          if (req is! Map) continue;
          final qty = (req['quantity'] as num?)?.toDouble() ?? 1.0;
          final val = qty * 1650.0;
          stocksProvided += val;
          final rId = (req['hog_raiser_id'] ?? '').toString();
          final raiserType = (raiserInvestmentTypeMap[rId] ?? '').toLowerCase();
          if (raiserType.contains('sow') || raiserType.contains('inahin')) {
            sowStocks += val;
          } else {
            fatteningStocks += val;
          }
        }
      } catch (_) {}

      final double totalCapital = initialCapital + stocksProvided;
      final double fatteningCapital = fatteningInitialCapital + fatteningStocks;
      final double sowCapital = sowInitialCapital + sowStocks;

      final cleanedActiveRaisers = activeRaisers.map((r) {
        final copy = Map<String, dynamic>.from(r);
        final rawType = (copy['pig_type'] ?? '').toString().trim();
        final cleanParts = rawType
            .split(RegExp(r'[,;]'))
            .map((p) => p.trim())
            .where((p) =>
                p.isNotEmpty &&
                p.toUpperCase() != 'N/A' &&
                p.toLowerCase() != 'null' &&
                p.toUpperCase() != 'NONE' &&
                p.toUpperCase() != 'UNASSIGNED')
            .map((s) {
              final l = s.toLowerCase();
              if (l.contains('sow') || l.contains('breed')) return 'Sow';
              if (l.contains('fatten')) return 'Fattening';
              return s;
            })
            .toSet()
            .toList();
        final cleanedType = cleanParts.isEmpty ? 'N/A' : cleanParts.join(', ');
        copy['pig_type'] = cleanedType;
        return copy;
      }).toList();

      setState(() {
        _activeRaisers = raisers.length;
        _batchCount = batches.length; // strictly admin batches
        _totalCapital = totalCapital;
        _fatteningCapital = fatteningCapital;
        _sowCapital = sowCapital;
        _activeRaisersList = cleanedActiveRaisers;
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

  /// KPI CARDS ROW — driven by live Supabase data (Admin Capital + Stocks Provided)
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

    final isVeryNarrow = MediaQuery.of(context).size.width < 500;

    if (isVeryNarrow) {
      return Column(
        children: [
          _buildKpiCard(
            label: kpiData[0]['label'] as String,
            value: kpiData[0]['value'] as String,
            isMobile: isMobile,
          ),
          const SizedBox(height: 12),
          _buildKpiCard(
            label: kpiData[1]['label'] as String,
            value: kpiData[1]['value'] as String,
            isMobile: isMobile,
          ),
        ],
      );
    }

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
      width: double.infinity,
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

  /// INVESTMENT ALLOCATION SECTION — driven by live Admin investment + stocks data
  Widget _buildInvestmentAllocationSection() {
    final isMobile = Responsive.isMobile(context);
    final isVeryNarrow = MediaQuery.of(context).size.width < 500;

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
          if (isVeryNarrow)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAllocationCard(
                  title: 'FATTENING',
                  amount: _formatCurrency(_fatteningCapital),
                  isMobile: isMobile,
                ),
                const SizedBox(height: 12),
                _buildAllocationCard(
                  title: 'SOW',
                  amount: _formatCurrency(_sowCapital),
                  isMobile: isMobile,
                ),
              ],
            )
          else
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
      width: width ?? double.infinity,
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
                final name = (raiser['name'] ?? 'Hog Raiser').toString();
                final rawPigType = (raiser['pig_type'] ?? '').toString().trim();
                final cleanList = rawPigType
                    .split(RegExp(r'[,;]'))
                    .map((s) => s.trim())
                    .where((s) =>
                        s.isNotEmpty &&
                        s.toUpperCase() != 'N/A' &&
                        s.toLowerCase() != 'null' &&
                        s.toUpperCase() != 'NONE' &&
                        s.toUpperCase() != 'UNASSIGNED')
                    .map((s) {
                      final l = s.toLowerCase();
                      if (l.contains('sow') || l.contains('breed')) return 'SOW';
                      if (l.contains('fatten')) return 'FATTENING';
                      return s.toUpperCase();
                    })
                    .toSet()
                    .toList();
                final bool isUnassigned = cleanList.isEmpty;
                final String displayBadge = isUnassigned ? 'UNASSIGNED' : cleanList.join(', ');
                final currentStage = isUnassigned ? 'Unassigned' : (raiser['lifecycle_stage'] ?? 'Booster').toString();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            name,
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
                            color: isUnassigned
                                ? (_isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
                                : (_isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isUnassigned
                                  ? (_isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))
                                  : (_isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            displayBadge,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isUnassigned
                                  ? (_isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
                                  : (_isDark ? Colors.white : const Color(0xFF18314F)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildLifecycleMap(currentStage, isUnassigned ? 'Fattening' : pigTypeString(rawPigType), isUnassigned: isUnassigned),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  String pigTypeString(String raw) {
    if (raw.toLowerCase().contains('sow')) return 'sow';
    return 'fattening';
  }

  Widget _buildLifecycleMap(String currentStage, String pigType, {bool isUnassigned = false}) {
    final List<String> lifecycleStages = pigType.toLowerCase() == 'sow'
        ? ['Booster', 'Pre-Starter', 'Starter', 'Grower', 'Breeder', 'Lactation']
        : ['Booster', 'Pre-Starter', 'Starter', 'Grower', 'Finisher', 'Selling'];
    final activeIndex = isUnassigned
        ? -1
        : lifecycleStages.indexWhere((stage) => stage.toLowerCase() == currentStage.toLowerCase());
    final normalizedIndex = isUnassigned ? -1 : (activeIndex < 0 ? 0 : activeIndex);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        Widget buildStepContent(int index) {
          final stage = lifecycleStages[index];
          final isDone = !isUnassigned && index < normalizedIndex;
          final isCurrent = !isUnassigned && index == normalizedIndex;

          Color bgColor;
          Color fgColor;
          IconData icon;
          if (isDone) {
            bgColor = const Color(0xFF10B981);
            fgColor = Colors.white;
            icon = Icons.check;
          } else if (isCurrent) {
            bgColor = _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary;
            fgColor = _isDark ? const Color(0xFF0F172A) : Colors.white;
            icon = Icons.priority_high_rounded;
          } else {
            bgColor = _isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
            fgColor = _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
            icon = isUnassigned ? Icons.lock_outline_rounded : Icons.radio_button_unchecked;
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(
                          color: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                          width: 2,
                        )
                      : null,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: (_isDark ? Colors.white : PiggyTrunkTheme.ptPrimary).withValues(alpha: 0.25),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(icon, size: 20, color: fgColor),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                stage,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: isCurrent ? FontWeight.w800 : (isDone ? FontWeight.w700 : FontWeight.w600),
                  color: isCurrent
                      ? (_isDark ? Colors.white : PiggyTrunkTheme.ptPrimary)
                      : (isDone ? _textDark : _mutedDark),
                ),
              ),
            ],
          );
        }

        if (isMobile) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(lifecycleStages.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(right: index == lifecycleStages.length - 1 ? 0 : 20),
                  child: SizedBox(
                    width: 76,
                    child: buildStepContent(index),
                  ),
                );
              }),
            ),
          );
        }

        // On Desktop: Evenly spaced across the card
        return Row(
          children: List.generate(lifecycleStages.length, (index) {
            return Expanded(
              child: Center(
                child: buildStepContent(index),
              ),
            );
          }),
        );
      },
    );
  }
}
