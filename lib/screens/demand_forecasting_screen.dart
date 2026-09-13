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

  // Practical filters
  int _selectedHorizonDays = 7;
  String _selectedCategory = 'All';
  String _urgencyFilter = 'All'; // 'All', 'Reorder Needed', 'Critical', 'In Stock'
  final TextEditingController _searchCtrl = TextEditingController();

  static const List<String> _categoryOptions = <String>[
    'All',
    'Feeds',
    'Vitamins',
    'Medicines',
    'Others',
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
        categoryFilter: _selectedCategory,
        searchQuery: _searchCtrl.text,
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


  List<ProductForecast> get _filteredForecasts {
    return _forecasts.where((f) {
      if (_selectedCategory != 'All' &&
          f.category.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q.isNotEmpty && !f.productName.toLowerCase().contains(q)) {
        return false;
      }
      if (_urgencyFilter == 'Reorder Needed') {
        return f.urgency == UrgencyLevel.critical || f.urgency == UrgencyLevel.reorder;
      } else if (_urgencyFilter == 'Critical') {
        return f.urgency == UrgencyLevel.critical;
      } else if (_urgencyFilter == 'In Stock') {
        return f.urgency == UrgencyLevel.adequate || f.urgency == UrgencyLevel.overstocked;
      }
      return true;
    }).toList();
  }

  // Summary Metrics
  int get _reorderNeededCount => _forecasts
      .where((f) => f.urgency == UrgencyLevel.critical || f.urgency == UrgencyLevel.reorder)
      .length;

  double get _totalProjectedDemand =>
      _forecasts.fold(0.0, (sum, f) => sum + f.predictedDemand);

  int get _highRiskCount =>
      _forecasts.where((f) => f.daysOfSupply <= 3.0 && f.currentStock > 0).length;

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

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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

                  // 4 Practical KPI Summary Cards
                  _buildKPISection(isMobile),
                  const SizedBox(height: 24),

                  // Horizon Selector & Filter Controls
                  _buildControlsCard(isMobile),
                  const SizedBox(height: 24),

                  // Forecast & Restock Matrix
                  _buildForecastMatrixCard(isMobile),
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
                          'Demand Forecast',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _titleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Predict sales & stock replenishment',
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
                            'Demand Forecast',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: _titleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Predict product sales demand & recommended stock replenishment based on POS history',
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
        if (widget.isMobileEmbedded) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacementNamed('/pos');
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
      onPressed: _loadData,
      icon: Icon(
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

  // --- 4 Practical KPI Summary Cards ---
  Widget _buildKPISection(bool isMobile) {
    final cards = [
      _buildKPICard(
        title: 'Items to Reorder',
        value: '$_reorderNeededCount',
        subtitle: _reorderNeededCount > 0
            ? 'Stock at or below reorder point'
            : 'All stock levels are optimal',
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFFF758C),
        badgeText: isMobile
            ? (_reorderNeededCount > 0 ? 'RESTOCK' : 'STOCKED')
            : (_reorderNeededCount > 0 ? 'ACTION NEEDED' : 'ALL STOCKED'),
        isMobile: isMobile,
      ),
      _buildKPICard(
        title: 'Projected Demand',
        value: '${_totalProjectedDemand.round()} units',
        subtitle: 'Estimated sales for next $_selectedHorizonDays days',
        icon: Icons.trending_up_rounded,
        color: _isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary,
        badgeText: isMobile ? '${_selectedHorizonDays}D HORIZON' : '$_selectedHorizonDays DAYS HORIZON',
        isMobile: isMobile,
      ),
      _buildKPICard(
        title: 'Critical Stockout Risk',
        value: '$_highRiskCount items',
        subtitle: 'Inventory remaining for <= 3 days',
        icon: Icons.timer_outlined,
        color: const Color(0xFFFFAA00),
        badgeText: isMobile
            ? (_highRiskCount > 0 ? 'HIGH RISK' : 'STABLE')
            : (_highRiskCount > 0 ? 'CRITICAL RUNOUT' : 'BUFFER OK'),
        isMobile: isMobile,
      ),
      _buildKPICard(
        title: 'Monitored Products',
        value: '${_forecasts.length} items',
        subtitle: 'Tracked with daily sales velocity',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF43CB89),
        badgeText: 'REAL-TIME',
        isMobile: isMobile,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 8),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 8),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
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

              // Row 2: Search, Category Chips & Status Filter (Fills 100% of row)
              if (!isStacked)
                Row(
                  children: [
                    // Search Input (Expands to fill all remaining width)
                    Expanded(
                      child: _buildSearchTextField(),
                    ),
                    const SizedBox(width: 12),

                    // Category & Status Chips with Divider
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ..._categoryOptions.map((c) => _buildCategoryFilterChip(c)),
                          Container(
                            height: 20,
                            width: 1.2,
                            margin: const EdgeInsets.only(left: 2, right: 10),
                            color: _cardBorder,
                          ),
                          _buildUrgencyChip('All'),
                          _buildUrgencyChip('Reorder Needed'),
                          _buildUrgencyChip('Critical'),
                          _buildUrgencyChip('In Stock'),
                        ],
                      ),
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

                    // Category & Status Pills in a Single Clean Horizontal Scroll
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ..._categoryOptions.map((c) => _buildCategoryFilterChip(c)),
                          Container(
                            height: 20,
                            width: 1.2,
                            margin: const EdgeInsets.only(left: 2, right: 10),
                            color: _cardBorder,
                          ),
                          _buildUrgencyChip('All'),
                          _buildUrgencyChip('Reorder Needed'),
                          _buildUrgencyChip('Critical'),
                          _buildUrgencyChip('In Stock'),
                        ],
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

  Widget _buildCategoryFilterChip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() => _selectedCategory = category);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (_isDark ? Colors.white : PiggyTrunkTheme.ptPrimary)
                : (_isDark ? const Color(0xFF1A2B44) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.transparent : _cardBorder,
              width: 1,
            ),
          ),
          child: Text(
            category,
            style: GoogleFonts.plusJakartaSans(
              color: isSelected
                  ? (_isDark ? PiggyTrunkTheme.ptPrimary : Colors.white)
                  : _mutedColor,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUrgencyChip(String label) {
    final isSel = _urgencyFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _urgencyFilter = label),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: isSel
                ? (_isDark ? Colors.white : PiggyTrunkTheme.ptPrimary)
                : (_isDark ? const Color(0xFF1A2B44) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSel ? Colors.transparent : _cardBorder,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: isSel
                  ? (_isDark ? PiggyTrunkTheme.ptPrimary : Colors.white)
                  : _mutedColor,
              fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }

  // --- Forecast & Reorder Matrix Card ---
  Widget _buildForecastMatrixCard(bool isMobile) {
    final list = _filteredForecasts;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth > 720 ? constraints.maxWidth : 720.0;

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
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stock Replenishment Matrix',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _titleColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Demand forecast for $_selectedHorizonDays-day window • Safety buffer lead time: 3 days',
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
                    Text(
                      '${list.length} item(s)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                                Expanded(flex: 3, child: Text('PRODUCT', style: _tableHeaderStyle)),
                                Expanded(flex: 2, child: Text('CURRENT STOCK', style: _tableHeaderStyle)),
                                Expanded(flex: 2, child: Text('AVG DAILY SALES', style: _tableHeaderStyle)),
                                Expanded(flex: 2, child: Text('PROJECTED DEMAND', style: _tableHeaderStyle)),
                                Expanded(flex: 2, child: Text('RECOMMENDED RESTOCK', style: _tableHeaderStyle)),
                                SizedBox(width: 104, child: Text('ACTION', style: _tableHeaderStyle)),
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
    return Row(
      children: [
        // Product Info (Image + Title + Category + Price)
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _fieldBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            f.category,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              color: _mutedColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₱${f.unitPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: _mutedColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Current Stock & Badge (System Styled)
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${f.currentStock} units',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 4),
              _buildStatusPill(f),
            ],
          ),
        ),

        // Daily Sales Velocity
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${f.averageDailySales.toStringAsFixed(1)} / day',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                f.daysOfSupply > 60
                    ? '> 60 days supply'
                    : '${f.daysOfSupply.toStringAsFixed(0)} days left',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: f.daysOfSupply <= 3 ? const Color(0xFFFF758C) : _mutedColor,
                ),
              ),
            ],
          ),
        ),

        // Projected Demand
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
                'in $_selectedHorizonDays days',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: _mutedColor,
                ),
              ),
            ],
          ),
        ),

        // Recommended Restock
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: f.recommendedReorderQty > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF758C).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF758C).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_shopping_cart_rounded, size: 14, color: Color(0xFFFF758C)),
                        const SizedBox(width: 5),
                        Text(
                          '+${f.recommendedReorderQty} units',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFFF758C),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x3343CB89),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Sufficient',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF43CB89),
                      ),
                    ),
                  ),
          ),
        ),

        // Quick Restock Action Button
        SizedBox(
          width: 104,
          child: ElevatedButton(
            onPressed: () => _openRestockDialog(f),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
              foregroundColor: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_shopping_cart,
                  size: 14,
                  color: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                ),
                const SizedBox(width: 5),
                Text(
                  'Restock',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill(ProductForecast f) {
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

  Widget _buildMobileRow(ProductForecast f) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Thumbnail Image
        _buildProductThumbnail(f.imageUrl, size: 70, radius: 12),
        const SizedBox(width: 12),

        // Product Details Column
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
                  _buildStatusPill(f),
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
                    'Stock: ${f.currentStock} units',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _titleColor,
                    ),
                  ),
                  const Text(' • '),
                  Text(
                    'Demand: ${f.predictedDemand.round()}u (${_selectedHorizonDays}d)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (f.recommendedReorderQty > 0)
                    Text(
                      'Reorder: +${f.recommendedReorderQty} units',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFF758C),
                      ),
                    )
                  else
                    Text(
                      'Stock Healthy',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF43CB89),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: () => _openRestockDialog(f),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                      foregroundColor: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_shopping_cart,
                          size: 13,
                          color: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Restock',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                          ),
                        ),
                      ],
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
            'details': details ?? 'Inventory Restock via Demand Forecast Recommendation',
          });
        } catch (_) {}
      },
      onProductsReload: _loadData,
      onShowSnackBar: (msg, {backgroundColor}) {
        AppToast.success(context, msg);
      },
    );
  }

  // --- Product Deep Dive Modal with Chart & Simple Summary ---
  void _showProductDeepDive(ProductForecast f) {
    showDialog(
      context: context,
      builder: (modalCtx) {
        return Dialog(
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 720,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            padding: const EdgeInsets.all(28),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            _buildProductThumbnail(f.imageUrl, size: 48, radius: 10),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        f.productName,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: _titleColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatusPill(f),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${f.category} • Current Stock: ${f.currentStock} units • ₱${f.unitPrice.toStringAsFixed(2)}/unit',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: _mutedColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(modalCtx).pop(),
                        icon: Icon(Icons.close_rounded, color: _titleColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: _cardBorder, height: 1),
                  const SizedBox(height: 20),

                  // Chart Header
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Sales History & Projected Demand Curve',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _titleColor,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLegendDot(_isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary, 'Actual Sales'),
                          const SizedBox(width: 14),
                          _buildLegendDot(const Color(0xFF10B981), 'Forecast Demand ($_selectedHorizonDays Days)'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Custom Paint Chart
                  Container(
                    height: 190,
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isDark ? const Color(0xFF0E1726) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _cardBorder),
                    ),
                    child: CustomPaint(
                      painter: ForecastChartPainter(
                        historyPoints: f.historicalDailySales,
                        projectedPoints: f.projectedDailySales,
                        isDark: _isDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Plain Retail Business Summary
                  Text(
                    'Replenishment Breakdown',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _fieldBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryItem(
                          'Average Sales Velocity',
                          '${f.averageDailySales.toStringAsFixed(1)} units / day',
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryItem(
                          'Expected Demand in $_selectedHorizonDays Days',
                          '~${f.predictedDemand.round()} units',
                          color: _isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryItem(
                          'Safety Stock Buffer',
                          '${f.safetyStock} units (Covers supply delays)',
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryItem(
                          'Reorder Threshold',
                          '${f.reorderPoint} units (Current: ${f.currentStock} units)',
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryItem(
                          'Recommended Reorder Quantity',
                          f.recommendedReorderQty > 0
                              ? '+${f.recommendedReorderQty} units to order'
                              : '0 units (Current stock is sufficient)',
                          color: f.recommendedReorderQty > 0
                              ? const Color(0xFFFF758C)
                              : const Color(0xFF43CB89),
                          isBold: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(modalCtx).pop(),
                        child: Text(
                          'Close',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: _mutedColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(modalCtx).pop();
                          _openRestockDialog(f);
                        },
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                        label: Text(
                          'Restock Product',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PiggyTrunkTheme.ptPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: _mutedColor),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: _titleColor,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: color ?? _titleColor,
          ),
        ),
      ],
    );
  }
}

// --- Forecast Chart Painter ---
class ForecastChartPainter extends CustomPainter {
  final List<DailySalesPoint> historyPoints;
  final List<DailySalesPoint> projectedPoints;
  final bool isDark;

  ForecastChartPainter({
    required this.historyPoints,
    required this.projectedPoints,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final allPoints = [...historyPoints, ...projectedPoints];
    if (allPoints.isEmpty) return;

    final maxVal = max(
      1.0,
      allPoints.fold<double>(0.0, (m, pt) => max(m, pt.quantity.toDouble())),
    );

    const double padBottom = 24.0;
    const double padTop = 14.0;
    const double padLeft = 32.0;
    const double padRight = 16.0;

    final double chartWidth = size.width - padLeft - padRight;
    final double chartHeight = size.height - padTop - padBottom;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.black12
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final y = padTop + (chartHeight / 3) * i;
      canvas.drawLine(Offset(padLeft, y), Offset(size.width - padRight, y), gridPaint);
    }

    final double totalPoints = allPoints.length.toDouble();
    final double barWidth = max(2.0, (chartWidth / totalPoints) * 0.55);

    // Draw Historical Bars
    final barPaint = Paint()
      ..color = (isDark ? const Color(0xFF60A5FA) : const Color(0xFF243B53)).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < historyPoints.length; i++) {
      final pt = historyPoints[i];
      final x = padLeft + (i / totalPoints) * chartWidth;
      final barH = (pt.quantity / maxVal) * chartHeight;
      final y = padTop + chartHeight - barH;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barH),
        const Radius.circular(2),
      );
      canvas.drawRRect(rrect, barPaint);
    }

    // Draw Projected Line
    if (projectedPoints.isNotEmpty) {
      final path = Path();
      final linePaint = Paint()
        ..color = const Color(0xFF10B981)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      final nodePaint = Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.fill;

      for (int j = 0; j < projectedPoints.length; j++) {
        final pt = projectedPoints[j];
        final index = historyPoints.length + j;
        final x = padLeft + (index / totalPoints) * chartWidth + (barWidth / 2);
        final y = padTop + chartHeight - ((pt.quantity / maxVal) * chartHeight);

        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        canvas.drawCircle(Offset(x, y), 3.5, nodePaint);
      }

      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant ForecastChartPainter oldDelegate) => true;
}
