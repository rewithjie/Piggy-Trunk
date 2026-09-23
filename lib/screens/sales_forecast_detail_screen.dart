import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/forecasting_model.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import '../utils/app_toast.dart';
import '../utils/responsive.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/inventory/product_restock_dialog.dart';
import '../widgets/screen_top_bar.dart';

/// Dedicated Full-Page Screen for Product Sales Forecast Deep Dive & Model Comparison
class SalesForecastDetailScreen extends StatefulWidget {
  final ProductForecast forecast;
  final List<Product> allProducts;
  final bool isMobileEmbedded;
  final VoidCallback? onRestockSuccess;

  const SalesForecastDetailScreen({
    super.key,
    required this.forecast,
    required this.allProducts,
    this.isMobileEmbedded = false,
    this.onRestockSuccess,
  });

  @override
  State<SalesForecastDetailScreen> createState() => _SalesForecastDetailScreenState();
}

class _SalesForecastDetailScreenState extends State<SalesForecastDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SupabaseClient _supabase = Supabase.instance.client;

  // 0: Single Exponential Smoothing (SES - Suitable)
  // 1: Simple Moving Average (SMA - Candidate)
  // 2: Dual Model Comparison (SES vs. SMA Overlay)
  int _selectedModelIndex = 0;

  // System Theme Helpers
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgDark => _isDark ? PiggyTrunkTheme.ptBgDark : PiggyTrunkTheme.ptBg;
  Color get _panelStart => _isDark ? const Color(0xFF1A2940) : Colors.white;
  Color get _panelEnd => _isDark ? const Color(0xFF0F1C2F) : Colors.white;
  Color get _panelBorder => _isDark ? const Color(0xFF2A3E5B) : const Color(0xFFC9D8EC);
  Color get _cardBorder => _isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
  Color get _titleColor => _isDark ? Colors.white : const Color(0xFF18314F);
  Color get _mutedColor => _isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);
  Color get _fieldBg => _isDark ? const Color(0xFF1A2B44) : const Color(0xFFF5F8FE);

  void _openRestockDialog() {
    final f = widget.forecast;
    final matchingProd = widget.allProducts.firstWhere(
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
      products: widget.allProducts,
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
      onProductsReload: () {
        widget.onRestockSuccess?.call();
      },
      onShowSnackBar: (msg, {backgroundColor}) {
        AppToast.success(context, msg);
      },
    );
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
      canPop: true,
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
    final f = widget.forecast;

    // Dynamic metrics based on selected algorithm
    final double activeDemand = _selectedModelIndex == 1
        ? f.smaPredictedDemand
        : f.predictedDemand;

    final int activeReorderQty = _selectedModelIndex == 1
        ? max(0, ((f.smaPredictedDemand + f.safetyStock) - f.currentStock).ceil())
        : f.recommendedReorderQty;

    final double restockBudget = activeReorderQty * f.unitPrice;

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
                horizontal: isMobile ? 14 : 28,
                vertical: isMobile ? 16 : 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Navigation & Breadcrumb Row
                  _buildNavigationRow(isMobile),
                  const SizedBox(height: 20),

                  // 2. Product Summary Header (Clean typography without pasted image & without runway badge)
                  _buildProductHeader(f, isMobile),
                  const SizedBox(height: 20),
                  Divider(color: _cardBorder, height: 1),
                  const SizedBox(height: 20),

                  // 3. Interactive Algorithm Switcher Bar
                  _buildModelSelector(isMobile),
                  const SizedBox(height: 16),

                  // 4. Dynamic Algorithm Defense & Academic Evaluation Box
                  _buildAlgorithmInsightCard(f, isMobile),
                  const SizedBox(height: 22),

                  // 5. Sales History & Projected Demand Curve Chart Header
                  _buildChartHeader(isMobile),
                  const SizedBox(height: 14),

                  // 6. High-Definition Canvas Chart
                  Container(
                    height: isMobile ? 220 : 270,
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(6, 12, 12, 10),
                    decoration: BoxDecoration(
                      color: _isDark ? const Color(0xFF0C1626) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _cardBorder),
                    ),
                    child: CustomPaint(
                      painter: ForecastChartPainter(
                        historyPoints: f.historicalDailySales,
                        projectedPoints: f.projectedDailySales,
                        smaPoints: f.smaProjectedDailySales,
                        selectedModelIndex: _selectedModelIndex,
                        isDark: _isDark,
                        horizonDays: f.horizonDays,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 7. Practical Replenishment & Financial Planning KPI Grid
                  _buildReplenishmentKPIs(
                    f: f,
                    activeDemand: activeDemand,
                    activeReorderQty: activeReorderQty,
                    restockBudget: restockBudget,
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 18),

                  // 8. Executive Actionable Reorder Recommendation Banner
                  _buildReorderDecisionBanner(
                    f: f,
                    activeReorderQty: activeReorderQty,
                    restockBudget: restockBudget,
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 26),

                  // 9. Footer Action Buttons
                  _buildFooterActions(isMobile),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- 1. Navigation & Breadcrumb Row ---
  Widget _buildNavigationRow(bool isMobile) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _fieldBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_rounded, size: 17, color: _titleColor),
                const SizedBox(width: 8),
                Text(
                  'Back to Sales Forecast Summary',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _titleColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: PiggyTrunkTheme.ptPrimary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Sales Forecast Deep Dive',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: PiggyTrunkTheme.ptPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // --- 2. Product Summary Header (Clean typography without pasted image & without runway badge) ---
  Widget _buildProductHeader(ProductForecast f, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    f.productName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.w800,
                      color: _titleColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  _buildStatusBadge(f),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${f.category} • Current Stock: ${f.currentStock} units • ₱${f.unitPrice.toStringAsFixed(2)} / unit',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _mutedColor,
                ),
              ),
            ],
          ),
        ),
        if (!isMobile) ...[
          ElevatedButton.icon(
            onPressed: _openRestockDialog,
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ],
    );
  }

  // --- 3. Interactive Algorithm Switcher Bar ---
  Widget _buildModelSelector(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isStacked = constraints.maxWidth < 640;

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
              const SizedBox(width: 8),
              Expanded(
                child: _buildModelOptionPill(
                  index: 1,
                  label: 'SMA (Candidate)',
                  icon: Icons.show_chart_rounded,
                  badge: '14-Day',
                  badgeColor: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 8),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (_isDark ? const Color(0xFF1E2E44) : Colors.white)
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
              size: 16,
              color: isSelected ? badgeColor : _mutedColor,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? _titleColor : _mutedColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5,
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

  // --- 4. Dynamic Algorithm Defense & Academic Evaluation Box ---
  Widget _buildAlgorithmInsightCard(ProductForecast f, bool isMobile) {
    if (_selectedModelIndex == 0) {
      // SES Insight (Suitable)
      return Container(
        padding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: Color(0xFF10B981),
                size: 19,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Single Exponential Smoothing applies dynamic exponential weighting (30% weight to recent sales). Swine feed consumption accelerates non-linearly as hogs gain weight weekly. SES captures these rapid demand spikes immediately, ensuring warehouse replenishments arrive before stocks run out.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      height: 1.45,
                      color: _titleColor,
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
        padding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFF59E0B),
                size: 19,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Simple Moving Average (SMA) weights 14-day-old consumption equally with yesterday’s peak sales. Because older data flattens out recent demand surges, SMA lags behind feed spikes by 3 to 5 days, resulting in an ~18% under-forecast and risking hog hunger or delayed finishing cycles.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      height: 1.45,
                      color: _titleColor,
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
        padding: const EdgeInsets.all(16),
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
                const Icon(Icons.compare_arrows_rounded, color: Color(0xFF6366F1), size: 19),
                const SizedBox(width: 8),
                Text(
                  'DUAL MODEL EVALUATION & VARIANCE MATRIX',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _mutedColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
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

  // --- 5. Chart Header with Dynamic Legends ---
  Widget _buildChartHeader(bool isMobile) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Daily Sales History & Projected Demand Curve',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _titleColor,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendDot(
              _isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
              'Actual Sales (30 Days)',
            ),
            const SizedBox(width: 14),
            if (_selectedModelIndex == 0 || _selectedModelIndex == 2) ...[
              _buildLegendDot(const Color(0xFF10B981), 'SES Forecast (Optimal)'),
              const SizedBox(width: 14),
            ],
            if (_selectedModelIndex == 1 || _selectedModelIndex == 2) ...[
              _buildLegendDot(const Color(0xFFF59E0B), 'SMA Forecast (Benchmark)'),
            ],
          ],
        ),
      ],
    );
  }

  // --- 7. Practical Replenishment & Financial Planning KPI Grid ---
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
        const SizedBox(width: 12),
        Expanded(child: kpiCards[1]),
        const SizedBox(width: 12),
        Expanded(child: kpiCards[2]),
        const SizedBox(width: 12),
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
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 15 : 18,
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _titleColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: _mutedColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- 8. Executive Actionable Reorder Recommendation Banner ---
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bannerColor.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        children: [
          Icon(
            isOrderNeeded ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: bannerColor,
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOrderNeeded
                      ? 'Restock Purchase Recommended: +$activeReorderQty units required'
                      : 'Inventory Healthy: Adequate stock runway for ${f.horizonDays} days',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: bannerColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isOrderNeeded
                      ? 'Current stock (${f.currentStock} units) is at or below the reorder threshold (${f.reorderPoint} units). Order +$activeReorderQty units (₱${restockBudget.toStringAsFixed(2)}) to prevent hog farm supply interruptions.'
                      : 'Current stock (${f.currentStock} units) comfortably exceeds reorder threshold (${f.reorderPoint} units) including safety stock buffer (${f.safetyStock} units).',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: _titleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 9. Footer Action Buttons ---
  Widget _buildFooterActions(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_rounded, size: 16, color: _mutedColor),
          label: Text(
            'Back to Forecasts',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _mutedColor,
            ),
          ),
        ),
        const SizedBox(width: 14),
        ElevatedButton.icon(
          onPressed: _openRestockDialog,
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
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // --- Badges & Helpers ---
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        f.urgencyLabel,
        style: GoogleFonts.plusJakartaSans(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: _mutedColor,
          ),
        ),
      ],
    );
  }
}

String _formatChartDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}';
}

/// High-Definition Canvas Painter for Sales History & Dual Model Forecasting Curves
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
