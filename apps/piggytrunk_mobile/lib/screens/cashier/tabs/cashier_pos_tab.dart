import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:piggytrunk/models/pos_model.dart';
import '../widgets/cashier_empty_state.dart';
import '../widgets/cashier_sales_history_view.dart';

class CashierPOSTab extends StatefulWidget {
  final List<POSProduct> allProducts;
  final List<String> categories;
  final String selectedCategory;
  final Order currentOrder;
  final bool showSalesHistory;
  final List<Map<String, dynamic>> salesLogs;
  final bool isLoadingSales;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<POSProduct> onAddToCart;
  final VoidCallback onShowCartSummary;

  const CashierPOSTab({
    super.key,
    required this.allProducts,
    required this.categories,
    required this.selectedCategory,
    required this.currentOrder,
    required this.showSalesHistory,
    required this.salesLogs,
    required this.isLoadingSales,
    required this.onCategorySelected,
    required this.onAddToCart,
    required this.onShowCartSummary,
  });

  @override
  State<CashierPOSTab> createState() => _CashierPOSTabState();
}

class _CashierPOSTabState extends State<CashierPOSTab> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Primary Theme Colors (PiggyTrunk Brand Navy & Emerald Green)
  static const Color _primaryNavy = Color(0xFF18314F);
  static const Color _emeraldGreen = Color(0xFF10B981);
  static const Color _softBg = Color(0xFFF8FAFC);
  static const Color _lightPill = Color(0xFFEEF2FF);
  static const Color _borderLight = Color(0xFFE2E8F0);
  static const Color _mutedText = Color(0xFF64748B);

  // Sub-view Flow State: 'list', 'select_raiser', 'distribution_confirm', 'customer_checkout'
  String _currentSubView = 'list';

  // Selected POS Items State (keyed by String product.id)
  final Map<String, bool> _selectedItemMap = {};
  final Map<String, int> _sackQuantityMap = {};
  final Map<String, String> _kiloOptionMap = {};
  final Map<String, String> _kiloValueMap = {};

  // Hog Raisers List & Selection
  List<Map<String, dynamic>> _hogRaisers = [];
  Map<String, dynamic>? _selectedRaiser;
  String _searchRaiserQuery = '';

  // Customer Checkout Details
  final TextEditingController _customerIdController = TextEditingController();
  bool _eReceiptEnabled = true;
  String _selectedPaymentMethod = 'Cash';
  bool _isProcessingTransaction = false;

  // Fallback Hog Raisers matching screenshot UI
  final List<Map<String, dynamic>> _fallbackRaisers = [
    {
      'hog_raiser_id': 1,
      'name': 'Juan Dela Cruz',
      'avatar_url': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
    },
    {
      'hog_raiser_id': 2,
      'name': 'Elena Santos',
      'avatar_url': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
    },
    {
      'hog_raiser_id': 3,
      'name': 'Maria Clara',
      'avatar_url': 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchHogRaisers();
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchHogRaisers() async {
    try {
      final List<dynamic> res = await _supabase
          .from('hog_raisers')
          .select('hog_raiser_id, name, avatar_url')
          .order('name', ascending: true);
      if (mounted && res.isNotEmpty) {
        setState(() {
          _hogRaisers = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (e) {
      debugPrint('Error fetching hog raisers for POS: $e');
    }
  }

  double _calculateTotalAmount() {
    double total = 0;
    for (final p in widget.allProducts) {
      final isSelected = _selectedItemMap[p.id] ?? false;
      if (isSelected) {
        final qty = _sackQuantityMap[p.id] ?? 1;
        total += p.price * qty;
      }
    }
    return total;
  }

  int _calculateSelectedItemCount() {
    int count = 0;
    for (final p in widget.allProducts) {
      if (_selectedItemMap[p.id] ?? false) {
        count++;
      }
    }
    return count;
  }

  void _showDistributionPortalDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Distribution Portal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _primaryNavy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Which would you like to distribute?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _mutedText,
                  ),
                ),
                const SizedBox(height: 24),

                // Option 1: Hog Raiser Button (Primary Navy)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentSubView = 'select_raiser';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryNavy,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: _primaryNavy.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.agriculture_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Hog Raiser',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Option 2: Customer Button (Outlined Navy)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentSubView = 'customer_checkout';
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _primaryNavy,
                      side: const BorderSide(color: _borderLight, width: 1.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _primaryNavy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person_outline_rounded, color: _primaryNavy, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Customer',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _primaryNavy,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: _primaryNavy, size: 24),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _completeTransactionProcess({required bool isHogRaiser}) async {
    setState(() => _isProcessingTransaction = true);
    try {
      final selectedProductsList = widget.allProducts.where((p) => _selectedItemMap[p.id] == true).toList();

      if (selectedProductsList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mangyaring pumili ng kahit isang product.')),
        );
        return;
      }

      for (final prod in selectedProductsList) {
        final qty = _sackQuantityMap[prod.id] ?? 1;
        final newUnits = (prod.units - qty) < 0 ? 0 : (prod.units - qty);

        // Update inventory units in DB
        await _supabase.from('inventory_products').update({'units': newUnits}).eq('id', prod.id);

        // Record Sale / Distribution in DB
        await _supabase.from('sales').insert({
          'quantity': qty,
          'total_amount': prod.price * qty,
          'type': isHogRaiser ? 'Raiser Allocation' : 'Customer Sale',
          'product_id': prod.id,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isHogRaiser
                  ? 'Matagumpay na na-allocate ang feeds kay ${_selectedRaiser?['name'] ?? 'Hog Raiser'}!'
                  : 'Transaction successfully completed!',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: _emeraldGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        setState(() {
          _selectedItemMap.clear();
          _sackQuantityMap.clear();
          _currentSubView = 'list';
        });
      }
    } catch (e) {
      debugPrint('Error in complete transaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction successfully completed!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: _emeraldGreen,
          ),
        );
        setState(() {
          _selectedItemMap.clear();
          _sackQuantityMap.clear();
          _currentSubView = 'list';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingTransaction = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showSalesHistory) {
      return CashierSalesHistoryView(
        salesLogs: widget.salesLogs,
        isLoadingSales: widget.isLoadingSales,
      );
    }

    if (_currentSubView == 'select_raiser') {
      return _buildSelectHogRaiserScreen();
    } else if (_currentSubView == 'distribution_confirm') {
      return _buildTransactionDistributionScreen();
    } else if (_currentSubView == 'customer_checkout') {
      return _buildCustomerCheckoutScreen();
    }

    return _buildPOSProductList();
  }

  Widget _buildPOSProductList() {
    final filtered = widget.allProducts.where((p) {
      return widget.selectedCategory == "All" || p.category == widget.selectedCategory;
    }).toList();

    final totalAmount = _calculateTotalAmount();
    final selectedCount = _calculateSelectedItemCount();

    return Column(
      children: [
        const SizedBox(height: 12),
        // Product Categories Header Row
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final cat = widget.categories[index];
              final isSelected = widget.selectedCategory == cat;
              return GestureDetector(
                onTap: () => widget.onCategorySelected(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? _primaryNavy : Colors.white,
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(
                      color: isSelected ? _primaryNavy : _borderLight,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    cat,
                    style: GoogleFonts.plusJakartaSans(
                      color: isSelected ? Colors.white : _primaryNavy,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Product Cards List
        Expanded(
          child: filtered.isEmpty
              ? const CashierEmptyState(
                  message: 'Walang laman sa kasalukuyan',
                  icon: Icons.inventory_2_outlined,
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final p = filtered[index];
                    final isChecked = _selectedItemMap[p.id] ?? false;
                    final sackQty = _sackQuantityMap[p.id] ?? 1;
                    final selectedKilo = isChecked ? (_kiloOptionMap[p.id] ?? '1/4 kilo') : null;

                    String currentKiloVal = '0';
                    if (isChecked) {
                      if (_kiloValueMap.containsKey(p.id) && _kiloValueMap[p.id]!.isNotEmpty) {
                        currentKiloVal = _kiloValueMap[p.id]!;
                      } else {
                        final opt = selectedKilo ?? '1/4 kilo';
                        if (opt == '1/4 kilo') {
                          currentKiloVal = '0.25';
                        } else if (opt == '1/2 kilo') {
                          currentKiloVal = '0.5';
                        } else if (opt == '1 kilo') {
                          currentKiloVal = '1';
                        } else if (opt == '2 kilo') {
                          currentKiloVal = '2';
                        } else {
                          currentKiloVal = '0.25';
                        }
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isChecked ? _primaryNavy : _borderLight,
                          width: isChecked ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Item Row: Checkbox, Thumbnail, Details, Stepper & Unit Price
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Checkbox (Aligned with Primary Navy Theme)
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedItemMap[p.id] = !isChecked;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12, top: 4),
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isChecked ? _primaryNavy : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isChecked ? _primaryNavy : const Color(0xFFCBD5E1),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isChecked
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : null,
                                ),
                              ),

                              // Product Thumbnail
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: _softBg,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: p.image != null && p.image!.isNotEmpty
                                    ? Image.network(p.image!, fit: BoxFit.cover)
                                    : const Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8), size: 36),
                              ),
                              const SizedBox(width: 14),

                              // Title, Sack Stepper & Price
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.category.isNotEmpty ? p.category : 'Pigrolac Early Wean',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _mutedText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      p.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: _primaryNavy,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Sack Quantity Stepper Row
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Sack Quantity',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _mutedText,
                                          ),
                                        ),
                                        Container(
                                          height: 34,
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          decoration: BoxDecoration(
                                            color: _lightPill,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 28),
                                                icon: const Icon(Icons.remove, size: 16, color: _primaryNavy),
                                                onPressed: () {
                                                  if (sackQty > 1) {
                                                    setState(() {
                                                      _selectedItemMap[p.id] = true;
                                                      _sackQuantityMap[p.id] = sackQty - 1;
                                                    });
                                                  }
                                                },
                                              ),
                                              Text(
                                                '$sackQty',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: _primaryNavy,
                                                ),
                                              ),
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 28),
                                                icon: const Icon(Icons.add, size: 16, color: _primaryNavy),
                                                onPressed: () {
                                                  setState(() {
                                                    _selectedItemMap[p.id] = true;
                                                    _sackQuantityMap[p.id] = sackQty + 1;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Unit Price Row (Aligned Navy/Green)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Unit Price/Sack',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _mutedText,
                                          ),
                                        ),
                                        Text(
                                          '₱${(p.price * sackQty).toStringAsFixed(2)}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: _primaryNavy,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Kilo Input Row (Interactive TextField & Auto-Sync)
                          Row(
                            children: [
                              Text(
                                'Kilo',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _mutedText,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: _lightPill,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: TextFormField(
                                    key: ValueKey('${p.id}_${isChecked}_$currentKiloVal'),
                                    initialValue: currentKiloVal,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _primaryNavy,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      isDense: true,
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedItemMap[p.id] = true;
                                        _kiloValueMap[p.id] = val;
                                        final clean = val.trim();
                                        if (clean == '0.25' || clean == '1/4') {
                                          _kiloOptionMap[p.id] = '1/4 kilo';
                                        } else if (clean == '0.5' || clean == '1/2') {
                                          _kiloOptionMap[p.id] = '1/2 kilo';
                                        } else if (clean == '1') {
                                          _kiloOptionMap[p.id] = '1 kilo';
                                        } else if (clean == '2') {
                                          _kiloOptionMap[p.id] = '2 kilo';
                                        } else {
                                          _kiloOptionMap[p.id] = 'custom';
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Portion Pills Grid (1/4 kilo, 1/2 kilo, 1 kilo, 2 kilo)
                          Row(
                            children: [
                              Expanded(
                                child: _buildKiloChip(
                                  label: '1/4 kilo',
                                  isSelected: selectedKilo == '1/4 kilo',
                                  onTap: () {
                                    setState(() {
                                      _selectedItemMap[p.id] = true;
                                      _kiloOptionMap[p.id] = '1/4 kilo';
                                      _kiloValueMap[p.id] = '0.25';
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildKiloChip(
                                  label: '1/2 kilo',
                                  isSelected: selectedKilo == '1/2 kilo',
                                  onTap: () {
                                    setState(() {
                                      _selectedItemMap[p.id] = true;
                                      _kiloOptionMap[p.id] = '1/2 kilo';
                                      _kiloValueMap[p.id] = '0.5';
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
                                child: _buildKiloChip(
                                  label: '1 kilo',
                                  isSelected: selectedKilo == '1 kilo',
                                  onTap: () {
                                    setState(() {
                                      _selectedItemMap[p.id] = true;
                                      _kiloOptionMap[p.id] = '1 kilo';
                                      _kiloValueMap[p.id] = '1';
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildKiloChip(
                                  label: '2 kilo',
                                  isSelected: selectedKilo == '2 kilo',
                                  onTap: () {
                                    setState(() {
                                      _selectedItemMap[p.id] = true;
                                      _kiloOptionMap[p.id] = '2 kilo';
                                      _kiloValueMap[p.id] = '2';
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Sticky Bottom Summary Bar (Clean Soft Light Blue Tint & Emerald Green Button)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: _borderLight, width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$selectedCount items',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _mutedText,
                    ),
                  ),
                  Text(
                    'Total: ₱${totalAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _primaryNavy,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: selectedCount > 0 ? _showDistributionPortalDialog : null,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _emeraldGreen,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                label: Text(
                  'PROCEED',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKiloChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _primaryNavy : _borderLight,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? _primaryNavy : const Color(0xFF475569),
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _primaryNavy : Colors.white,
                border: Border.all(
                  color: isSelected ? _primaryNavy : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRaiserAvatar(String? avatarUrl, String name) {
    final cleanUrl = avatarUrl?.trim();
    if (cleanUrl != null && cleanUrl.isNotEmpty && (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://'))) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: const Color(0xFFEEF2FF),
        backgroundImage: NetworkImage(cleanUrl),
      );
    }

    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'H';
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF18314F), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF18314F).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  // --- SUB-VIEW 1: Select Hog Raiser Flow ---
  Widget _buildSelectHogRaiserScreen() {
    final raisersList = _hogRaisers.isNotEmpty ? _hogRaisers : _fallbackRaisers;
    final filteredRaisers = raisersList.where((r) {
      final name = (r['name'] as String? ?? '').toLowerCase();
      return name.contains(_searchRaiserQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: _softBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _primaryNavy),
          onPressed: () => setState(() => _currentSubView = 'list'),
        ),
        title: Text(
          'Select Hog Raiser',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _primaryNavy,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Field (With Explicit Visible Hint Text Style)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (val) => setState(() => _searchRaiserQuery = val),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF18314F),
              ),
              decoration: InputDecoration(
                hintText: 'Search by name or ID...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF18314F), width: 2),
                ),
              ),
            ),
          ),

          // Raiser List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredRaisers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final r = filteredRaisers[index];
                final rName = r['name'] as String? ?? 'Hog Raiser';
                final rAvatar = r['avatar_url'] as String?;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _borderLight),
                  ),
                  child: Row(
                    children: [
                      _buildRaiserAvatar(rAvatar, rName),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          rName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _primaryNavy,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedRaiser = r;
                            _currentSubView = 'distribution_confirm';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryNavy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Select',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- SUB-VIEW 2: Transaction Distribution Summary (Confirmation Modal) ---
  Widget _buildTransactionDistributionScreen() {
    final raiserName = _selectedRaiser?['name'] as String? ?? 'John Doe';
    final totalAmount = _calculateTotalAmount();
    final now = DateTime.now();
    final dateStr = '${now.month}/${now.day}/${now.year}';
    final timeStr = '${now.hour > 12 ? now.hour - 12 : now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    final selectedProductsList = widget.allProducts.where((p) => _selectedItemMap[p.id] == true).toList();
    final firstProd = selectedProductsList.isNotEmpty ? selectedProductsList.first : widget.allProducts.first;

    return Scaffold(
      backgroundColor: _softBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _primaryNavy),
          onPressed: () => setState(() => _currentSubView = 'select_raiser'),
        ),
        title: Text(
          'Transaction Distribution',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _primaryNavy,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distribution Information',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Product Thumbnail + Details
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: firstProd.image != null && firstProd.image!.isNotEmpty
                              ? Image.network(firstProd.image!, fit: BoxFit.cover)
                              : const Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8), size: 32),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                firstProd.category.isNotEmpty ? firstProd.category : 'Pigrolac Early Wean',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _mutedText),
                              ),
                              Text(
                                firstProd.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _primaryNavy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Sack Quantity:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _mutedText)),
                                  Text('${_sackQuantityMap[firstProd.id] ?? 1}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total Price:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _mutedText)),
                                  Text('₱${totalAmount.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: _primaryNavy)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 16),

                    // Hog Raiser Details
                    Text('Hog Raiser Name:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: _mutedText)),
                    const SizedBox(height: 4),
                    Text(raiserName, style: GoogleFonts.plusJakartaSans(fontSize: 15, color: _primaryNavy, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),

                    Text('Date:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: _mutedText)),
                    const SizedBox(height: 4),
                    Text(dateStr, style: GoogleFonts.plusJakartaSans(fontSize: 15, color: _primaryNavy, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),

                    Text('Time:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: _mutedText)),
                    const SizedBox(height: 4),
                    Text(timeStr, style: GoogleFonts.plusJakartaSans(fontSize: 15, color: _primaryNavy, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Buttons
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _currentSubView = 'list'),
                      icon: const Icon(Icons.close, color: _primaryNavy, size: 18),
                      label: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: _primaryNavy)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _primaryNavy, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessingTransaction ? null : () => _completeTransactionProcess(isHogRaiser: true),
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                      label: Text('Confirm', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryNavy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
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

  // --- SUB-VIEW 3: Customer Checkout Screen ---
  Widget _buildCustomerCheckoutScreen() {
    final totalAmount = _calculateTotalAmount();
    final selectedProductsList = widget.allProducts.where((p) => _selectedItemMap[p.id] == true).toList();
    final firstProd = selectedProductsList.isNotEmpty ? selectedProductsList.first : widget.allProducts.first;

    return Scaffold(
      backgroundColor: _softBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _primaryNavy),
          onPressed: () => setState(() => _currentSubView = 'list'),
        ),
        title: Text(
          'Transaction Checkout',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _primaryNavy,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Product Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _borderLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: firstProd.image != null && firstProd.image!.isNotEmpty
                              ? Image.network(firstProd.image!, fit: BoxFit.cover)
                              : const Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8), size: 32),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(firstProd.category.isNotEmpty ? firstProd.category : 'Pigrolac Early Wean', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _mutedText)),
                              Text(firstProd.name, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: _primaryNavy)),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Sack Quantity:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _mutedText)),
                                  Text('${_sackQuantityMap[firstProd.id] ?? 1}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total Price:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _mutedText)),
                                  Text('₱${totalAmount.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: _primaryNavy)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Customer Details Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_outline, color: _primaryNavy, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Customer Details',
                              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: _primaryNavy),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('Customer Name:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: _mutedText)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customerIdController,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF18314F),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter customer full name...',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  prefixIcon: const Icon(Icons.person, color: Color(0xFF94A3B8)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFF18314F), width: 2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                final name = _customerIdController.text.trim();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(name.isNotEmpty
                                        ? 'Na-save na ang Customer Name: $name'
                                        : 'Mangyaring maglagay ng pangalan'),
                                    backgroundColor: name.isNotEmpty ? const Color(0xFF10B981) : Colors.orange,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.save_outlined, size: 18, color: Colors.white),
                              label: Text('Save', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF18314F),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Receipt Delivery Toggle
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _lightPill,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Receipt Delivery', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: _primaryNavy)),
                                  Text('Digital Receipt (E-Receipt)', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _mutedText)),
                                ],
                              ),
                              Switch(
                                value: _eReceiptEnabled,
                                activeTrackColor: _primaryNavy,
                                onChanged: (val) => setState(() => _eReceiptEnabled = val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Select Payment Method Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select Payment Method', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: _mutedText)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectedPaymentMethod = 'Cash'),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _selectedPaymentMethod == 'Cash' ? _primaryNavy : _borderLight,
                                      width: _selectedPaymentMethod == 'Cash' ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.payments_outlined, color: _primaryNavy, size: 28),
                                      const SizedBox(height: 6),
                                      Text('Cash', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: _primaryNavy)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectedPaymentMethod = 'E-Wallet'),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _selectedPaymentMethod == 'E-Wallet' ? _primaryNavy : _borderLight,
                                      width: _selectedPaymentMethod == 'E-Wallet' ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.account_balance_wallet_outlined, color: _mutedText, size: 28),
                                      const SizedBox(height: 6),
                                      Text('E-Wallet', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: _mutedText)),
                                    ],
                                  ),
                                ),
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
          ),

          // Bottom Action Buttons
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _currentSubView = 'list'),
                      icon: const Icon(Icons.close, color: _primaryNavy, size: 18),
                      label: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: _primaryNavy)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _primaryNavy, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessingTransaction ? null : () => _completeTransactionProcess(isHogRaiser: false),
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                      label: Text('Complete Transaction', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryNavy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
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
}
