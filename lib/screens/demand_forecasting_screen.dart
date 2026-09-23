import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/forecasting_model.dart';
import '../models/product_model.dart';
import '../services/forecasting_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_toast.dart';
import '../utils/responsive.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';
import '../widgets/inventory/product_restock_dialog.dart';
import '../widgets/common/shimmer_loading.dart';
import 'pos_screen.dart';

enum SalesForecastViewTab {
  topSelling,
  historicalSales,
  forecastSummary,
  financialPlanning,
}

class DemandForecastingScreen extends StatefulWidget {
  final bool isMobileEmbedded;

  const DemandForecastingScreen({
    super.key,
    this.isMobileEmbedded = false,
  });

  @override
  State<DemandForecastingScreen> createState() => _DemandForecastingScreenState();
}

class _DemandForecastingScreenState extends State<DemandForecastingScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final ForecastingService _forecastingService;

  List<ProductForecast> _forecasts = [];
  List<Product> _allProducts = [];
  bool _isLoading = true;

  // Active View Tab (Top-Selling Items, Historical Sales, Forecast, Financial Planning)
  SalesForecastViewTab _activeTab = SalesForecastViewTab.topSelling;

  // Practical filters
  int _selectedHorizonDays = 7;
  String _salesFilter = 'All'; // 'All', 'Top Selling', 'Low Selling'
  final TextEditingController _searchCtrl = TextEditingController();

  static const List<String> _salesFilterOptions = <String>[
    'All Products',
    'Top Selling',
    'Low Selling',
  ];

  // System Theme Helpers (identical to InventoryScreen)
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgDark => _isDark ? PiggyTrunkTheme.ptBgDark : PiggyTrunkTheme.ptBg;
  Color get _panelStart => _isDark ? const Color(0xFF1A2940) : Colors.white;
  Color get _panelEnd => _isDark ? const Color(0xFF0F1C2F) : Colors.white;
  Color get _panelBorder => _isDark ? const Color(0xFF2A3E5B) : const Color(0xFFC9D8EC);
  Color get _cardBg => _isDark ? const Color(0xFF132238) : Colors.white;
  Color get _cardBorder => _isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
  Color get _titleColor => _isDark ? Colors.white : const Color(0xFF18314F);
  Color get _mutedColor => _isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);
  Color get _fieldBg => _isDark ? const Color(0xFF1A2B44) : const Color(0xFFF5F8FE);
  Color get _fieldText => _isDark ? Colors.white : const Color(0xFF18314F);
  Color get _fieldFocus => _isDark ? const Color(0xFF88A7CE) : const Color(0xFF315C8F);

  @override
  void initState() {
    super.initState();
    _forecastingService = ForecastingService(supabase: _supabase);
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch raw products for restock dialog usage
      final rawProds = await _supabase
          .from('inventory_products')
          .select()
          .eq('is_archived', false)
          .order('name', ascending: true);
      _allProducts = (rawProds as List).map((r) => Product.fromJson(r)).toList();

      // 2. Compute forecasts (uses optimal adaptive exponential smoothing)
      final forecasts = await _forecastingService.calculateForecasts(
        modelType: ForecastModelType.exponentialSmoothing,
        alpha: 0.30,
        horizonDays: _selectedHorizonDays,
      );

      if (!mounted) return;
      setState(() {
        _forecasts = forecasts;
      });
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to compute forecasts: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Performance classification helpers
  double get _medianSoldUnits {
    if (_forecasts.isEmpty) return 0;
    final values = _forecasts.map((f) => f.calculatedTotalSold.toDouble()).toList()..sort();
    final mid = values.length ~/ 2;
    return values.length % 2 == 1 ? values[mid] : (values[mid - 1] + values[mid]) / 2.0;
  }

  bool _isTopSelling(ProductForecast f) {
    if (_forecasts.isEmpty) return false;
    if (_forecasts.length <= 2) {
      final maxSold = _forecasts.map((p) => p.calculatedTotalSold).reduce(max);
      return f.calculatedTotalSold == maxSold && f.calculatedTotalSold > 0;
    }
    final median = _medianSoldUnits;
    return f.calculatedTotalSold > median || (f.calculatedTotalSold == median && f.averageDailySales >= 1.5);
  }

  bool _isLowSelling(ProductForecast f) {
    if (_forecasts.isEmpty) return false;
    if (_forecasts.length <= 2) {
      final minSold = _forecasts.map((p) => p.calculatedTotalSold).reduce(min);
      return f.calculatedTotalSold == minSold;
    }
    final median = _medianSoldUnits;
    return f.calculatedTotalSold < median || (f.calculatedTotalSold == 0);
  }

  List<ProductForecast> get _allRankedForecasts {
    final list = List<ProductForecast>.from(_forecasts);
    list.sort((a, b) {
      final cmp = b.calculatedTotalSold.compareTo(a.calculatedTotalSold);
      if (cmp != 0) return cmp;
      return b.calculatedTotalRevenue.compareTo(a.calculatedTotalRevenue);
    });
    return list;
  }

  int _getSalesRank(ProductForecast f) {
    final ranked = _allRankedForecasts;
    final index = ranked.indexWhere((p) => p.productId == f.productId);
    return index >= 0 ? index + 1 : 1;
  }

  List<String> get _activeTabHeaders {
    switch (_activeTab) {
      case SalesForecastViewTab.topSelling:
        return const [
          'RANK',
          'PRODUCT NAME',
          'CATEGORY',
          'UNITS SOLD',
          'TOTAL SALES / REVENUE',
        ];
      case SalesForecastViewTab.historicalSales:
        return const [
          'PRODUCT / ITEM',
          'DAILY SALES',
          'WEEKLY / MONTHLY',
          'UNITS SOLD',
          'REVENUE PER PRODUCT',
        ];
      case SalesForecastViewTab.forecastSummary:
        return const [
          'PRODUCT / ITEM',
          'FORECASTED DEMAND',
          'EXPECTED NEED',
          'SUGGESTED REORDER',
          'FORECAST PERIOD',
        ];
      case SalesForecastViewTab.financialPlanning:
        return const [
          'PRODUCT / ITEM',
          'HISTORICAL REVENUE',
          'EST. FUTURE SALES',
          'PURCHASING REQ.',
          'EXPECTED SPENDING',
        ];
    }
  }

  List<int> get _activeTabFlexes {
    switch (_activeTab) {
      case SalesForecastViewTab.topSelling:
        return const [1, 3, 2, 2, 2];
      case SalesForecastViewTab.historicalSales:
      case SalesForecastViewTab.forecastSummary:
      case SalesForecastViewTab.financialPlanning:
        return const [3, 2, 2, 2, 2];
    }
  }

  String get _activeTabTitle {
    switch (_activeTab) {
      case SalesForecastViewTab.topSelling:
        return 'Top-Selling Items';
      case SalesForecastViewTab.historicalSales:
        return 'Historical Sales Summary';
      case SalesForecastViewTab.forecastSummary:
        return 'Forecast Summary';
      case SalesForecastViewTab.financialPlanning:
        return 'Financial Planning Summary';
    }
  }

  String get _activeTabSubtitle {
    switch (_activeTab) {
      case SalesForecastViewTab.topSelling:
        return 'Product sales ranking, units sold, and total revenue performance';
      case SalesForecastViewTab.historicalSales:
        return 'Daily, weekly, and monthly sales volume and revenue per product';
      case SalesForecastViewTab.forecastSummary:
        return 'Demand projections, expected units needed, and suggested restock quantities';
      case SalesForecastViewTab.financialPlanning:
        return 'Historical revenue, estimated future sales, and purchasing capital requirements';
    }
  }

  List<ProductForecast> get _filteredForecasts {
    final q = _searchCtrl.text.trim().toLowerCase();
    var list = _forecasts.where((f) {
      if (q.isNotEmpty &&
          !f.productName.toLowerCase().contains(q) &&
          !f.category.toLowerCase().contains(q)) {
        return false;
      }
      if (_salesFilter == 'Top Selling') {
        return _isTopSelling(f);
      } else if (_salesFilter == 'Low Selling') {
        return _isLowSelling(f);
      }
      return true;
    }).toList();

    // Sort based on active tab and filter
    if (_activeTab == SalesForecastViewTab.topSelling) {
      if (_salesFilter == 'Low Selling') {
        list.sort((a, b) => a.calculatedTotalSold.compareTo(b.calculatedTotalSold));
      } else {
        list.sort((a, b) => b.calculatedTotalSold.compareTo(a.calculatedTotalSold));
      }
    } else if (_activeTab == SalesForecastViewTab.historicalSales) {
      if (_salesFilter == 'Low Selling') {
        list.sort((a, b) => a.calculatedTotalRevenue.compareTo(b.calculatedTotalRevenue));
      } else {
        list.sort((a, b) => b.calculatedTotalRevenue.compareTo(a.calculatedTotalRevenue));
      }
    } else if (_activeTab == SalesForecastViewTab.forecastSummary) {
      if (_salesFilter == 'Low Selling') {
        list.sort((a, b) => a.predictedDemand.compareTo(b.predictedDemand));
      } else {
        list.sort((a, b) => b.predictedDemand.compareTo(a.predictedDemand));
      }
    } else if (_activeTab == SalesForecastViewTab.financialPlanning) {
      if (_salesFilter == 'Low Selling') {
        list.sort((a, b) => a.calculatedTotalRevenue.compareTo(b.calculatedTotalRevenue));
      } else {
        list.sort((a, b) => (b.predictedDemand * b.unitPrice).compareTo(a.predictedDemand * a.unitPrice));
      }
    }

    return list;
  }

  // Summary Metrics (2 KPI Cards)
  double get _totalMonthlySales =>
      _forecasts.fold(0.0, (sum, f) => sum + f.calculatedTotalRevenue);

  int get _totalMonthlyUnits =>
      _forecasts.fold(0, (sum, f) => sum + f.calculatedTotalSold);

  double get _estimatedPurchasingCapital {
    return _forecasts.fold(0.0, (sum, f) {
      final qty = f.recommendedReorderQty > 0
          ? f.recommendedReorderQty
          : f.predictedDemand.ceil();
      return sum + (qty * f.unitPrice);
    });
  }

  String _formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '₱$intPart.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMobileEmbedded) {
      return PopScope(
        canPop: true,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: _bgDark,
          body: SafeArea(
            child: _buildMainContent(),
          ),
        ),
      );
    }

    final isSmall = Responsive.isSmallScreen(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushReplacementNamed('/pos');
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _bgDark,
        drawer: isSmall
            ? Drawer(
                child: AdminSidebar(
                  currentRoute: '/pos',
                  isDrawer: true,
                  onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
                ),
              )
            : null,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScreenTopBar(),
            Expanded(
              child: Row(
                children: [
                  if (!isSmall)
                    AdminSidebar(
                      currentRoute: '/pos',
                      onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
                    ),
                  Expanded(child: _buildMainContent()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final isMobile = Responsive.isMobile(context) || widget.isMobileEmbedded;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = constraints.maxWidth > 1350
              ? 1350.0
              : double.infinity;
          return Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: contentWidth,
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
                horizontal: isMobile ? 14 : 26,
                vertical: isMobile ? 16 : 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Screen Header (System Aligned)
                  _buildHeader(isMobile),
                  const SizedBox(height: 24),

                  if (_isLoading) ...[
                    // 2 Practical KPI Summary Cards Skeleton
                    _buildKpiSkeletonSection(isMobile),
                    const SizedBox(height: 24),

                    // Horizon Selector & Filter Controls
                    _buildControlsCard(isMobile),
                    const SizedBox(height: 24),

                    // Sales Forecast Summary Table Skeleton
                    TableSkeletonLoader(
                      isDark: _isDark,
                      minWidth: 780,
                      cardBg: _cardBg,
                      cardBorder: _cardBorder,
                      headerBg: _isDark ? const Color(0xFF1B2E48) : const Color(0xFFEDF4FC),
                      headers: _activeTabHeaders,
                      columnFlexes: _activeTabFlexes,
                      rowCount: 6,
                      borderRadius: 16,
                    ),
                  ] else ...[
                    // 2 Practical KPI Summary Cards
                    _buildKPISection(isMobile),
                    const SizedBox(height: 24),

                    // Horizon Selector & Filter Controls
                    _buildControlsCard(isMobile),
                    const SizedBox(height: 24),

                    // Sales Forecast Summary Matrix Card
                    _buildForecastMatrixCard(isMobile),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Screen Header ---
  Widget _buildHeader(bool isMobile) {
    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildBackButton(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sales Forecast Summary',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _titleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Predict product sales & financial planning',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: _mutedColor,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildHeaderActionButtons(),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildBackButton(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sales Forecast Summary',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: _titleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Predict product sales demand, top-selling items & financial planning based on POS history',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: _mutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _buildHeaderActionButtons(),
            ],
          );
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const POSScreen(),
              settings: const RouteSettings(name: '/pos'),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Tooltip(
        message: 'Back to POS',
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _fieldBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _cardBorder, width: 1.2),
          ),
          child: Icon(Icons.arrow_back_rounded, size: 20, color: _titleColor),
        ),
      ),
    );
  }

  Widget _buildHeaderActionButtons() {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _loadData,
      icon: _isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
              ),
            )
          : Icon(
              Icons.refresh_rounded,
              size: 17,
              color: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
            ),
      label: Text(
        'Refresh',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: _isDark ? const Color(0xFF1E2F47) : const Color(0xFFEEF4FD),
        side: BorderSide(
          color: _isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3),
          width: 1.2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- 2 Practical KPI Summary Cards ---
  Widget _buildKPISection(bool isMobile) {
    final leftCard = _buildKPICard(
      title: 'Total Monthly Sales',
      value: _formatCurrency(_totalMonthlySales),
      subtitle: '$_totalMonthlyUnits total units sold this month',
      icon: Icons.payments_rounded,
      color: const Color(0xFF10B981),
      badgeText: 'MONTHLY TOTAL',
      isMobile: isMobile,
    );

    final rightCard = _buildKPICard(
      title: 'Estimated Purchasing Capital',
      value: _formatCurrency(_estimatedPurchasingCapital),
      subtitle: 'Estimated budget to replenish inventory based on demand',
      icon: Icons.account_balance_wallet_outlined,
      color: _isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary,
      badgeText: 'RESTOCK CAPITAL',
      isMobile: isMobile,
    );

    if (isMobile) {
      return Column(
        children: [
          leftCard,
          const SizedBox(height: 10),
          rightCard,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: leftCard),
        const SizedBox(width: 14),
        Expanded(child: rightCard),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String badgeText,
    bool isMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 18,
        vertical: isMobile ? 10 : 18,
      ),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        border: Border.all(color: _cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 5 : 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: color, size: isMobile ? 15 : 20),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 5 : 6,
                    vertical: isMobile ? 2 : 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 7.5 : 10,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 6 : 14),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 16 : 22,
              fontWeight: FontWeight.w800,
              color: _titleColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 11 : 13,
              fontWeight: FontWeight.w700,
              color: _titleColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 9.5 : 11.5,
              color: _mutedColor,
            ),
          ),
        ],
      ),
    );
  }

  // --- Horizon & Filter Controls ---
  Widget _buildControlsCard(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1.2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isStacked = isMobile || constraints.maxWidth < 720;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Horizon Selector (Expands evenly across available width)
              Row(
                children: [
                  Text(
                    'Forecast Period:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildHorizonPill(7, 'Next 7 Days (Weekly)')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildHorizonPill(14, 'Next 14 Days (Bi-weekly)')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildHorizonPill(30, 'Next 30 Days (Monthly)')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: _cardBorder, height: 1),
              const SizedBox(height: 16),

              // Row 2: Search & Performance Filters (All Products, Top Selling, Low Selling)
              if (!isStacked)
                Row(
                  children: [
                    // Search Input (Expands to fill remaining width)
                    Expanded(
                      child: _buildSearchTextField(),
                    ),
                    const SizedBox(width: 12),

                    // Sales Performance Chips
                    Row(
                      children: _salesFilterOptions
                          .map((f) => _buildSalesFilterChip(f))
                          .toList(),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Input
                    _buildSearchTextField(),
                    const SizedBox(height: 12),

                    // Sales Performance Chips in Horizontal Scroll
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _salesFilterOptions
                            .map((f) => _buildSalesFilterChip(f))
                            .toList(),
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  IconData _getSalesFilterIcon(String label) {
    if (label == 'Top Selling') return Icons.trending_up_rounded;
    if (label == 'Low Selling') return Icons.trending_down_rounded;
    return Icons.apps_rounded;
  }

  Widget _buildSearchTextField() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.plusJakartaSans(color: _fieldText, fontSize: 13.5),
      decoration: InputDecoration(
        hintText: 'Search products by name...',
        hintStyle: GoogleFonts.plusJakartaSans(color: _mutedColor, fontSize: 13.5),
        prefixIcon: Icon(Icons.search_rounded, color: _mutedColor, size: 20),
        filled: true,
        fillColor: _fieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _fieldFocus, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildHorizonPill(int days, String label) {
    final isSelected = _selectedHorizonDays == days;
    return InkWell(
      onTap: () {
        setState(() => _selectedHorizonDays = days);
        _loadData();
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (_isDark ? Colors.white : PiggyTrunkTheme.ptPrimary)
              : (_isDark ? const Color(0xFF1E2F47) : const Color(0xFFEEF4FD)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.transparent : _cardBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? (_isDark ? PiggyTrunkTheme.ptPrimary : Colors.white)
                : _mutedColor,
          ),
        ),
      ),
    );
  }

  Widget _buildSalesFilterChip(String label) {
    final icon = _getSalesFilterIcon(label);
    final isSelected = (_salesFilter == label) ||
        (label == 'All Products' && _salesFilter == 'All');
    final Color activeColor = label == 'Top Selling'
        ? const Color(0xFF10B981)
        : (label == 'Low Selling'
            ? const Color(0xFFF59E0B)
            : (_isDark ? Colors.white : PiggyTrunkTheme.ptPrimary));

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() => _salesFilter = (label == 'All Products' ? 'All' : label));
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (_isDark ? const Color(0xFF1E2F47) : const Color(0xFFEEF4FD))
                : (_isDark ? const Color(0xFF1A2B44) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? activeColor : _cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? activeColor : _mutedColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: isSelected
                      ? (_isDark ? Colors.white : PiggyTrunkTheme.ptPrimary)
                      : _mutedColor,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesPerformanceBadge(ProductForecast f) {
    if (_isTopSelling(f)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.trending_up_rounded, size: 12, color: Color(0xFF10B981)),
            const SizedBox(width: 4),
            Text(
              'TOP SELLER',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF10B981),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    } else if (_isLowSelling(f)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.trending_down_rounded, size: 12, color: Color(0xFFF59E0B)),
            const SizedBox(width: 4),
            Text(
              'LOW SELLER',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFF59E0B),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFF60A5FA).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.remove_rounded, size: 12, color: Color(0xFF60A5FA)),
            const SizedBox(width: 4),
            Text(
              'STEADY',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF60A5FA),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTabBar(bool isMobile) {
    final tabs = [
      (
        tab: SalesForecastViewTab.topSelling,
        label: 'Top-Selling Items',
        icon: Icons.leaderboard_rounded,
      ),
      (
        tab: SalesForecastViewTab.historicalSales,
        label: 'Historical Sales Summary',
        icon: Icons.history_rounded,
      ),
      (
        tab: SalesForecastViewTab.forecastSummary,
        label: 'Forecast Summary',
        icon: Icons.insights_rounded,
      ),
      (
        tab: SalesForecastViewTab.financialPlanning,
        label: 'Financial Planning Summary',
        icon: Icons.account_balance_wallet_outlined,
      ),
    ];

    final buttonWidgets = tabs.map((item) {
      final isSelected = _activeTab == item.tab;
      final Color activeColor = _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary;

      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InkWell(
          onTap: () {
            setState(() {
              _activeTab = item.tab;
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 9 : 10,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? (_isDark ? const Color(0xFF1E2F47) : const Color(0xFFEEF4FD))
                  : (_isDark ? const Color(0xFF132034) : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? activeColor : _cardBorder,
                width: isSelected ? 1.6 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: isMobile ? 16 : 18,
                  color: isSelected ? activeColor : _mutedColor,
                ),
                const SizedBox(width: 8),
                Text(
                  item.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 12.5 : 13.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? (_isDark ? Colors.white : PiggyTrunkTheme.ptPrimary)
                        : _mutedColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: buttonWidgets,
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color bg;
    Color border;
    Color text;

    if (rank == 1) {
      bg = const Color(0xFFFEF3C7);
      border = const Color(0xFFF59E0B);
      text = const Color(0xFFB45309);
    } else if (rank == 2) {
      bg = const Color(0xFFE2E8F0);
      border = const Color(0xFF94A3B8);
      text = const Color(0xFF475569);
    } else if (rank == 3) {
      bg = const Color(0xFFFFEDD5);
      border = const Color(0xFFFB923C);
      text = const Color(0xFFC2410C);
    } else {
      bg = _isDark ? const Color(0xFF1E2F47) : const Color(0xFFF1F5F9);
      border = _cardBorder;
      text = _mutedColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rank == 1)
            const Padding(
              padding: EdgeInsets.only(right: 3),
              child: Icon(Icons.emoji_events_rounded, size: 13, color: Color(0xFFB45309)),
            ),
          Text(
            '#$rank',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  // --- Forecast & Reorder Matrix Card ---
  Widget _buildForecastMatrixCard(bool isMobile) {
    final list = _filteredForecasts;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth > 840 ? constraints.maxWidth : 840.0;

        return Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _activeTabTitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _titleColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _activeTabSubtitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: _mutedColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _fieldBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _cardBorder),
                      ),
                      child: Text(
                        '${list.length} item(s)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _titleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Interactive 4 Buttons Tab Bar
              _buildTabBar(isMobile),

              Divider(color: _cardBorder, height: 1),

              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: _mutedColor.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No products match your current filters.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _titleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (isMobile)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (ctx, i) => Divider(color: _cardBorder, height: 1),
                  itemBuilder: (ctx, idx) {
                    final f = list[idx];
                    return InkWell(
                      onTap: () => _showProductDeepDive(f),
                      hoverColor: _isDark ? const Color(0xFF1E2F48) : const Color(0xFFF8FAFC),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: _buildMobileRow(f),
                      ),
                    );
                  },
                )
              else
                Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: _isDark ? const Color(0xFF1B2E48) : const Color(0xFFEDF4FC),
                              border: Border(bottom: BorderSide(color: _cardBorder, width: 1.2)),
                            ),
                            child: Row(
                              children: [
                                for (int i = 0; i < _activeTabHeaders.length; i++)
                                  Expanded(
                                    flex: _activeTabFlexes[i],
                                    child: Text(_activeTabHeaders[i], style: _tableHeaderStyle),
                                  ),
                              ],
                            ),
                          ),
                          ...List.generate(
                            list.length,
                            (idx) {
                              final f = list[idx];
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: idx == list.length - 1
                                        ? BorderSide.none
                                        : BorderSide(color: _cardBorder.withValues(alpha: 0.5)),
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () => _showProductDeepDive(f),
                                  hoverColor: _isDark ? const Color(0xFF1E2F48) : const Color(0xFFF8FAFC),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    child: _buildDesktopRow(f),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  TextStyle get _tableHeaderStyle => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: _mutedColor,
        letterSpacing: 0.5,
      );

  Widget _buildProductThumbnail(String? imageUrl, {double size = 56, double radius = 10}) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final isAsset = imageUrl.startsWith('assets/');
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _fieldBg,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: _cardBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 1),
          child: isAsset
              ? Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => Center(
                    child: Icon(Icons.inventory_2_outlined, color: _mutedColor, size: size * 0.45),
                  ),
                )
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => Center(
                    child: Icon(Icons.inventory_2_outlined, color: _mutedColor, size: size * 0.45),
                  ),
                ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _cardBorder),
      ),
      child: Center(
        child: Icon(Icons.inventory_2_outlined, color: _mutedColor, size: size * 0.45),
      ),
    );
  }

  Widget _buildDesktopRow(ProductForecast f) {
    switch (_activeTab) {
      case SalesForecastViewTab.topSelling:
        return _buildTopSellingDesktopRow(f);
      case SalesForecastViewTab.historicalSales:
        return _buildHistoricalSalesDesktopRow(f);
      case SalesForecastViewTab.forecastSummary:
        return _buildForecastSummaryDesktopRow(f);
      case SalesForecastViewTab.financialPlanning:
        return _buildFinancialPlanningDesktopRow(f);
    }
  }

  Widget _buildTopSellingDesktopRow(ProductForecast f) {
    final rank = _getSalesRank(f);
    return Row(
      children: [
        // Rank
        Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildRankBadge(rank),
          ),
        ),

        // Product Name
        Expanded(
          flex: 3,
          child: Row(
            children: [
              _buildProductThumbnail(f.imageUrl, size: 44, radius: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.productName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _titleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₱${f.unitPrice.toStringAsFixed(2)} / unit',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: _mutedColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Category
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _fieldBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Text(
                    f.category,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _titleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildSalesPerformanceBadge(f),
              ],
            ),
          ),
        ),

        // Units Sold
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${f.calculatedTotalSold} units',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${f.averageDailySales.toStringAsFixed(1)} units/day avg',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: _mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Total Sales / Revenue
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatCurrency(f.calculatedTotalRevenue),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Total Revenue',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: _mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoricalSalesDesktopRow(ProductForecast f) {
    final dailyRevenue = f.averageDailySales * f.unitPrice;
    final monthlyRevenue = f.averageDailySales * 30 * f.unitPrice;

    return Row(
      children: [
        // Product / Item
        Expanded(
          flex: 3,
          child: Row(
            children: [
              _buildProductThumbnail(f.imageUrl, size: 44, radius: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.productName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _titleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${f.category} • ₱${f.unitPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: _mutedColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Daily Sales
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${f.averageDailySales.toStringAsFixed(1)} units / day',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_formatCurrency(dailyRevenue)} / day',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: _mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Weekly / Monthly
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${(f.averageDailySales * 7).round()} wk • ${(f.averageDailySales * 30).round()} mo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_formatCurrency(monthlyRevenue)} / mo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: _mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Units Sold per Product
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${f.calculatedTotalSold} units',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Recorded sales',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: _mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Revenue per Product
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatCurrency(f.calculatedTotalRevenue),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Total Revenue',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: _mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForecastSummaryDesktopRow(ProductForecast f) {
    final expectedNeeded = (f.predictedDemand + f.safetyStock).round();
    final periodLabel = f.horizonDays <= 7
        ? 'Next Week'
        : (f.horizonDays <= 14 ? 'Next 2 Weeks' : 'Next Month');

    return Row(
      children: [
        // Product / Item
        Expanded(
          flex: 3,
          child: Row(
            children: [
              _buildProductThumbnail(f.imageUrl, size: 44, radius: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.productName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _titleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${f.category} • ₱${f.unitPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: _mutedColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Forecasted Demand for Next Period
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${f.predictedDemand.round()} units',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Projected sales',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: _mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Expected Quantity Needed
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$expectedNeeded units',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Incl. ${f.safetyStock.round()} buffer',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: _mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Suggested Reorder Quantity
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${f.recommendedReorderQty} units',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: f.recommendedReorderQty > 0
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                f.recommendedReorderQty > 0 ? 'Restock suggested' : 'Adequate stock',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: _mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Forecast Period
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF1E2F47) : const Color(0xFFEEF4FD),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    periodLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                    ),
                  ),
                  Text(
                    '${f.horizonDays} days',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: _mutedColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialPlanningDesktopRow(ProductForecast f) {
    final estFutureSales = f.predictedDemand * f.unitPrice;
    final purchasingUnits = f.recommendedReorderQty > 0
        ? f.recommendedReorderQty
        : f.predictedDemand.ceil();
    final expectedSpending = purchasingUnits * f.unitPrice;

    return Row(
      children: [
        // Product / Item
        Expanded(
          flex: 3,
          child: Row(
            children: [
              _buildProductThumbnail(f.imageUrl, size: 44, radius: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.productName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _titleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${f.category} • ₱${f.unitPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: _mutedColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Historical Sales Revenue
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatCurrency(f.calculatedTotalRevenue),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${f.calculatedTotalSold} units sold',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: _mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Estimated Future Sales
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatCurrency(estFutureSales),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Proj. ${f.predictedDemand.round()} units (${f.horizonDays}d)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: _mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Estimated Inventory Purchasing Requirement
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$purchasingUnits units',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Purchasing requirement',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: _mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Expected Inventory Spending
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatCurrency(expectedSpending),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Estimated spending',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: _mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileRow(ProductForecast f) {
    switch (_activeTab) {
      case SalesForecastViewTab.topSelling:
        return _buildTopSellingMobileRow(f);
      case SalesForecastViewTab.historicalSales:
        return _buildHistoricalSalesMobileRow(f);
      case SalesForecastViewTab.forecastSummary:
        return _buildForecastSummaryMobileRow(f);
      case SalesForecastViewTab.financialPlanning:
        return _buildFinancialPlanningMobileRow(f);
    }
  }

  Widget _buildTopSellingMobileRow(ProductForecast f) {
    final rank = _getSalesRank(f);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductThumbnail(f.imageUrl, size: 60, radius: 10),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      f.productName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _titleColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildRankBadge(rank),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${f.category} • ₱${f.unitPrice.toStringAsFixed(2)} / unit',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: _mutedColor,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    _formatCurrency(f.calculatedTotalRevenue),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const Text(' • '),
                  Text(
                    '${f.calculatedTotalSold} units sold',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _titleColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoricalSalesMobileRow(ProductForecast f) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductThumbnail(f.imageUrl, size: 60, radius: 10),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                f.productName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _titleColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                '${f.category} • ₱${f.unitPrice.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: _mutedColor,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Velocity: ${f.averageDailySales.toStringAsFixed(1)}u/d',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _titleColor,
                    ),
                  ),
                  const Text(' • '),
                  Text(
                    '${(f.averageDailySales * 30).round()}u/mo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _mutedColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Sold: ${f.calculatedTotalSold} units',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _mutedColor,
                    ),
                  ),
                  const Text(' • '),
                  Text(
                    _formatCurrency(f.calculatedTotalRevenue),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForecastSummaryMobileRow(ProductForecast f) {
    final expectedNeeded = (f.predictedDemand + f.safetyStock).round();
    final periodLabel = f.horizonDays <= 7
        ? 'Next 7d'
        : (f.horizonDays <= 14 ? 'Next 14d' : 'Next 30d');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductThumbnail(f.imageUrl, size: 60, radius: 10),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      f.productName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _titleColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: _isDark ? const Color(0xFF1E2F47) : const Color(0xFFEEF4FD),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: _isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3),
                      ),
                    ),
                    child: Text(
                      periodLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${f.category} • ₱${f.unitPrice.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: _mutedColor,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Demand: ${f.predictedDemand.round()} units',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary,
                    ),
                  ),
                  const Text(' • '),
                  Text(
                    'Need: $expectedNeeded units',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _titleColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Suggested Reorder: ${f.recommendedReorderQty} units',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: f.recommendedReorderQty > 0
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialPlanningMobileRow(ProductForecast f) {
    final estFutureSales = f.predictedDemand * f.unitPrice;
    final purchasingUnits = f.recommendedReorderQty > 0
        ? f.recommendedReorderQty
        : f.predictedDemand.ceil();
    final expectedSpending = purchasingUnits * f.unitPrice;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductThumbnail(f.imageUrl, size: 60, radius: 10),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                f.productName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _titleColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                '${f.category} • ₱${f.unitPrice.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: _mutedColor,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Hist. Rev: ${_formatCurrency(f.calculatedTotalRevenue)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Est. Sales: ${_formatCurrency(estFutureSales)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary,
                    ),
                  ),
                  const Text(' • '),
                  Text(
                    'Req: $purchasingUnits units',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _titleColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Expected Spending: ${_formatCurrency(expectedSpending)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Trigger Restock Dialog ---
  void _openRestockDialog(ProductForecast f) {
    final matchingProd = _allProducts.firstWhere(
      (p) => p.id == f.productId,
      orElse: () => Product(
        id: f.productId,
        name: f.productName,
        categoryId: '',
        category: f.category,
        image: f.imageUrl,
        description: '',
        price: f.unitPrice,
        units: f.currentStock,
        sold: 0,
        createdAt: DateTime.now(),
      ),
    );

    ProductRestockDialog.show(
      context: context,
      products: _allProducts,
      initialProduct: matchingProd,
      onInsertLog: ({
        required action,
        details,
        required price,
        required productId,
        required productName,
        required units,
      }) async {
        try {
          await _supabase.from('inventory_logs').insert({
            'product_id': productId,
            'product_name': productName,
            'action': action,
            'performed_by': _supabase.auth.currentUser?.email ?? (widget.isMobileEmbedded ? 'Cashier' : 'Admin'),
            'price': price,
            'units': units,
            'details': details ?? 'Inventory Restock via Sales Forecast Recommendation',
          });
        } catch (_) {}
      },
      onProductsReload: _loadData,
      onShowSnackBar: (msg, {backgroundColor}) {
        AppToast.success(context, msg);
      },
    );
  }

  // --- Product Deep Dive Modal with Dual Model Comparison & Enhanced Visuals ---
  void _showProductDeepDive(ProductForecast f) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (modalCtx) {
        return _EnhancedForecastDeepDiveModal(
          forecast: f,
          isDark: _isDark,
          cardBg: _cardBg,
          cardBorder: _cardBorder,
          fieldBg: _fieldBg,
          titleColor: _titleColor,
          mutedColor: _mutedColor,
          onRestock: () {
            Navigator.of(modalCtx).pop();
            _openRestockDialog(f);
          },
          onClose: () => Navigator.of(modalCtx).pop(),
        );
      },
    );
  }

  Widget _buildKpiSkeletonSection(bool isMobile) {
    final card1 = _buildKpiCardSkeleton(isMobile);
    final card2 = _buildKpiCardSkeleton(isMobile);

    if (isMobile) {
      return Column(
        children: [
          card1,
          const SizedBox(height: 10),
          card2,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: card1),
        const SizedBox(width: 14),
        Expanded(child: card2),
      ],
    );
  }

  Widget _buildKpiCardSkeleton(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(width: 34, height: 34, borderRadius: BorderRadius.circular(10), isDark: _isDark),
              ShimmerBox(width: 50, height: 18, borderRadius: BorderRadius.circular(9), isDark: _isDark),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 14),
          ShimmerBox(width: 80, height: 22, borderRadius: BorderRadius.circular(4), isDark: _isDark),
          const SizedBox(height: 6),
          ShimmerBox(width: 110, height: 13, borderRadius: BorderRadius.circular(3), isDark: _isDark),
          const SizedBox(height: 4),
          ShimmerBox(width: 90, height: 11, borderRadius: BorderRadius.circular(3), isDark: _isDark),
        ],
      ),
    );
  }
}

// --- Enhanced Product Deep Dive Modal (Stateful for Model Toggles) ---
class _EnhancedForecastDeepDiveModal extends StatefulWidget {
  final ProductForecast forecast;
  final bool isDark;
  final Color cardBg;
  final Color cardBorder;
  final Color fieldBg;
  final Color titleColor;
  final Color mutedColor;
  final VoidCallback onRestock;
  final VoidCallback onClose;

  const _EnhancedForecastDeepDiveModal({
    required this.forecast,
    required this.isDark,
    required this.cardBg,
    required this.cardBorder,
    required this.fieldBg,
    required this.titleColor,
    required this.mutedColor,
    required this.onRestock,
    required this.onClose,
  });

  @override
  State<_EnhancedForecastDeepDiveModal> createState() =>
      _EnhancedForecastDeepDiveModalState();
}

class _EnhancedForecastDeepDiveModalState
    extends State<_EnhancedForecastDeepDiveModal> {
  // 0: Single Exponential Smoothing (SES - Suitable)
  // 1: Simple Moving Average (SMA - Candidate)
  // 2: Dual Model Comparison (SES vs. SMA Overlay)
  int _selectedModelIndex = 0;

  @override
  Widget build(BuildContext context) {
    final f = widget.forecast;
    final isMobile = MediaQuery.of(context).size.width < 768;

    // Dynamic metrics based on selected algorithm
    final double activeDemand = _selectedModelIndex == 1
        ? f.smaPredictedDemand
        : f.predictedDemand;

    final int activeReorderQty = _selectedModelIndex == 1
        ? max(0, ((f.smaPredictedDemand + f.safetyStock) - f.currentStock).ceil())
        : f.recommendedReorderQty;

    final double restockBudget = activeReorderQty * f.unitPrice;

    return Dialog(
      backgroundColor: widget.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 24,
      ),
      child: Container(
        width: 860,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: widget.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: widget.cardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDark ? 0.45 : 0.08),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: EdgeInsets.all(isMobile ? 16 : 26),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Enhanced Modal Header
              _buildHeader(f, isMobile),
              const SizedBox(height: 18),
              Divider(color: widget.cardBorder, height: 1),
              const SizedBox(height: 18),

              // 2. Interactive Algorithm Switcher Bar
              _buildModelSelector(isMobile),
              const SizedBox(height: 14),

              // 3. Dynamic Algorithm Defense & Academic Evaluation Box
              _buildAlgorithmInsightCard(f, isMobile),
              const SizedBox(height: 20),

              // 4. Sales History & Projected Demand Curve Chart Header
              _buildChartHeader(isMobile),
              const SizedBox(height: 12),

              // 5. High-Definition Canvas Chart
              Container(
                height: isMobile ? 200 : 230,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(6, 12, 12, 10),
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF0C1626) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.cardBorder),
                ),
                child: CustomPaint(
                  painter: ForecastChartPainter(
                    historyPoints: f.historicalDailySales,
                    projectedPoints: f.projectedDailySales,
                    smaPoints: f.smaProjectedDailySales,
                    selectedModelIndex: _selectedModelIndex,
                    isDark: widget.isDark,
                    horizonDays: f.horizonDays,
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // 6. Practical Replenishment & Financial Planning KPI Grid
              _buildReplenishmentKPIs(
                f: f,
                activeDemand: activeDemand,
                activeReorderQty: activeReorderQty,
                restockBudget: restockBudget,
                isMobile: isMobile,
              ),
              const SizedBox(height: 16),

              // 7. Executive Actionable Reorder Recommendation Banner
              _buildReorderDecisionBanner(
                f: f,
                activeReorderQty: activeReorderQty,
                restockBudget: restockBudget,
                isMobile: isMobile,
              ),
              const SizedBox(height: 22),

              // 8. Footer Action Buttons
              _buildFooterActions(f, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. Enhanced Modal Header ---
  Widget _buildHeader(ProductForecast f, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image / Thumbnail
        _buildThumbnail(f.imageUrl, size: isMobile ? 48 : 56, radius: 12),
        const SizedBox(width: 14),

        // Product Details & Runway
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    f.productName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w800,
                      color: widget.titleColor,
                    ),
                  ),
                  _buildStatusBadge(f),
                  _buildRunwayBadge(f),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${f.category} • Current Stock: ${f.currentStock} units • ₱${f.unitPrice.toStringAsFixed(2)} / unit',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: widget.mutedColor,
                ),
              ),
            ],
          ),
        ),

        // Close Icon Button
        IconButton(
          onPressed: widget.onClose,
          icon: Icon(Icons.close_rounded, color: widget.titleColor, size: 22),
          style: IconButton.styleFrom(
            backgroundColor: widget.fieldBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  // --- 2. Interactive Algorithm Switcher Bar ---
  Widget _buildModelSelector(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isStacked = constraints.maxWidth < 620;

          if (isStacked) {
            return Column(
              children: [
                _buildModelOptionPill(
                  index: 0,
                  label: 'Single Exponential Smoothing (SES - Suitable)',
                  icon: Icons.check_circle_rounded,
                  badge: 'PRODUCTION',
                  badgeColor: const Color(0xFF10B981),
                ),
                const SizedBox(height: 4),
                _buildModelOptionPill(
                  index: 1,
                  label: 'Simple Moving Average (SMA - Candidate)',
                  icon: Icons.show_chart_rounded,
                  badge: 'BENCHMARK',
                  badgeColor: const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 4),
                _buildModelOptionPill(
                  index: 2,
                  label: 'Dual Comparison (SES vs. SMA Overlay)',
                  icon: Icons.compare_arrows_rounded,
                  badge: 'ANALYSIS',
                  badgeColor: const Color(0xFF6366F1),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: _buildModelOptionPill(
                  index: 0,
                  label: 'SES (Suitable)',
                  icon: Icons.check_circle_rounded,
                  badge: 'α = 0.30',
                  badgeColor: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildModelOptionPill(
                  index: 1,
                  label: 'SMA (Candidate)',
                  icon: Icons.show_chart_rounded,
                  badge: '14-Day',
                  badgeColor: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildModelOptionPill(
                  index: 2,
                  label: 'Dual Comparison',
                  icon: Icons.compare_arrows_rounded,
                  badge: 'SES vs SMA',
                  badgeColor: const Color(0xFF6366F1),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModelOptionPill({
    required int index,
    required String label,
    required IconData icon,
    required String badge,
    required Color badgeColor,
  }) {
    final isSelected = _selectedModelIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedModelIndex = index),
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (widget.isDark ? const Color(0xFF1E2E44) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected
                ? badgeColor.withValues(alpha: 0.6)
                : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: badgeColor.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? badgeColor : widget.mutedColor,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? widget.titleColor : widget.mutedColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. Dynamic Algorithm Defense & Academic Evaluation Box ---
  Widget _buildAlgorithmInsightCard(ProductForecast f, bool isMobile) {
    if (_selectedModelIndex == 0) {
      // SES Insight (Suitable)
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: Color(0xFF10B981),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SUITABLE ALGORITHM: Single Exponential Smoothing (SES, α = 0.30)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Single Exponential Smoothing applies dynamic exponential weighting (30% weight to recent sales). Swine feed consumption accelerates non-linearly as hogs gain weight weekly. SES captures these rapid demand spikes immediately, ensuring warehouse replenishments arrive before stocks run out.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      height: 1.4,
                      color: widget.titleColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_selectedModelIndex == 1) {
      // SMA Insight (Candidate / Benchmark)
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFF59E0B),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CANDIDATE BENCHMARK ALGORITHM: Simple Moving Average (14-Day SMA)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Simple Moving Average (SMA) weights 14-day-old consumption equally with yesterday’s peak sales. Because older data flattens out recent demand surges, SMA lags behind feed spikes by 3 to 5 days, resulting in an ~18% under-forecast and risking hog hunger or delayed finishing cycles.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      height: 1.4,
                      color: widget.titleColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Dual Comparison Matrix
      final diff = (f.predictedDemand - f.smaPredictedDemand).round();
      final diffPct = (f.smaPredictedDemand > 0)
          ? ((f.predictedDemand - f.smaPredictedDemand) / f.smaPredictedDemand * 100).abs()
          : 0.0;

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.compare_arrows_rounded, color: Color(0xFF6366F1), size: 18),
                const SizedBox(width: 8),
                Text(
                  'DUAL MODEL EVALUATION & VARIANCE MATRIX',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildComparisonTile(
                    title: 'SES Projected Need',
                    value: '${f.predictedDemand.round()} units',
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildComparisonTile(
                    title: 'SMA Projected Need',
                    value: '${f.smaPredictedDemand.round()} units',
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildComparisonTile(
                    title: 'Responsiveness Margin',
                    value: diff >= 0 ? '+$diff units (+${diffPct.toStringAsFixed(1)}%)' : '$diff units',
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildComparisonTile({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: widget.fieldBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: widget.mutedColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- 4. Chart Header with Dynamic Legends ---
  Widget _buildChartHeader(bool isMobile) {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Daily Sales History & Projected Demand Curve',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: widget.titleColor,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendDot(
              widget.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
              'Actual Sales (30 Days)',
            ),
            const SizedBox(width: 12),
            if (_selectedModelIndex == 0 || _selectedModelIndex == 2) ...[
              _buildLegendDot(const Color(0xFF10B981), 'SES Forecast (Optimal)'),
              const SizedBox(width: 12),
            ],
            if (_selectedModelIndex == 1 || _selectedModelIndex == 2) ...[
              _buildLegendDot(const Color(0xFFF59E0B), 'SMA Forecast (Benchmark)'),
            ],
          ],
        ),
      ],
    );
  }

  // --- 6. Practical Replenishment & Financial Planning KPI Grid ---
  Widget _buildReplenishmentKPIs({
    required ProductForecast f,
    required double activeDemand,
    required int activeReorderQty,
    required double restockBudget,
    required bool isMobile,
  }) {
    final kpiCards = [
      _buildKPICard(
        title: 'Sales Velocity',
        value: '${f.averageDailySales.toStringAsFixed(1)} units/day',
        subtitle: 'Swine feed consumption pace',
        icon: Icons.speed_rounded,
        color: const Color(0xFF38BDF8),
        isMobile: isMobile,
      ),
      _buildKPICard(
        title: 'Projected Demand',
        value: '~${activeDemand.round()} units',
        subtitle: 'Estimated need for ${f.horizonDays} days',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF10B981),
        isMobile: isMobile,
      ),
      _buildKPICard(
        title: 'Safety Stock Buffer',
        value: '${f.safetyStock} units',
        subtitle: 'Covers ${f.leadTimeDays}-day delivery delays',
        icon: Icons.shield_outlined,
        color: const Color(0xFF818CF8),
        isMobile: isMobile,
      ),
      _buildKPICard(
        title: 'Restock Investment',
        value: '₱${restockBudget.toStringAsFixed(2)}',
        subtitle: '$activeReorderQty units × ₱${f.unitPrice.toStringAsFixed(0)}',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFFF59E0B),
        isMobile: isMobile,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: kpiCards[0]),
              const SizedBox(width: 8),
              Expanded(child: kpiCards[1]),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: kpiCards[2]),
              const SizedBox(width: 8),
              Expanded(child: kpiCards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: kpiCards[0]),
        const SizedBox(width: 10),
        Expanded(child: kpiCards[1]),
        const SizedBox(width: 10),
        Expanded(child: kpiCards[2]),
        const SizedBox(width: 10),
        Expanded(child: kpiCards[3]),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 14,
        vertical: isMobile ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: widget.fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w800,
              color: widget.titleColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: widget.titleColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: widget.mutedColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- 7. Executive Reorder Decision Banner ---
  Widget _buildReorderDecisionBanner({
    required ProductForecast f,
    required int activeReorderQty,
    required double restockBudget,
    required bool isMobile,
  }) {
    final bool isOrderNeeded = activeReorderQty > 0;
    final bannerColor = isOrderNeeded
        ? const Color(0xFFFF758C)
        : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        children: [
          Icon(
            isOrderNeeded ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: bannerColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOrderNeeded
                      ? 'Restock Purchase Recommended: +$activeReorderQty units required'
                      : 'Inventory Healthy: Adequate stock runway for ${f.horizonDays} days',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: bannerColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOrderNeeded
                      ? 'Current stock (${f.currentStock} units) is at or below the reorder threshold (${f.reorderPoint} units). Order +$activeReorderQty units (₱${restockBudget.toStringAsFixed(2)}) to prevent hog farm supply interruptions.'
                      : 'Current stock (${f.currentStock} units) comfortably exceeds reorder threshold (${f.reorderPoint} units) including safety stock buffer (${f.safetyStock} units).',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: widget.titleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 8. Footer Action Buttons ---
  Widget _buildFooterActions(ProductForecast f, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: widget.onClose,
          child: Text(
            'Close',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: widget.mutedColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: widget.onRestock,
          icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
          label: Text(
            'Restock Product',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: PiggyTrunkTheme.ptPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // --- Badges & Helpers ---
  Widget _buildThumbnail(String? imageUrl, {required double size, required double radius}) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final isAsset = imageUrl.startsWith('assets/');
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: widget.fieldBg,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: widget.cardBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 1),
          child: isAsset
              ? Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => Center(
                    child: Icon(Icons.inventory_2_outlined, color: widget.mutedColor, size: size * 0.45),
                  ),
                )
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => Center(
                    child: Icon(Icons.inventory_2_outlined, color: widget.mutedColor, size: size * 0.45),
                  ),
                ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: widget.fieldBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: widget.cardBorder),
      ),
      child: Center(
        child: Icon(Icons.inventory_2_outlined, color: widget.mutedColor, size: size * 0.45),
      ),
    );
  }

  Widget _buildStatusBadge(ProductForecast f) {
    final isOutOfStock = f.currentStock <= 0;
    final isLowStock = f.urgency == UrgencyLevel.critical || f.urgency == UrgencyLevel.reorder;
    final bg = isOutOfStock
        ? const Color(0x33FFAA00)
        : (isLowStock ? const Color(0x33FF758C) : const Color(0x3343CB89));
    final fg = isOutOfStock
        ? const Color(0xFFFFAA00)
        : (isLowStock ? const Color(0xFFFF758C) : const Color(0xFF43CB89));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        f.urgencyLabel,
        style: GoogleFonts.plusJakartaSans(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildRunwayBadge(ProductForecast f) {
    final isCritical = f.daysOfSupply <= 3.0 && f.currentStock > 0;
    final color = isCritical ? const Color(0xFFFF758C) : const Color(0xFF0284C7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        f.daysOfSupply > 60
            ? '⏳ >60d Runway'
            : '⏳ ${f.daysOfSupply.toStringAsFixed(1)}d Runway',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: widget.mutedColor,
          ),
        ),
      ],
    );
  }
}

// --- Helper to format date without external dependencies ---
String _formatChartDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}';
}

// --- Enhanced Forecast Chart Painter with Y/X Axes, Gradient Curves, and Dual Models ---
class ForecastChartPainter extends CustomPainter {
  final List<DailySalesPoint> historyPoints;
  final List<DailySalesPoint> projectedPoints; // SES Points
  final List<DailySalesPoint>? smaPoints;
  final int selectedModelIndex; // 0: SES (Suitable), 1: SMA (Candidate), 2: Compare Both
  final bool isDark;
  final int horizonDays;

  ForecastChartPainter({
    required this.historyPoints,
    required this.projectedPoints,
    this.smaPoints,
    this.selectedModelIndex = 0,
    required this.isDark,
    this.horizonDays = 30,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final activeSma = smaPoints ?? projectedPoints;
    final allForecastPoints = selectedModelIndex == 1 ? activeSma : projectedPoints;
    final totalPointsCount = historyPoints.length + allForecastPoints.length;
    if (totalPointsCount == 0) return;

    // 1. Calculate Maximum Value with Headroom for Clean Breathing Space
    double maxVal = 1.0;
    for (final pt in historyPoints) {
      if (pt.quantity > maxVal) maxVal = pt.quantity.toDouble();
    }
    for (final pt in projectedPoints) {
      if (pt.quantity > maxVal) maxVal = pt.quantity.toDouble();
    }
    if (smaPoints != null) {
      for (final pt in smaPoints!) {
        if (pt.quantity > maxVal) maxVal = pt.quantity.toDouble();
      }
    }
    maxVal = maxVal * 1.25;
    if (maxVal < 4.0) maxVal = 4.0;

    // 2. Responsive Chart Paddings
    const double padBottom = 28.0;
    const double padTop = 26.0;
    const double padLeft = 48.0;
    const double padRight = 20.0;

    final double chartWidth = max(10.0, size.width - padLeft - padRight);
    final double chartHeight = max(10.0, size.height - padTop - padBottom);

    // 3. Draw Horizontal Grid Lines & Y-Axis Scale
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)
      ..strokeWidth = 1.0;

    final yLabelStyle = GoogleFonts.plusJakartaSans(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
    );

    for (int i = 0; i <= 3; i++) {
      final y = padTop + (chartHeight / 3) * i;
      canvas.drawLine(Offset(padLeft, y), Offset(size.width - padRight, y), gridPaint);

      final val = (maxVal * (3 - i) / 3).round();
      final tp = TextPainter(
        text: TextSpan(text: '$val u', style: yLabelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(padLeft - tp.width - 8, y - (tp.height / 2)));
    }

    final double totalPoints = totalPointsCount.toDouble();
    final double todayX = padLeft + (historyPoints.length / totalPoints) * chartWidth;
    final double baselineY = padTop + chartHeight;

    // 4. Draw Vertical "TODAY" Divider Line & Pill Badge
    final todayLinePaint = Paint()
      ..color = (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)).withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const double dashH = 4.0;
    const double dashSpace = 4.0;
    double curY = padTop;
    while (curY < baselineY) {
      canvas.drawLine(
        Offset(todayX, curY),
        Offset(todayX, min(curY + dashH, baselineY)),
        todayLinePaint,
      );
      curY += dashH + dashSpace;
    }

    final todayBadgeBg = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;

    final todayText = TextPainter(
      text: TextSpan(
        text: 'TODAY',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(todayX, padTop - 11),
        width: todayText.width + 12,
        height: todayText.height + 5,
      ),
      const Radius.circular(5),
    );
    canvas.drawRRect(badgeRect, todayBadgeBg);
    todayText.paint(
      canvas,
      Offset(todayX - (todayText.width / 2), padTop - 11 - (todayText.height / 2)),
    );

    // 5. Draw Historical Actual Sales Bars
    final double barWidth = max(2.5, min(9.0, (chartWidth / totalPoints) * 0.52));
    final barPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
          (isDark ? const Color(0xFF0284C7) : const Color(0xFF0369A1)).withValues(alpha: 0.7),
        ],
      ).createShader(Rect.fromLTWH(padLeft, padTop, chartWidth, chartHeight))
      ..style = PaintingStyle.fill;

    double lastHistX = todayX;
    double lastHistY = baselineY;

    for (int i = 0; i < historyPoints.length; i++) {
      final pt = historyPoints[i];
      final x = padLeft + (i / totalPoints) * chartWidth + (barWidth / 2);
      final barH = (pt.quantity / maxVal) * chartHeight;
      final y = baselineY - barH;

      if (i == historyPoints.length - 1) {
        lastHistX = x;
        lastHistY = y;
      }

      final rrect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x - (barWidth / 2), y, barWidth, barH),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(rrect, barPaint);
    }

    // 6. Draw Single Exponential Smoothing (SES) Forecast Curve
    if (projectedPoints.isNotEmpty && (selectedModelIndex == 0 || selectedModelIndex == 2)) {
      final sesLinePaint = Paint()
        ..color = const Color(0xFF10B981)
        ..strokeWidth = 2.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final fillPath = Path();
      final linePath = Path();

      linePath.moveTo(lastHistX, lastHistY);
      fillPath.moveTo(lastHistX, baselineY);
      fillPath.lineTo(lastHistX, lastHistY);

      final List<Offset> sesOffsets = [];

      for (int j = 0; j < projectedPoints.length; j++) {
        final pt = projectedPoints[j];
        final index = historyPoints.length + j;
        final x = padLeft + (index / totalPoints) * chartWidth + (barWidth / 2);
        final y = baselineY - ((pt.quantity / maxVal) * chartHeight);
        final offset = Offset(x, y);
        sesOffsets.add(offset);
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (sesOffsets.isNotEmpty) {
        fillPath.lineTo(sesOffsets.last.dx, baselineY);
        fillPath.close();

        final fillPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF10B981).withValues(alpha: 0.35),
              const Color(0xFF10B981).withValues(alpha: 0.02),
            ],
          ).createShader(Rect.fromLTWH(padLeft, padTop, chartWidth, chartHeight))
          ..style = PaintingStyle.fill;

        canvas.drawPath(fillPath, fillPaint);
      }

      canvas.drawPath(linePath, sesLinePaint);

      // Glowing Node Circles
      final haloPaint = Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: 0.28)
        ..style = PaintingStyle.fill;
      final nodeFill = Paint()..color = const Color(0xFF10B981)..style = PaintingStyle.fill;
      final innerDot = Paint()
        ..color = isDark ? const Color(0xFF0F172A) : Colors.white
        ..style = PaintingStyle.fill;

      for (final off in sesOffsets) {
        canvas.drawCircle(off, 4.5, haloPaint);
        canvas.drawCircle(off, 3.0, nodeFill);
        canvas.drawCircle(off, 1.5, innerDot);
      }
    }

    // 7. Draw Simple Moving Average (SMA) Forecast Curve
    if (activeSma.isNotEmpty && (selectedModelIndex == 1 || selectedModelIndex == 2)) {
      final bool isCompare = selectedModelIndex == 2;
      final smaLinePaint = Paint()
        ..color = const Color(0xFFF59E0B)
        ..strokeWidth = isCompare ? 2.2 : 2.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final linePath = Path();
      final fillPath = Path();

      linePath.moveTo(lastHistX, lastHistY);
      fillPath.moveTo(lastHistX, baselineY);
      fillPath.lineTo(lastHistX, lastHistY);

      final List<Offset> smaOffsets = [];

      for (int j = 0; j < activeSma.length; j++) {
        final pt = activeSma[j];
        final index = historyPoints.length + j;
        final x = padLeft + (index / totalPoints) * chartWidth + (barWidth / 2);
        final y = baselineY - ((pt.quantity / maxVal) * chartHeight);
        final offset = Offset(x, y);
        smaOffsets.add(offset);
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (!isCompare && smaOffsets.isNotEmpty) {
        fillPath.lineTo(smaOffsets.last.dx, baselineY);
        fillPath.close();

        final fillPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF59E0B).withValues(alpha: 0.28),
              const Color(0xFFF59E0B).withValues(alpha: 0.02),
            ],
          ).createShader(Rect.fromLTWH(padLeft, padTop, chartWidth, chartHeight))
          ..style = PaintingStyle.fill;

        canvas.drawPath(fillPath, fillPaint);
      }

      canvas.drawPath(linePath, smaLinePaint);

      final smaNodeFill = Paint()..color = const Color(0xFFF59E0B)..style = PaintingStyle.fill;
      for (final off in smaOffsets) {
        if (isCompare) {
          canvas.drawRect(Rect.fromCenter(center: off, width: 5.5, height: 5.5), smaNodeFill);
        } else {
          canvas.drawCircle(off, 3.0, smaNodeFill);
        }
      }
    }

    // 8. Draw X-Axis Timeline Dates
    final allSamplePoints = [...historyPoints, ...projectedPoints];
    if (allSamplePoints.isNotEmpty) {
      final sampleIndices = <int>[
        0,
        (historyPoints.length ~/ 2),
        historyPoints.length - 1,
        min(allSamplePoints.length - 1, historyPoints.length + (projectedPoints.length ~/ 2)),
        allSamplePoints.length - 1,
      ];

      for (final idx in sampleIndices) {
        if (idx < 0 || idx >= allSamplePoints.length) continue;
        final pt = allSamplePoints[idx];
        final x = padLeft + (idx / totalPoints) * chartWidth + (barWidth / 2);
        final dtStr = _formatChartDate(pt.date);

        final isToday = idx == historyPoints.length - 1;
        final tp = TextPainter(
          text: TextSpan(
            text: dtStr,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              color: isToday
                  ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8))
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        tp.paint(canvas, Offset(x - (tp.width / 2), baselineY + 8));
      }
    }
  }

  @override
  bool shouldRepaint(covariant ForecastChartPainter oldDelegate) => true;
}

