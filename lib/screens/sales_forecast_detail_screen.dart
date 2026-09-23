import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/forecasting_model.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';

/// Clean & Easy-to-Understand Sales Forecast Detail Screen with SES, SMA, and WMA Models
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
  State<SalesForecastDetailScreen> createState() =>
      _SalesForecastDetailScreenState();
}

class _SalesForecastDetailScreenState extends State<SalesForecastDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 0: SES (Single Exponential Smoothing - Adaptive)
  // 1: SMA (Simple Moving Average - 14-Day)
  // 2: WMA (Weighted Moving Average - Linear Weights)
  // 3: Compare All (SES vs SMA vs WMA overlay)
  int _selectedCurveIndex = 0;

  // System Theme Helpers
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgDark =>
      _isDark ? PiggyTrunkTheme.ptBgDark : PiggyTrunkTheme.ptBg;
  Color get _panelStart => _isDark ? const Color(0xFF1A2940) : Colors.white;
  Color get _panelEnd => _isDark ? const Color(0xFF0F1C2F) : Colors.white;
  Color get _panelBorder =>
      _isDark ? const Color(0xFF2A3E5B) : const Color(0xFFC9D8EC);
  Color get _cardBorder =>
      _isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
  Color get _titleColor => _isDark ? Colors.white : const Color(0xFF18314F);
  Color get _mutedColor =>
      _isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);
  Color get _fieldBg =>
      _isDark ? const Color(0xFF1A2B44) : const Color(0xFFF5F8FE);

  @override
  Widget build(BuildContext context) {
    if (widget.isMobileEmbedded) {
      return PopScope(
        canPop: true,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: _bgDark,
          body: SafeArea(child: _buildMainContent()),
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
                  onLogout: () =>
                      Navigator.of(context).pushReplacementNamed('/login'),
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
                      onLogout: () =>
                          Navigator.of(context).pushReplacementNamed('/login'),
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
                borderRadius: BorderRadius.circular(isMobile ? 16 : 28),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 26,
                vertical: isMobile ? 16 : 26,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Clean Navigation (Back Button Only)
                  _buildNavigationRow(),
                  const SizedBox(height: 18),

                  // 2. Product Summary Header (Clean typography without pasted image & without runway badge)
                  _buildProductHeader(f, isMobile),
                  const SizedBox(height: 20),
                  Divider(color: _cardBorder, height: 1),
                  const SizedBox(height: 20),

                  // 3. Simple & Clear Key Metrics (Total Sold, Current Stock, Forecasted Need, Suggested Reorder)
                  _buildSimpleMetrics(f, isMobile),
                  const SizedBox(height: 22),

                  // 4. Easy-to-Understand Forecast Chart with Model Switcher (SES vs SMA vs WMA)
                  _buildEasyForecastChartSection(f, isMobile),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- 1. Clean Navigation Row (Back Button Only) ---
  Widget _buildNavigationRow() {
    return InkWell(
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
    );
  }

  // --- 2. Product Header (With product image & clean typography) ---
  Widget _buildProductHeader(ProductForecast f, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildProductThumbnail(
          f.imageUrl,
          size: isMobile ? 54 : 64,
          radius: 12,
        ),
        const SizedBox(width: 14),
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
      ],
    );
  }

  Widget _buildProductThumbnail(
    String? imageUrl, {
    double size = 64,
    double radius = 12,
  }) {
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      final isAsset = imageUrl.startsWith('assets/');
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _fieldBg,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: _cardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 1.2),
          child: isAsset
              ? Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => Center(
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: _mutedColor,
                      size: size * 0.45,
                    ),
                  ),
                )
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => Center(
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: _mutedColor,
                      size: size * 0.45,
                    ),
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
        border: Border.all(color: _cardBorder, width: 1.2),
      ),
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          color: _mutedColor,
          size: size * 0.45,
        ),
      ),
    );
  }

  // --- 3. Simple & Clear Business Metrics ---
  Widget _buildSimpleMetrics(ProductForecast f, bool isMobile) {
    // Dynamic expected demand based on active model
    final double activePredictedDemand = _selectedCurveIndex == 1
        ? f.smaPredictedDemand
        : (_selectedCurveIndex == 2 ? f.wmaPredictedDemand : f.predictedDemand);

    final cards = [
      _buildSimpleMetricCard(
        title: 'Units Sold',
        value: '${f.calculatedTotalSold} units',
        subtitle: 'Past 30 days sales',
        icon: Icons.shopping_bag_outlined,
        color: const Color(0xFF0284C7),
      ),
      _buildSimpleMetricCard(
        title: 'Current Stock',
        value: '${f.currentStock} units',
        subtitle: 'Available in inventory',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF6366F1),
      ),
      _buildSimpleMetricCard(
        title: 'Expected Demand',
        value: '~${activePredictedDemand.round()} units',
        subtitle: _selectedCurveIndex == 1
            ? 'SMA 14-day projection'
            : (_selectedCurveIndex == 2
                  ? 'WMA weighted projection'
                  : 'SES optimal projection'),
        icon: Icons.trending_up_rounded,
        color: _selectedCurveIndex == 1
            ? const Color(0xFFF59E0B)
            : (_selectedCurveIndex == 2
                  ? const Color(0xFFA855F7)
                  : const Color(0xFF10B981)),
      ),
      _buildSimpleMetricCard(
        title: 'Suggested Reorder',
        value: f.recommendedReorderQty > 0
            ? '+${f.recommendedReorderQty} units'
            : 'Stock Sufficient',
        subtitle: f.recommendedReorderQty > 0
            ? 'Below threshold (${f.reorderPoint} units)'
            : 'Comfortably stocked',
        icon: f.recommendedReorderQty > 0
            ? Icons.add_circle_outline_rounded
            : Icons.check_circle_outline_rounded,
        color: f.recommendedReorderQty > 0
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981),
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 8),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 8),
          Row(
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
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 12),
        Expanded(child: cards[1]),
        const SizedBox(width: 12),
        Expanded(child: cards[2]),
        const SizedBox(width: 12),
        Expanded(child: cards[3]),
      ],
    );
  }

  Widget _buildSimpleMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _mutedColor,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
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

  // --- 4. Easy-to-Understand Forecast Chart Section with Model Selector (SES / SMA / WMA) ---
  Widget _buildEasyForecastChartSection(ProductForecast f, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF0F1A29) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Clean Title & Friendly Legends
          Wrap(
            spacing: 16,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sales History & 30-Day Demand Forecast',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: f.hasDetailedHistoricalSales
                              ? (_isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE0EDFD))
                              : (_isDark ? const Color(0xFF3E2D1A) : const Color(0xFFFEF3C7)),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              f.hasDetailedHistoricalSales ? Icons.insights_rounded : Icons.star_rounded,
                              size: 11,
                              color: f.hasDetailedHistoricalSales
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Data Used: ${f.hasDetailedHistoricalSales ? 'Historical Sales Data (POS Logs)' : 'Top-Selling Items Data'}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: f.hasDetailedHistoricalSales
                                    ? (_isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8))
                                    : (_isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Feeding into SES, SMA, and WMA models',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _mutedColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Clean Model Curve Selector Pills
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildCurveChip(0, 'SES (Adaptive)', const Color(0xFF10B981)),
                  _buildCurveChip(1, 'SMA (14-Day)', const Color(0xFFF59E0B)),
                  _buildCurveChip(2, 'WMA (Weighted)', const Color(0xFFA855F7)),
                  _buildCurveChip(3, 'Compare All', const Color(0xFF38BDF8)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dynamic Active Legends
          Wrap(
            spacing: 14,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildLegendDot(
                _isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                'Actual Sales (Past 30 Days)',
              ),
              if (_selectedCurveIndex == 0 || _selectedCurveIndex == 3)
                _buildLegendDot(
                  const Color(0xFF10B981),
                  'SES Forecast (~${f.predictedDemand.round()} units)',
                ),
              if (_selectedCurveIndex == 1 || _selectedCurveIndex == 3)
                _buildLegendDot(
                  const Color(0xFFF59E0B),
                  'SMA Forecast (~${f.smaPredictedDemand.round()} units)',
                ),
              if (_selectedCurveIndex == 2 || _selectedCurveIndex == 3)
                _buildLegendDot(
                  const Color(0xFFA855F7),
                  'WMA Forecast (~${f.wmaPredictedDemand.round()} units)',
                ),
            ],
          ),
          const SizedBox(height: 16),

          // High-Definition, Easy-to-Understand Canvas Chart
          Container(
            height: isMobile ? 220 : 280,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF0C1626) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _cardBorder.withValues(alpha: 0.6)),
            ),
            child: CustomPaint(
              painter: SimpleForecastChartPainter(
                historyPoints: f.historicalDailySales,
                sesPoints: f.projectedDailySales,
                smaPoints: f.smaProjectedDailySales,
                wmaPoints: f.wmaProjectedDailySales,
                selectedCurveIndex: _selectedCurveIndex,
                isDark: _isDark,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Simple Summary Explanation Callout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _getCalloutColor().withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _getCalloutColor().withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: _getCalloutColor(),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getCalloutMessage(f),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _titleColor,
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

  Widget _buildCurveChip(int index, String label, Color color) {
    final isSelected = _selectedCurveIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedCurveIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.16)
              : (_isDark ? const Color(0xFF162338) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : _cardBorder,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? _titleColor : _mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCalloutColor() {
    switch (_selectedCurveIndex) {
      case 1:
        return const Color(0xFFF59E0B);
      case 2:
        return const Color(0xFFA855F7);
      case 3:
        return const Color(0xFF38BDF8);
      default:
        return const Color(0xFF10B981);
    }
  }

  String _getCalloutMessage(ProductForecast f) {
    final sourceName = f.hasDetailedHistoricalSales
        ? 'Historical Sales Data (Daily POS & distribution logs)'
        : (f.calculatedTotalSold > 0 ? 'Top-Selling Items Data (Cumulative sales volume)' : 'Baseline Inventory');

    if (f.calculatedTotalSold <= 0) {
      return 'Data Source: Baseline Inventory (0 sales recorded in 30 days). Current stock is ${f.currentStock} units. As actual sales occur, SES, SMA, and WMA projections will automatically adapt to demand.';
    }

    switch (_selectedCurveIndex) {
      case 1:
        return 'SMA (Simple Moving Average): Projects ~${f.smaPredictedDemand.round()} units based on a flat 14-day average of $sourceName. Useful for baseline demand, but reacts slower to sudden surges in feed intake.';
      case 2:
        return 'WMA (Weighted Moving Average): Projects ~${f.wmaPredictedDemand.round()} units with higher weights on recent days of $sourceName. Provides a balanced linear response between SMA and SES.';
      case 3:
        return 'Model Comparison: All 3 methods (SES, SMA, WMA) are computed from $sourceName. SES (~${f.predictedDemand.round()} units) responds fastest to feed spikes, WMA (~${f.wmaPredictedDemand.round()} units) applies weighted progression, and SMA acts as baseline average.';
      default:
        return 'SES (Single Exponential Smoothing): Optimal recommendation of ~${f.predictedDemand.round()} units based on $sourceName. Adapts 30% to recent swine feed demand spikes, preventing warehouse stockouts as hogs grow.';
    }
  }

  // --- Badges & Helpers ---
  Widget _buildStatusBadge(ProductForecast f) {
    final isOutOfStock = f.currentStock <= 0;
    final isLowStock =
        f.urgency == UrgencyLevel.critical || f.urgency == UrgencyLevel.reorder;
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

String _formatSimpleDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}';
}

/// Simple, Clean & Easy-to-Understand Canvas Chart Painter supporting SES, SMA, and WMA
class SimpleForecastChartPainter extends CustomPainter {
  final List<DailySalesPoint> historyPoints;
  final List<DailySalesPoint> sesPoints;
  final List<DailySalesPoint> smaPoints;
  final List<DailySalesPoint> wmaPoints;
  final int selectedCurveIndex; // 0: SES, 1: SMA, 2: WMA, 3: Compare All
  final bool isDark;

  SimpleForecastChartPainter({
    required this.historyPoints,
    required this.sesPoints,
    required this.smaPoints,
    required this.wmaPoints,
    required this.selectedCurveIndex,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final totalPointsCount = historyPoints.length + sesPoints.length;
    if (totalPointsCount == 0) return;

    // 1. Calculate Maximum Value with headroom & clean integer step intervals
    double rawMax = 1.0;
    for (final pt in historyPoints) {
      if (pt.quantity > rawMax) rawMax = pt.quantity.toDouble();
    }
    for (final pt in sesPoints) {
      if (pt.quantity > rawMax) rawMax = pt.quantity.toDouble();
    }
    for (final pt in smaPoints) {
      if (pt.quantity > rawMax) rawMax = pt.quantity.toDouble();
    }
    for (final pt in wmaPoints) {
      if (pt.quantity > rawMax) rawMax = pt.quantity.toDouble();
    }

    // Determine clean integer step for 4 equal intervals (5 grid lines: 0, 1, 2, 3, 4)
    // Ensures clean numbers without skipping (e.g., 4, 3, 2, 1, 0 or 8, 6, 4, 2, 0 units)
    int step = (rawMax / 4.0).ceil();
    if (step < 1) step = 1;
    if (step * 4 <= rawMax) {
      step += 1;
    }
    final double maxVal = (step * 4).toDouble();

    // 2. Chart Paddings
    const double padBottom = 30.0;
    const double padTop = 26.0;
    const double padLeft = 64.0;
    const double padRight = 20.0;

    final double chartWidth = max(10.0, size.width - padLeft - padRight);
    final double chartHeight = max(10.0, size.height - padTop - padBottom);

    // 3. Draw Horizontal Grid Lines & Y-Axis Labels
    final gridPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.07)
          : Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    final yLabelStyle = GoogleFonts.plusJakartaSans(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
    );

    for (int i = 0; i <= 4; i++) {
      final y = padTop + (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(padLeft, y),
        Offset(size.width - padRight, y),
        gridPaint,
      );

      final val = step * (4 - i);
      final unitLabel = '$val ${val == 1 ? 'unit' : 'units'}';
      final tp = TextPainter(
        text: TextSpan(text: unitLabel, style: yLabelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(padLeft - tp.width - 8, y - (tp.height / 2)));
    }

    final double totalPoints = totalPointsCount.toDouble();
    final double todayX =
        padLeft + (historyPoints.length / totalPoints) * chartWidth;
    final double baselineY = padTop + chartHeight;

    // 4. Draw Vertical "TODAY" Divider
    final todayLinePaint = Paint()
      ..color = (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB))
          .withValues(alpha: 0.5)
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
      Offset(
        todayX - (todayText.width / 2),
        padTop - 11 - (todayText.height / 2),
      ),
    );

    // 5. Draw Actual Historical Sales Bars (Past 30 Days)
    final double barWidth = max(
      2.5,
      min(8.0, (chartWidth / totalPoints) * 0.52),
    );
    final barPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
          (isDark ? const Color(0xFF0284C7) : const Color(0xFF0369A1))
              .withValues(alpha: 0.7),
        ],
      ).createShader(Rect.fromLTWH(padLeft, padTop, chartWidth, chartHeight))
      ..style = PaintingStyle.fill;

    for (int i = 0; i < historyPoints.length; i++) {
      final pt = historyPoints[i];
      final x = padLeft + (i / totalPoints) * chartWidth + (barWidth / 2);
      final barH = (pt.quantity / maxVal) * chartHeight;
      final y = baselineY - barH;

      final rrect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x - (barWidth / 2), y, barWidth, barH),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(rrect, barPaint);
    }

    // Precalculate historical model values so lines start from index 0 (Day 1)
    final List<double> sesHist = [];
    if (historyPoints.isNotEmpty) {
      double s = historyPoints.first.quantity.toDouble();
      sesHist.add(s);
      for (int i = 1; i < historyPoints.length; i++) {
        s = (0.3 * historyPoints[i].quantity) + (0.7 * s);
        sesHist.add(s);
      }
    }

    final List<double> smaHist = [];
    for (int i = 0; i < historyPoints.length; i++) {
      final start = max(0, i - 13);
      double sum = 0;
      int count = 0;
      for (int k = start; k <= i; k++) {
        sum += historyPoints[k].quantity;
        count++;
      }
      smaHist.add(count > 0 ? sum / count : 0.0);
    }

    final List<double> wmaHist = [];
    for (int i = 0; i < historyPoints.length; i++) {
      final start = max(0, i - 13);
      double weightedSum = 0;
      int weightSum = 0;
      int w = 1;
      for (int k = start; k <= i; k++) {
        weightedSum += historyPoints[k].quantity * w;
        weightSum += w;
        w++;
      }
      wmaHist.add(weightSum > 0 ? weightedSum / weightSum : 0.0);
    }

    // Helper to draw forecast curves starting from Day 1 through future projection
    void drawForecastCurve(
      List<double> histValues,
      List<DailySalesPoint> pts,
      Color color, {
      bool withFill = false,
      bool isCompare = false,
      bool highlightNextDate = false,
    }) {
      if (histValues.isEmpty && pts.isEmpty) return;

      final linePaint = Paint()
        ..color = color
        ..strokeWidth = isCompare ? 2.0 : 2.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final linePath = Path();
      final fillPath = Path();

      final List<Offset> allPoints = [];
      final List<Offset> futurePoints = [];

      // 1. Trace from Day 1 through History
      for (int i = 0; i < histValues.length; i++) {
        final x = padLeft + (i / totalPoints) * chartWidth + (barWidth / 2);
        final y = baselineY - ((histValues[i] / maxVal) * chartHeight);
        final off = Offset(x, y);
        allPoints.add(off);

        if (i == 0) {
          linePath.moveTo(x, y);
        } else {
          linePath.lineTo(x, y);
        }
      }

      // 2. Trace into Future Horizon
      Offset? firstFuturePoint;
      for (int j = 0; j < pts.length; j++) {
        final pt = pts[j];
        final index = historyPoints.length + j;
        final x = padLeft + (index / totalPoints) * chartWidth + (barWidth / 2);
        final y = baselineY - ((pt.quantity / maxVal) * chartHeight);
        final off = Offset(x, y);
        allPoints.add(off);
        futurePoints.add(off);

        if (j == 0) {
          firstFuturePoint = off;
          if (allPoints.length == 1) {
            linePath.moveTo(x, y);
          } else {
            linePath.lineTo(x, y);
          }

          fillPath.moveTo(todayX, baselineY);
          if (histValues.isNotEmpty) {
            final lastHist = allPoints[histValues.length - 1];
            fillPath.lineTo(lastHist.dx, lastHist.dy);
          }
          fillPath.lineTo(x, y);
        } else {
          linePath.lineTo(x, y);
          fillPath.lineTo(x, y);
        }
      }

      // 3. Draw Fill under the forecast projection
      if (withFill && futurePoints.isNotEmpty) {
        fillPath.lineTo(futurePoints.last.dx, baselineY);
        fillPath.close();

        final fillPaint = Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.02),
                ],
              ).createShader(
                Rect.fromLTWH(padLeft, padTop, chartWidth, chartHeight),
              )
          ..style = PaintingStyle.fill;

        canvas.drawPath(fillPath, fillPaint);
      }

      // 4. Draw the full continuous curve
      canvas.drawPath(linePath, linePaint);

      // 5. Draw future point nodes
      final nodeFill = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      for (final off in futurePoints) {
        canvas.drawCircle(off, isCompare ? 1.8 : 2.2, nodeFill);
      }

      // 6. Highlight the immediate NEXT forecast date (Tomorrow)
      if (highlightNextDate && firstFuturePoint != null && pts.isNotEmpty) {
        final nextPt = pts.first;

        // Glowing outer halo
        final haloPaint = Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(firstFuturePoint, 7.0, haloPaint);

        // Core bright dot
        final corePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(firstFuturePoint, 3.5, corePaint);
        canvas.drawCircle(firstFuturePoint, 2.2, nodeFill);

        // Clear Callout Badge: "Next: <Date> (<Qty> units)"
        final nextDateStr = _formatSimpleDate(nextPt.date);
        final calloutText =
            'Next: $nextDateStr (${nextPt.quantity} ${nextPt.quantity == 1 ? 'unit' : 'units'})';

        final tp = TextPainter(
          text: TextSpan(
            text: calloutText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final pillW = tp.width + 14;
        final pillH = tp.height + 7;

        double pillY = firstFuturePoint.dy - pillH - 8;
        if (pillY < padTop + 2) {
          pillY = firstFuturePoint.dy + 10;
        }

        double pillX = firstFuturePoint.dx - (pillW / 2);
        if (pillX < padLeft + 4) pillX = padLeft + 4;
        if (pillX + pillW > size.width - padRight - 4) {
          pillX = size.width - padRight - 4 - pillW;
        }

        final pillRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(pillX, pillY, pillW, pillH),
          const Radius.circular(6),
        );

        final pillBg = Paint()
          ..color = (isDark ? const Color(0xFF0F172A) : Colors.white)
              .withValues(alpha: 0.95)
          ..style = PaintingStyle.fill;
        final pillBorder = Paint()
          ..color = color
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;

        canvas.drawRRect(pillRect, pillBg);
        canvas.drawRRect(pillRect, pillBorder);
        tp.paint(canvas, Offset(pillX + 7, pillY + 3.5));
      }
    }

    // 6. Draw Curves based on selected model
    final bool isCompareAll = selectedCurveIndex == 3;

    // SMA (Amber)
    if (selectedCurveIndex == 1 || isCompareAll) {
      drawForecastCurve(
        smaHist,
        smaPoints,
        const Color(0xFFF59E0B),
        withFill: selectedCurveIndex == 1,
        isCompare: isCompareAll,
        highlightNextDate: selectedCurveIndex == 1,
      );
    }

    // WMA (Purple)
    if (selectedCurveIndex == 2 || isCompareAll) {
      drawForecastCurve(
        wmaHist,
        wmaPoints,
        const Color(0xFFA855F7),
        withFill: selectedCurveIndex == 2,
        isCompare: isCompareAll,
        highlightNextDate: selectedCurveIndex == 2,
      );
    }

    // SES (Emerald Green)
    if (selectedCurveIndex == 0 || isCompareAll) {
      drawForecastCurve(
        sesHist,
        sesPoints,
        const Color(0xFF10B981),
        withFill: selectedCurveIndex == 0,
        isCompare: isCompareAll,
        highlightNextDate: selectedCurveIndex == 0 || isCompareAll,
      );
    }

    // 7. Draw Clean X-Axis Timeline Dates
    final allSamplePoints = [...historyPoints, ...sesPoints];
    if (allSamplePoints.isNotEmpty) {
      final sampleIndices = <int>[
        0,
        (historyPoints.length ~/ 2),
        historyPoints.length - 1,
        min(
          allSamplePoints.length - 1,
          historyPoints.length + (sesPoints.length ~/ 2),
        ),
        allSamplePoints.length - 1,
      ];

      for (final idx in sampleIndices) {
        if (idx < 0 || idx >= allSamplePoints.length) continue;
        final pt = allSamplePoints[idx];
        final x = padLeft + (idx / totalPoints) * chartWidth + (barWidth / 2);
        final dtStr = _formatSimpleDate(pt.date);

        final isToday = idx == historyPoints.length - 1;
        final tp = TextPainter(
          text: TextSpan(
            text: isToday ? '$dtStr (Today)' : dtStr,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              color: isToday
                  ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8))
                  : (isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B)),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        tp.paint(canvas, Offset(x - (tp.width / 2), baselineY + 8));
      }
    }
  }

  @override
  bool shouldRepaint(covariant SimpleForecastChartPainter oldDelegate) => true;
}
