import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pos_model.dart';
import '../theme/app_theme.dart';
import '../utils/app_toast.dart';
import '../utils/inventory_data_adapter.dart';
import '../utils/responsive.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';

class BestSellersScreen extends StatefulWidget {
  final List<POSProduct>? initialProducts;

  const BestSellersScreen({
    super.key,
    this.initialProducts,
  });

  @override
  State<BestSellersScreen> createState() => _BestSellersScreenState();
}

class _BestSellersScreenState extends State<BestSellersScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<POSProduct> _products = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _isDark ? PiggyTrunkTheme.ptBgDark : const Color(0xFFF4F7FB);
  Color get _surface => _isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
  Color get _border => _isDark ? PiggyTrunkTheme.ptBorderDark : const Color(0xFFD7E3F3);
  Color get _text => _isDark ? PiggyTrunkTheme.ptTextDark : const Color(0xFF18314F);
  Color get _muted => _isDark ? PiggyTrunkTheme.ptMutedDark : const Color(0xFF6F8096);
  Color get _brandPrimary => _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary;

  @override
  void initState() {
    super.initState();
    if (widget.initialProducts != null && widget.initialProducts!.isNotEmpty) {
      _products = widget.initialProducts!;
      _isLoading = false;
    } else {
      _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await _loadInventoryRows();
      final rows = response.map((row) => POSProduct.fromJson(row)).toList();
      if (!mounted) return;
      setState(() => _products = rows);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to load best sellers: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadInventoryRows() async {
    try {
      final response = await _supabase
          .from('inventory_products')
          .select()
          .order('sold', ascending: false);

      final rows = (response as List).where((row) {
        final isArchived = row['is_archived'] == true;
        return !isArchived;
      }).toList();
      return normalizeInventoryRows(rows, sourceTable: 'inventory_products');
    } catch (e) {
      final fallbackResponse = await _supabase.from('products').select().order('sold', ascending: false);
      final fallbackRows = (fallbackResponse as List).where((row) {
        final isArchived = row['is_archived'] == true;
        return !isArchived;
      }).toList();
      return normalizeInventoryRows(fallbackRows, sourceTable: 'products');
    }
  }

  List<String> get _categories {
    final cats = _products.map((p) => p.category.trim()).where((c) => c.isNotEmpty).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  List<POSProduct> get _rankedProducts {
    var list = List<POSProduct>.from(_products);

    // Filter by Category
    if (_selectedCategory != 'All') {
      list = list.where((p) => p.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }

    // Sort by sold count descending, then by total revenue (price * sold) descending
    list.sort((a, b) {
      final cmp = b.sold.compareTo(a.sold);
      if (cmp != 0) return cmp;
      final revA = a.price * a.sold;
      final revB = b.price * b.sold;
      return revB.compareTo(revA);
    });

    return list;
  }

  int get _totalSoldUnits => _products.fold<int>(0, (sum, p) => sum + p.sold);
  double get _totalRevenue => _products.fold<double>(0.0, (sum, p) => sum + (p.price * p.sold));

  POSProduct? get _topProduct {
    if (_products.isEmpty) return null;
    final sorted = List<POSProduct>.from(_products)..sort((a, b) => b.sold.compareTo(a.sold));
    return sorted.first.sold > 0 ? sorted.first : sorted.first;
  }

  String get _topCategory {
    if (_products.isEmpty) return 'None';
    final Map<String, int> catCounts = {};
    for (final p in _products) {
      catCounts[p.category] = (catCounts[p.category] ?? 0) + p.sold;
    }
    if (catCounts.isEmpty) return 'None';
    final entries = catCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key.isNotEmpty ? entries.first.key : 'Feeds';
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = Responsive.isSmallScreen(context);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: _bg,
      drawer: isSmall
          ? Drawer(
              backgroundColor: _surface,
              child: AdminSidebar(
                currentRoute: '/pos',
                onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isSmall)
            AdminSidebar(
              currentRoute: '/pos',
              onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
            ),
          Expanded(
            child: Column(
              children: [
                const ScreenTopBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 24,
                            vertical: isMobile ? 14 : 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Bar Header & Back Button
                              _buildHeader(isMobile),
                              const SizedBox(height: 18),

                              // KPI Metric Summary Cards
                              _buildKpiMetrics(isMobile),
                              const SizedBox(height: 24),

                              // Category Pills (Balanced Spacing)
                              _buildCategoryPills(),
                              const SizedBox(height: 20),

                              // Top 3 Podium Spotlight (if available)
                              if (_rankedProducts.isNotEmpty) ...[
                                _buildPodiumSection(isMobile),
                                const SizedBox(height: 24),
                              ],

                              // Full Leaderboard Table / Cards
                              _buildLeaderboardSection(isMobile),
                            ],
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

  Widget _buildHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isDark ? const Color(0xFF1E2F47) : const Color(0xFFEEF4FD),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: _brandPrimary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Best Selling Products',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: _isDark ? const Color(0xFF1E2F47) : const Color(0xFFEEF4FD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _border,
                        ),
                      ),
                      child: Text(
                        'Rankings',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _brandPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Real-time ranking of top volume and revenue products in POS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 11.5 : 13,
                    fontWeight: FontWeight.w500,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          onPressed: _loadProducts,
          icon: Icon(Icons.refresh_rounded, color: _muted),
          tooltip: 'Refresh Rankings',
        ),
      ],
    );
  }

  Widget _buildKpiMetrics(bool isMobile) {
    final topProd = _topProduct;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isMobile ? 2 : (constraints.maxWidth > 900 ? 4 : 2);
        final cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 14) / crossAxisCount;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _buildKpiCard(
              width: cardWidth,
              title: 'Top Product',
              value: topProd != null ? topProd.name : 'N/A',
              subtitle: topProd != null ? '${topProd.sold} units sold' : 'No sales yet',
            ),
            _buildKpiCard(
              width: cardWidth,
              title: 'Total Units Sold',
              value: '$_totalSoldUnits units',
              subtitle: 'Across all catalog items',
            ),
            _buildKpiCard(
              width: cardWidth,
              title: 'Total POS Revenue',
              value: '₱ ${_totalRevenue.toStringAsFixed(2)}',
              subtitle: 'Combined sales value',
            ),
            _buildKpiCard(
              width: cardWidth,
              title: 'Top Category',
              value: _topCategory,
              subtitle: 'Leading sales volume',
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: _muted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: _text,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: _muted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          final bg = isSelected
              ? (_isDark ? Colors.white : PiggyTrunkTheme.ptPrimary)
              : (_isDark ? const Color(0xFF1E2F47) : const Color(0xFFEEF4FD));
          final fg = isSelected
              ? (_isDark ? PiggyTrunkTheme.ptPrimary : Colors.white)
              : (_isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569));
          final border = isSelected
              ? Colors.transparent
              : (_isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3));

          final count = cat == 'All'
              ? _products.length
              : _products.where((p) => p.category.toLowerCase() == cat.toLowerCase()).length;

          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: InkWell(
              onTap: () => setState(() => _selectedCategory = cat),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: (_isDark ? Colors.white : PiggyTrunkTheme.ptPrimary).withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  '$cat ($count)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPodiumSection(bool isMobile) {
    final topThree = _rankedProducts.take(3).toList();
    if (topThree.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top 3 Spotlight',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _text,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardCount = topThree.length;
            final isNarrow = constraints.maxWidth < 700;
            final double cardWidth = isNarrow
                ? constraints.maxWidth
                : (constraints.maxWidth - (cardCount - 1) * 14) / cardCount;

            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: List.generate(topThree.length, (idx) {
                final product = topThree[idx];
                final rank = idx + 1;
                return _buildPodiumCard(product, rank, cardWidth);
              }),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPodiumCard(POSProduct product, int rank, double width) {
    final Color medalColor;
    final Color medalBg;
    final String medalLabel;

    if (rank == 1) {
      medalColor = _brandPrimary;
      medalBg = _isDark ? const Color(0xFF1E2F47) : const Color(0xFFEEF4FD);
      medalLabel = 'RANK #1';
    } else if (rank == 2) {
      medalColor = _isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);
      medalBg = _isDark ? const Color(0xFF162338) : const Color(0xFFF1F5F9);
      medalLabel = 'RANK #2';
    } else {
      medalColor = _isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8);
      medalBg = _isDark ? const Color(0xFF111D2E) : const Color(0xFFF8FAFC);
      medalLabel = 'RANK #3';
    }

    final double revenue = product.price * product.sold;

    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank == 1 ? _brandPrimary : _border,
          width: rank == 1 ? 2.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (rank == 1 ? _brandPrimary : Colors.black).withValues(
              alpha: _isDark ? (rank == 1 ? 0.25 : 0.2) : (rank == 1 ? 0.1 : 0.03),
            ),
            blurRadius: rank == 1 ? 14 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rank Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: medalBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: rank == 1 ? _brandPrimary.withValues(alpha: 0.5) : _border,
                    width: 1,
                  ),
                ),
                child: Text(
                  medalLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: medalColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                product.category,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Product Image & Name
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _isDark ? const Color(0xFF1E2F47) : const Color(0xFFEEF4FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: product.image != null && product.image!.isNotEmpty
                      ? Image.network(
                          product.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.inventory_2_outlined, color: _muted, size: 24),
                        )
                      : Icon(Icons.inventory_2_outlined, color: _muted, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₱ ${product.price.toStringAsFixed(2)} / unit',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Sales Stats Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF162338) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL SOLD',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: _muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${product.sold} units',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: _brandPrimary),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'REVENUE',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: _muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₱ ${revenue.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: const Color(0xFF10B981)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection(bool isMobile) {
    final products = _rankedProducts;

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Leaderboard Ranking (${products.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
              Text(
                'Sorted by Units Sold',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 40, color: _muted),
                    const SizedBox(height: 10),
                    Text(
                      'No products available in this category.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: _muted),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (context, index) => Divider(color: _border, height: 16),
              itemBuilder: (context, idx) {
                final product = products[idx];
                final rank = idx + 1;
                final revenue = product.price * product.sold;
                final isOutOfStock = product.units <= 0;

                return Row(
                  children: [
                    // Rank Chip
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: rank == 1
                            ? (_isDark ? const Color(0xFF1E2F47) : const Color(0xFFEEF4FD))
                            : (_isDark ? const Color(0xFF162338) : const Color(0xFFF8FAFC)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: rank == 1 ? _brandPrimary : _border,
                          width: rank == 1 ? 1.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$rank',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: rank == 1 ? _brandPrimary : _muted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Product Image
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isDark ? const Color(0xFF1E2F47) : const Color(0xFFEEF4FD),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: product.image != null && product.image!.isNotEmpty
                            ? Image.network(
                                product.image!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(Icons.inventory_2_outlined, color: _muted, size: 20),
                              )
                            : Icon(Icons.inventory_2_outlined, color: _muted, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Product Name & Category
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: _text,
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
                                  color: _isDark ? const Color(0xFF1E2F47) : const Color(0xFFEEF4FD),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  product.category,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: _muted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '₱${product.price.toStringAsFixed(2)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Sold Units
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '${product.sold} sold',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: _brandPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isOutOfStock ? 'Out of Stock' : '${product.units} in stock',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isOutOfStock ? const Color(0xFFEF4444) : _muted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Revenue
                    if (!isMobile)
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₱ ${revenue.toStringAsFixed(2)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total revenue',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
