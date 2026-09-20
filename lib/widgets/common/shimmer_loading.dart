import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Provides a synchronized continuous shimmer animation for all descendant [ShimmerBox] widgets.
class ShimmerProvider extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerProvider({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
  });

  static Animation<double>? of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_ShimmerScope>();
    return scope?.animation;
  }

  @override
  State<ShimmerProvider> createState() => _ShimmerProviderState();
}

class _ShimmerProviderState extends State<ShimmerProvider>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      animation: _controller,
      child: widget.child,
    );
  }
}

class _ShimmerScope extends InheritedWidget {
  final Animation<double> animation;

  const _ShimmerScope({
    required this.animation,
    required super.child,
  });

  @override
  bool updateShouldNotify(_ShimmerScope oldWidget) =>
      animation != oldWidget.animation;
}

/// A placeholder element (pill, box, or circle) that displays a sweeping gradient shimmer.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxShape shape;
  final bool? isDark;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final anim = ShimmerProvider.of(context);
    final dark = isDark ?? (Theme.of(context).brightness == Brightness.dark);

    final baseColor = dark ? const Color(0xFF1E2D44) : const Color(0xFFE2E8F0);
    final highlightColor = dark ? const Color(0xFF2C4161) : const Color(0xFFF8FAFC);

    if (anim == null) {
      return _StandaloneShimmerBox(
        width: width,
        height: height,
        borderRadius: borderRadius,
        shape: shape,
        baseColor: baseColor,
        highlightColor: highlightColor,
      );
    }

    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: shape == BoxShape.circle
                ? null
                : (borderRadius ?? BorderRadius.circular(6)),
            gradient: LinearGradient(
              begin: Alignment(-2.0 + 4.0 * anim.value, -0.3),
              end: Alignment(0.0 + 4.0 * anim.value, 0.3),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class _StandaloneShimmerBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxShape shape;
  final Color baseColor;
  final Color highlightColor;

  const _StandaloneShimmerBox({
    this.width,
    required this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<_StandaloneShimmerBox> createState() => _StandaloneShimmerBoxState();
}

class _StandaloneShimmerBoxState extends State<_StandaloneShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : (widget.borderRadius ?? BorderRadius.circular(6)),
            gradient: LinearGradient(
              begin: Alignment(-2.0 + 4.0 * _controller.value, -0.3),
              end: Alignment(0.0 + 4.0 * _controller.value, 0.3),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// A comprehensive, responsive table skeleton loader designed to match Piggy-Trunk's data tables.
/// Supports both Flex rows and Table column width layouts with zero layout shift and ZERO overflow.
class TableSkeletonLoader extends StatelessWidget {
  final bool? isDark;
  final List<String>? headers;
  final List<int>? columnFlexes;
  final Map<int, TableColumnWidth>? columnWidths;
  final int rowCount;
  final int? actionButtonCount;
  final double minWidth;
  final double borderRadius;
  final Color? cardBg;
  final Color? cardBorder;
  final Color? headerBg;

  const TableSkeletonLoader({
    super.key,
    this.isDark,
    this.headers,
    this.columnFlexes,
    this.columnWidths,
    this.rowCount = 5,
    this.actionButtonCount,
    this.minWidth = 720.0,
    this.borderRadius = 18.0,
    this.cardBg,
    this.cardBorder,
    this.headerBg,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final effectiveCardBg = cardBg ??
        (dark ? const Color(0xFF151F2E) : Colors.white);
    final effectiveBorder = cardBorder ??
        (dark ? const Color(0xFF28354A) : const Color(0xFFE6EBF2));
    final effectiveHeaderBg = headerBg ??
        (dark ? const Color(0xFF1B2E48) : const Color(0xFFEDF4FC));
    final headerTextColor =
        dark ? const Color(0xFF9CB0C9) : const Color(0xFF6F8096);

    final headerCount = headers?.length ?? columnFlexes?.length ?? (columnWidths?.length ?? 5);

    return ShimmerProvider(
      child: Container(
        decoration: BoxDecoration(
          color: effectiveCardBg,
          border: Border.all(color: effectiveBorder),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - 1),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = constraints.maxWidth > minWidth
                  ? constraints.maxWidth
                  : minWidth;

              if (columnWidths != null) {
                // Table layout mode
                return Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: Table(
                        columnWidths: columnWidths!,
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: [
                          if (headers != null && headers!.isNotEmpty)
                            TableRow(
                              decoration: BoxDecoration(
                                color: effectiveHeaderBg,
                                border: Border(
                                  bottom: BorderSide(color: effectiveBorder),
                                ),
                              ),
                              children: List.generate(headers!.length, (i) {
                                final isCenter = i >= headers!.length - 2;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 13,
                                  ),
                                  child: Align(
                                    alignment: isCenter
                                        ? Alignment.center
                                        : Alignment.centerLeft,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: isCenter
                                          ? Alignment.center
                                          : Alignment.centerLeft,
                                      child: Text(
                                        headers![i],
                                        softWrap: false,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: headerTextColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.7,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ...List.generate(rowCount, (rowIndex) {
                            return TableRow(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: effectiveBorder.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                              children: List.generate(headerCount, (colIndex) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  child: _buildCellSkeleton(
                                    colIndex: colIndex,
                                    totalCols: headerCount,
                                    dark: dark,
                                    rowIndex: rowIndex,
                                  ),
                                );
                              }),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Row + Expanded layout mode
              final flexes = columnFlexes ??
                  _getDefaultFlexes(headerCount);

              return Scrollbar(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (headers != null && headers!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: effectiveHeaderBg,
                              border: Border(
                                bottom: BorderSide(color: effectiveBorder, width: 1.2),
                              ),
                            ),
                            child: Row(
                              children: List.generate(headers!.length, (i) {
                                final isCenter = i >= headers!.length - 2;
                                return Expanded(
                                  flex: i < flexes.length ? flexes[i] : 2,
                                  child: Align(
                                    alignment: isCenter
                                        ? Alignment.center
                                        : Alignment.centerLeft,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: isCenter
                                          ? Alignment.center
                                          : Alignment.centerLeft,
                                      child: Text(
                                        headers![i],
                                        softWrap: false,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: headerTextColor,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ...List.generate(rowCount, (rowIndex) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: effectiveBorder.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            child: Row(
                              children: List.generate(headerCount, (colIndex) {
                                return Expanded(
                                  flex: colIndex < flexes.length
                                      ? flexes[colIndex]
                                      : 2,
                                  child: _buildCellSkeleton(
                                    colIndex: colIndex,
                                    totalCols: headerCount,
                                    dark: dark,
                                    rowIndex: rowIndex,
                                  ),
                                );
                              }),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<int> _getDefaultFlexes(int count) {
    if (count == 4) return [4, 3, 2, 2];
    if (count == 5) return [3, 2, 2, 2, 2];
    if (count == 6) return [3, 2, 2, 2, 2, 2];
    return List.filled(count, 2);
  }

  Widget _buildCellSkeleton({
    required int colIndex,
    required int totalCols,
    required bool dark,
    required int rowIndex,
  }) {
    final currentHeader = (headers != null && colIndex < headers!.length)
        ? headers![colIndex].toUpperCase()
        : '';
    final isActionsCol = currentHeader.contains('ACTION') ||
        (headers == null && colIndex == totalCols - 1);
    final isStatusCol = currentHeader.contains('STATUS') ||
        (headers == null && colIndex == totalCols - 2);

    // Actions column: clean, pure square shimmering placeholders mirroring real 30x30/32x32 action buttons (NO static eye or pencil icons)
    if (isActionsCol) {
      final btnCount = actionButtonCount ??
          ((headers != null && headers!.length <= 4) ? 1 : 3);
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              btnCount,
              (i) => Padding(
                padding: EdgeInsets.only(left: i > 0 ? 6.0 : 0.0),
                child: ShimmerBox(
                  width: 30,
                  height: 30,
                  borderRadius: BorderRadius.circular(8),
                  isDark: dark,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Status column: Centered status badge pill
    if (isStatusCol) {
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ShimmerBox(
            width: 64,
            height: 22,
            borderRadius: BorderRadius.circular(11),
            isDark: dark,
          ),
        ),
      );
    }

    // All standard data columns (Col 0, Col 1, Col 2, etc.):
    // Use FittedBox to guarantee ZERO overflow regardless of column width!
    final widths = [85.0, 70.0, 95.0, 60.0, 80.0];
    final w = widths[(colIndex + rowIndex) % widths.length];

    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: ShimmerBox(
          width: w,
          height: 12,
          borderRadius: BorderRadius.circular(4),
          isDark: dark,
        ),
      ),
    );
  }
}

/// A skeleton loader for metric or info cards.
class CardSkeletonLoader extends StatelessWidget {
  final bool? isDark;
  final double? width;
  final double height;
  final double borderRadius;

  const CardSkeletonLoader({
    super.key,
    this.isDark,
    this.width,
    this.height = 130.0,
    this.borderRadius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final cardBg = dark ? const Color(0xFF151F2E) : Colors.white;
    final cardBorder = dark ? const Color(0xFF28354A) : const Color(0xFFE6EBF2);

    return ShimmerProvider(
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border.all(color: cardBorder),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(
                  width: 36,
                  height: 36,
                  shape: BoxShape.circle,
                  isDark: dark,
                ),
                ShimmerBox(
                  width: 48,
                  height: 20,
                  borderRadius: BorderRadius.circular(10),
                  isDark: dark,
                ),
              ],
            ),
            const Spacer(),
            ShimmerBox(
              width: 80,
              height: 12,
              borderRadius: BorderRadius.circular(4),
              isDark: dark,
            ),
            const SizedBox(height: 8),
            ShimmerBox(
              width: 120,
              height: 22,
              borderRadius: BorderRadius.circular(4),
              isDark: dark,
            ),
          ],
        ),
      ),
    );
  }
}
