import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/forecasting_model.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';

/// Clean & Easy-to-Understand Sales Forecast Detail Screen
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
                  // 1. Clean Navigation (Back Button Only - No "Sales Forecast Deep Dive" badge)
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

                  // 4. Easy-to-Understand Forecast Chart
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

  // --- 2. Product Header (Clean typography, no pasted image, no runway badge) ---
  Widget _buildProductHeader(ProductForecast f, bool isMobile) {
    return Column(
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
    );
  }

  // --- 3. Simple & Clear Business Metrics ---
  Widget _buildSimpleMetrics(ProductForecast f, bool isMobile) {
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
        value: '~${f.predictedDemand.round()} units',
        subtitle: 'Projected for next ${f.horizonDays} days',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF10B981),
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

  // --- 4. Easy-to-Understand Forecast Chart Section ---
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
            runSpacing: 8,
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
                  const SizedBox(height: 2),
                  Text(
                    'Blue bars show your past sales. The green line shows estimated upcoming demand.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: _mutedColor,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendDot(
                    _isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                    'Actual Sales (Past 30 Days)',
                  ),
                  const SizedBox(width: 14),
                  _buildLegendDot(
                    const Color(0xFF10B981),
                    'Forecast (Next 30 Days)',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

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
                projectedPoints: f.projectedDailySales,
                isDark: _isDark,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Simple Summary Explanation Callout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    f.calculatedTotalSold > 0
                        ? 'Based on recent sales (${f.calculatedTotalSold} units sold), estimated demand for the next 30 days is ~${f.predictedDemand.round()} units. '
                            '${f.recommendedReorderQty > 0 ? "Replenish +${f.recommendedReorderQty} units to prevent stockouts." : "Your stock (${f.currentStock} units) is sufficient."}'
                        : 'No sales recorded yet in the past 30 days. Current stock is ${f.currentStock} units. As sales occur, the forecast will automatically adjust to expected demand.',
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

String _formatSimpleDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day}';
}

/// Simple, Clean & Easy-to-Understand Canvas Chart Painter
class SimpleForecastChartPainter extends CustomPainter {
  final List<DailySalesPoint> historyPoints;
  final List<DailySalesPoint> projectedPoints;
  final bool isDark;

  SimpleForecastChartPainter({
    required this.historyPoints,
    required this.projectedPoints,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final totalPointsCount = historyPoints.length + projectedPoints.length;
    if (totalPointsCount == 0) return;

    // 1. Calculate Maximum Value with headroom
    double maxVal = 1.0;
    for (final pt in historyPoints) {
      if (pt.quantity > maxVal) maxVal = pt.quantity.toDouble();
    }
    for (final pt in projectedPoints) {
      if (pt.quantity > maxVal) maxVal = pt.quantity.toDouble();
    }
    maxVal = maxVal * 1.3;
    if (maxVal < 4.0) maxVal = 4.0;

    // 2. Chart Paddings
    const double padBottom = 30.0;
    const double padTop = 26.0;
    const double padLeft = 44.0;
    const double padRight = 18.0;

    final double chartWidth = max(10.0, size.width - padLeft - padRight);
    final double chartHeight = max(10.0, size.height - padTop - padBottom);

    // 3. Draw Horizontal Grid Lines & Y-Axis Labels
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.05)
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

    // 4. Draw Vertical "TODAY" Divider
    final todayLinePaint = Paint()
      ..color = (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)).withValues(alpha: 0.5)
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

    // 5. Draw Actual Historical Sales Bars (Past 30 Days)
    final double barWidth = max(2.5, min(8.0, (chartWidth / totalPoints) * 0.52));
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

    // 6. Draw Clean Forecast Demand Curve (Next 30 Days)
    if (projectedPoints.isNotEmpty) {
      final forecastLinePaint = Paint()
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

      final List<Offset> points = [];

      for (int j = 0; j < projectedPoints.length; j++) {
        final pt = projectedPoints[j];
        final index = historyPoints.length + j;
        final x = padLeft + (index / totalPoints) * chartWidth + (barWidth / 2);
        final y = baselineY - ((pt.quantity / maxVal) * chartHeight);
        final offset = Offset(x, y);
        points.add(offset);
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (points.isNotEmpty) {
        fillPath.lineTo(points.last.dx, baselineY);
        fillPath.close();

        final fillPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF10B981).withValues(alpha: 0.28),
              const Color(0xFF10B981).withValues(alpha: 0.02),
            ],
          ).createShader(Rect.fromLTWH(padLeft, padTop, chartWidth, chartHeight))
          ..style = PaintingStyle.fill;

        canvas.drawPath(fillPath, fillPaint);
      }

      canvas.drawPath(linePath, forecastLinePaint);

      // Draw subtle nodes
      final nodeFill = Paint()..color = const Color(0xFF10B981)..style = PaintingStyle.fill;
      for (final off in points) {
        canvas.drawCircle(off, 2.5, nodeFill);
      }
    }

    // 7. Draw Clean X-Axis Timeline Dates
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
        final dtStr = _formatSimpleDate(pt.date);

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
  bool shouldRepaint(covariant SimpleForecastChartPainter oldDelegate) => true;
}
