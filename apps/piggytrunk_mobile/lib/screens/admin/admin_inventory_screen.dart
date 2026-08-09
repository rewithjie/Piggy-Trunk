import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_restock_screen.dart';

class AdminMobileInventoryScreen extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const AdminMobileInventoryScreen({
    super.key,
    this.onBackToDashboard,
  });

  @override
  State<AdminMobileInventoryScreen> createState() =>
      _AdminMobileInventoryScreenState();
}

class _AdminMobileInventoryScreenState
    extends State<AdminMobileInventoryScreen> {
  // Brand color tokens
  static const Color _brandNavy = Color(0xFF18314F);
  static const Color _cardBorder = Color(0xFFE2E8F0);
  static const Color _textMuted = Color(0xFF6F8096);
  static const Color _criticalRed = Color(0xFFDC2626);
  static const Color _emeraldGreen = Color(0xFF10B981);
  static const Color _actionBlue = Color(0xFF3B82F6);

  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['All', 'Piglet', 'Fattening', 'Sow', 'Booster'];

  bool _isSearchOpen = false;
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = false;

  int _totalStock = 0;
  int _outOfStock = 0;
  List<Map<String, dynamic>> _inventoryProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchLiveInventory();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveInventory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      List<dynamic> res = [];
      try {
        res = await Supabase.instance.client
            .from('inventory_products')
            .select('id, name, category, price, units, is_archived')
            .eq('is_archived', false)
            .order('name');
      } catch (_) {
        try {
          res = await Supabase.instance.client
              .from('products')
              .select('id, name, category, price, units, is_archived')
              .eq('is_archived', false)
              .order('name');
        } catch (_) {}
      }

      if (res.isNotEmpty && mounted) {
        int sumUnits = 0;
        int lowStockCount = 0;
        List<Map<String, dynamic>> parsed = [];

        for (var p in res) {
          final int units = (p['units'] as num?)?.toInt() ?? 0;
          final double price = (p['price'] as num?)?.toDouble() ?? 0.0;
          final String name = (p['name'] as String?) ?? 'Feed Product';
          final String cat = (p['category'] as String?) ?? 'Piglet';
          final double ratio = units > 0 ? (units / 100).clamp(0.05, 1.0) : 0.0;
          final bool critical = units <= 10;

          sumUnits += units;
          if (critical) lowStockCount++;

          parsed.add({
            'id': p['id']?.toString() ?? '',
            'name': name.toUpperCase(),
            'brand': 'Pigrolac Feed Series',
            'category': cat,
            'price': price,
            'units': units,
            'percentage': ratio,
            'percentText': '${(ratio * 100).toInt()}% ($units Bags)',
            'isCritical': critical,
            'icon': Icons.inventory_2_rounded,
          });
        }

        setState(() {
          _inventoryProducts = parsed;
          _totalStock = sumUnits;
          _outOfStock = lowStockCount;
        });
      } else if (mounted) {
        setState(() {
          _inventoryProducts = [];
          _totalStock = 0;
          _outOfStock = 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching live inventory: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openRestockModal(Map<String, dynamic> item) async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AdminMobileRestockScreen(product: item),
      ),
    );
    if (res == true) {
      _fetchLiveInventory();
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    final query = _searchCtrl.text.trim().toLowerCase();
    final selectedCat = _categories[_selectedCategoryIndex];

    return _inventoryProducts.where((p) {
      final nameMatches = (p['name'] as String).toLowerCase().contains(query) ||
          (p['brand'] as String).toLowerCase().contains(query);
      final catMatches = selectedCat == 'All' ||
          (p['category'] as String).toLowerCase() == selectedCat.toLowerCase();
      return nameMatches && catMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          color: _brandNavy,
          onRefresh: _fetchLiveInventory,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoading) ...[
                  const LinearProgressIndicator(
                    minHeight: 2.5,
                    color: _brandNavy,
                    backgroundColor: Colors.transparent,
                  ),
                  const SizedBox(height: 12),
                ],

                // Inline Search Bar (if toggled)
                if (_isSearchOpen) ...[
                  _buildSearchBar(),
                  const SizedBox(height: 18),
                ],

                // Top Metric Cards (Total Stock & Out of Stock)
                _buildMetricCardsRow(),
                const SizedBox(height: 22),

                // Category Filter Pills (Piglet, Fattening, Sow, Booster)
                _buildCategoryPillSelector(),
                const SizedBox(height: 24),

                // Feed Inventory List
                _buildInventoryList(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1. Top App Bar with Menu, Title, Search, and Notification
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: _brandNavy, size: 24),
        onPressed: widget.onBackToDashboard ?? () => Navigator.maybePop(context),
      ),
      title: Text(
        'Inventory',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: _brandNavy,
          letterSpacing: -0.4,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isSearchOpen ? Icons.close : Icons.search_rounded,
            color: _brandNavy,
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _isSearchOpen = !_isSearchOpen;
              if (!_isSearchOpen) _searchCtrl.clear();
            });
          },
        ),
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded,
                  color: _brandNavy, size: 23),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All stock alerts are up to date.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _criticalRed,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // Search input field
  Widget _buildSearchBar() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.plusJakartaSans(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search feed brand, product or category...',
        prefixIcon: const Icon(Icons.search, size: 20, color: _textMuted),
        suffixIcon: _searchCtrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  setState(() => _searchCtrl.clear());
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _cardBorder),
        ),
      ),
    );
  }

  // 2. Dual Metric Summary Cards (2 Columns: Total Stock & Out of Stock)
  Widget _buildMetricCardsRow() {
    return Row(
      children: [
        // Total Stock Card (Deep Navy / Slate Gradient)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF18314F),
                  Color(0xFF243B53),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF18314F).withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Stock',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _totalStock.toString(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Out of Stock / Low Stock Card (Amber / Coral Gradient)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF97316),
                  Color(0xFFEA580C),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Out of Stock',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _outOfStock.toString(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 3. Category Filter Pill Selector (Piglet, Fattening, Sow, Booster)
  Widget _buildCategoryPillSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: _cardBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.asMap().entries.map((entry) {
            final int index = entry.key;
            final String label = entry.value;
            final bool isSelected = _selectedCategoryIndex == index;

            return GestureDetector(
              onTap: () {
                setState(() => _selectedCategoryIndex = index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? const Color(0xFFE11D48) : _textMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 4. Feed Inventory Items & Cards
  Widget _buildInventoryList() {
    final list = _filteredProducts;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 48, color: _textMuted),
              const SizedBox(height: 12),
              Text(
                'No feed items found',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _brandNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Try selecting another category or clear the search.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: _textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = list[index];
        final bool isCritical = item['isCritical'] as bool;
        final double percentage = (item['percentage'] as num).toDouble();
        final double price = (item['price'] as num).toDouble();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isCritical ? const Color(0xFFFECDD3) : _cardBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Thumbnail, Product Titles & Options Menu / Critical Tag
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Feed Sack Thumbnail Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _cardBorder),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: _brandNavy,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Titles & Category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['brand'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['name'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _brandNavy,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Critical Stock Tag or 3-Dots Menu
                  if (isCritical)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4E6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'CRITICAL STOCK',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFE11D48),
                          letterSpacing: 0.4,
                        ),
                      ),
                    )
                  else
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded,
                          color: _textMuted, size: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val == 'restock') _openRestockModal(item);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'restock',
                          child: Text('Restock Now'),
                        ),
                        const PopupMenuItem(
                          value: 'price',
                          child: Text('Adjust Price'),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Price & Stock Level Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PRICE:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '₱${price.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: _brandNavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Stock level text
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isCritical ? 'STOCK DEPLETING' : 'STOCK LEVEL',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isCritical
                          ? const Color(0xFFE11D48)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    item['percentText'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isCritical
                          ? const Color(0xFFE11D48)
                          : _brandNavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Progress indicator bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCritical ? const Color(0xFFE11D48) : _emeraldGreen,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Full width RESTOCK action button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _actionBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _openRestockModal(item),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    'RESTOCK',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
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
}
