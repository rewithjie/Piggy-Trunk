import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_transaction_checkout_screen.dart';

class AdminMobileSalesScreen extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const AdminMobileSalesScreen({
    super.key,
    this.onBackToDashboard,
  });

  @override
  State<AdminMobileSalesScreen> createState() =>
      _AdminMobileSalesScreenState();
}

class _AdminMobileSalesScreenState extends State<AdminMobileSalesScreen> {
  // Brand color tokens (Aligned with Piggy Trunk Design System)
  static const Color _brandNavy = Color(0xFF18314F);
  static const Color _cardBorder = Color(0xFFE2E8F0);
  static const Color _textMuted = Color(0xFF6F8096);
  static const Color _accentCoral = Color(0xFFC73F57);
  static const Color _kiloSelectedBg = Color(0xFF8B1D35); // Deep wine for active kilo pill

  final int _selectedTabIndex = 3; // POS Tab (Active)
  bool _isLoading = false;
  String _searchQuery = '';

  List<Map<String, dynamic>> _posProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchLivePOSProducts();
  }

  Future<void> _fetchLivePOSProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final res = await Supabase.instance.client
          .from('inventory_products')
          .select('id, name, category, price, units')
          .order('name', ascending: true);

      if (res.isNotEmpty && mounted) {
        List<Map<String, dynamic>> parsed = [];
        for (var p in res) {
          final double price = (p['price'] as num?)?.toDouble() ?? 10000.00;
          parsed.add({
            'id': p['id']?.toString() ?? '',
            'name': (p['name'] as String?)?.toUpperCase() ?? 'FEED PRODUCT',
            'category': (p['category'] as String?) ?? 'Pigrolac Early Wean',
            'price': price,
            'stock': (p['units'] as num?)?.toInt() ?? 0,
            'isChecked': false,
            'sackQty': 0,
            'kiloQty': 0.0,
            'selectedKiloOption': '',
          });
        }
        setState(() => _posProducts = parsed);
      } else if (mounted) {
        // Clean state if empty in DB
        setState(() => _posProducts = []);
      }
    } catch (e) {
      debugPrint('Error fetching POS products: $e');
      if (mounted) setState(() => _posProducts = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _selectedItemsCount {
    return _posProducts.where((p) => p['isChecked'] == true && (p['sackQty'] > 0 || p['kiloQty'] > 0)).length;
  }

  double get _totalCartAmount {
    double total = 0.0;
    for (var p in _posProducts) {
      if (p['isChecked'] == true) {
        final double unitPrice = (p['price'] as num).toDouble();
        final int sacks = p['sackQty'] as int;
        final double kilos = (p['kiloQty'] as num).toDouble();
        // Sacks cost + Kilo cost (assuming 50kg per sack standard)
        total += (sacks * unitPrice) + (kilos * (unitPrice / 50.0));
      }
    }
    return total;
  }

  void _openCheckoutModal() {
    if (_selectedItemsCount == 0 || _totalCartAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one item to proceed.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final selectedProduct = _posProducts.firstWhere(
      (p) => p['isChecked'] == true,
      orElse: () => _posProducts.first,
    );

    final String prodName = (selectedProduct['name'] as String?) ?? 'IMMUNOBOOSTER';
    final String category = (selectedProduct['category'] as String?) ?? 'Pigrolac Early Wean';
    final int sacks = (selectedProduct['sackQty'] as num?)?.toInt() ?? 2;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminMobileTransactionCheckoutScreen(
          checkoutData: {
            'productName': prodName.toUpperCase(),
            'category': category,
            'sackQuantity': sacks > 0 ? sacks : 2,
            'totalPrice': _totalCartAmount > 0 ? _totalCartAmount : 10000.00,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _posProducts.where((p) {
      final String name = (p['name'] as String).toLowerCase();
      final String cat = (p['category'] as String).toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || cat.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          color: _brandNavy,
          onRefresh: _fetchLivePOSProducts,
          child: Column(
            children: [
              if (_isLoading) ...[
                const LinearProgressIndicator(
                  minHeight: 2.5,
                  color: _brandNavy,
                  backgroundColor: Colors.transparent,
                ),
              ],

              // Product Cards List (or Clean Empty State)
              Expanded(
                child: filtered.isEmpty
                    ? _buildCleanEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 90),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return _buildPOSProductCard(filtered[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: _buildStickyCheckoutBar(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // 1. Top App Bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: _brandNavy, size: 26),
        onPressed: widget.onBackToDashboard ?? () => Navigator.maybePop(context),
      ),
      title: Text(
        'POS',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: _brandNavy,
          letterSpacing: -0.4,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: _brandNavy, size: 22),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                final searchCtrl = TextEditingController(text: _searchQuery);
                return AlertDialog(
                  title: const Text('Search Feeds'),
                  content: TextField(
                    controller: searchCtrl,
                    decoration: const InputDecoration(hintText: 'Type feed name...'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() => _searchQuery = searchCtrl.text.trim());
                        Navigator.pop(context);
                      },
                      child: const Text('Search'),
                    ),
                  ],
                );
              },
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: _brandNavy, size: 22),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Filter by feed category or price.'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // 2. POS Feed Product Card matching uploaded screenshot
  Widget _buildPOSProductCard(Map<String, dynamic> item) {
    final bool isChecked = item['isChecked'] as bool;
    final int sackQty = item['sackQty'] as int;
    final double unitPrice = (item['price'] as num).toDouble();
    final String selectedKiloOption = item['selectedKiloOption'] as String;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isChecked ? const Color(0xFFFCA5A5) : const Color(0xFFFDE8E8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Checkbox, Product Image, Subtitle, Title, Sack Stepper, Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              GestureDetector(
                onTap: () {
                  setState(() {
                    item['isChecked'] = !isChecked;
                    if (item['isChecked'] == true && sackQty == 0) {
                      item['sackQty'] = 1;
                    }
                  });
                },
                child: Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.only(top: 2, right: 12),
                  decoration: BoxDecoration(
                    color: isChecked ? _kiloSelectedBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: isChecked ? _kiloSelectedBg : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                  ),
                  child: isChecked
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                      : null,
                ),
              ),

              // Product Image Box
              Container(
                width: 60,
                height: 74,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _cardBorder),
                ),
                child: Center(
                  child: Icon(
                    Icons.inventory_2_rounded,
                    size: 32,
                    color: item['name'].toString().contains('STARTER') ? const Color(0xFFD97706) : const Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Product Details & Sack Quantity Stepper
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['category'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['name'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _brandNavy,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Sack Quantity Row with Stepper
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sack Quantity',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.remove, size: 16, color: _accentCoral),
                                onPressed: () {
                                  if (sackQty > 0) {
                                    setState(() {
                                      item['sackQty'] = sackQty - 1;
                                      if (item['sackQty'] == 0 && (item['kiloQty'] as num) == 0) {
                                        item['isChecked'] = false;
                                      }
                                    });
                                  }
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  sackQty.toString(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: _brandNavy,
                                  ),
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.add, size: 16, color: _accentCoral),
                                onPressed: () {
                                  setState(() {
                                    item['sackQty'] = sackQty + 1;
                                    item['isChecked'] = true;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Unit Price/Sack
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Unit Price/Sack',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _textMuted,
                          ),
                        ),
                        Text(
                          '₱${unitPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF991B1B), // Dark Wine / Coral
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Kilo Input Bar
          Row(
            children: [
              Text(
                'Kilo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item['kiloQty'] > 0 ? '${item['kiloQty']} kg' : '0',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: item['kiloQty'] > 0 ? _brandNavy : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2x2 Kilo Shortcut Pills Grid (matching screenshot layout)
          Row(
            children: [
              Expanded(
                child: _buildKiloPill(
                  label: '1 kilo',
                  isSelected: selectedKiloOption == '1kilo_1',
                  onTap: () {
                    setState(() {
                      if (selectedKiloOption == '1kilo_1') {
                        item['selectedKiloOption'] = '';
                        item['kiloQty'] = 0.0;
                      } else {
                        item['selectedKiloOption'] = '1kilo_1';
                        item['kiloQty'] = 1.0;
                        item['isChecked'] = true;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKiloPill(
                  label: '1 kilo',
                  isSelected: selectedKiloOption == '1kilo_2',
                  onTap: () {
                    setState(() {
                      if (selectedKiloOption == '1kilo_2') {
                        item['selectedKiloOption'] = '';
                        item['kiloQty'] = 0.0;
                      } else {
                        item['selectedKiloOption'] = '1kilo_2';
                        item['kiloQty'] = 1.0;
                        item['isChecked'] = true;
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildKiloPill(
                  label: '1/4 kilo',
                  isSelected: selectedKiloOption == 'quarter_1',
                  onTap: () {
                    setState(() {
                      if (selectedKiloOption == 'quarter_1') {
                        item['selectedKiloOption'] = '';
                        item['kiloQty'] = 0.0;
                      } else {
                        item['selectedKiloOption'] = 'quarter_1';
                        item['kiloQty'] = 0.25;
                        item['isChecked'] = true;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKiloPill(
                  label: '1/4 kilo',
                  isSelected: selectedKiloOption == 'quarter_2',
                  onTap: () {
                    setState(() {
                      if (selectedKiloOption == 'quarter_2') {
                        item['selectedKiloOption'] = '';
                        item['kiloQty'] = 0.0;
                      } else {
                        item['selectedKiloOption'] = 'quarter_2';
                        item['kiloQty'] = 0.25;
                        item['isChecked'] = true;
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKiloPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF991B1B) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _kiloSelectedBg : Colors.transparent,
                border: Border.all(
                  color: isSelected ? _kiloSelectedBg : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Clean Empty State Placeholder
  Widget _buildCleanEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _brandNavy.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.point_of_sale_rounded, size: 32, color: _accentCoral),
            ),
            const SizedBox(height: 14),
            Text(
              'No Feed Products in Inventory',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: _brandNavy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add feed inventory items from the Inventory screen to begin ringing up sack and retail kilo sales.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: _textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 4. Sticky Bottom Floating Checkout Bar
  Widget _buildStickyCheckoutBar() {
    final int itemsCount = _selectedItemsCount;
    final double total = _totalCartAmount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEE), // Soft rose surface from screenshot
        border: const Border(
          top: BorderSide(color: Color(0xFFFDE8E8), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Items & Total Price Column
          Row(
            children: [
              const Icon(Icons.keyboard_arrow_up_rounded, color: Color(0xFFC73F57), size: 22),
              const SizedBox(width: 4),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$itemsCount items',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF991B1B),
                    ),
                  ),
                  Text(
                    'Total: ₱${total.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: _brandNavy,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Green PROCEED Button
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B074), // Emerald green from screenshot
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              onPressed: _openCheckoutModal,
              label: Text(
                'PROCEED',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  letterSpacing: 0.6,
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Bottom Navigation Bar (5 Dedicated Tabs matching screenshot)
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: (index) {
          if (index != 3) {
            Navigator.pop(context);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFC73F57), // Active Red
        unselectedItemColor: const Color(0xFF64748B),
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded, size: 24),
            activeIcon: Icon(Icons.dashboard_rounded, size: 24),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined, size: 24),
            activeIcon: Icon(Icons.inventory_2_rounded, size: 24),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined, size: 24),
            activeIcon: Icon(Icons.assignment_rounded, size: 24),
            label: 'Investment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_outlined, size: 24),
            activeIcon: Icon(Icons.point_of_sale_rounded, size: 24),
            label: 'POS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded, size: 24),
            activeIcon: Icon(Icons.person_rounded, size: 24),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
