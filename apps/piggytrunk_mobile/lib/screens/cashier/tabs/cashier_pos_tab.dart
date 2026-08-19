import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/models/pos_model.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../widgets/cashier_empty_state.dart';
import '../widgets/cashier_sales_history_view.dart';
import '../widgets/cashier_checkout_modal.dart';
import '../widgets/cashier_receipt_modal.dart';

class CashierPOSTab extends StatefulWidget {
  final List<POSProduct> allProducts;
  final List<String> categories;
  final String selectedCategory;
  final Order currentOrder;
  final bool showSalesHistory;
  final List<Map<String, dynamic>> salesLogs;
  final bool isLoadingSales;
  final String cashierName;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<POSProduct> onAddToCart;
  final VoidCallback onShowCartSummary;
  final Function(OrderItem item, int newQuantity) onUpdateItemQuantity;
  final Function(OrderItem item) onRemoveItem;
  final VoidCallback onClearCart;
  final Future<void> Function({
    required String customerName,
    required String customerType,
    required String paymentMethod,
    required double tenderedAmount,
    required double changeAmount,
    required Order order,
  }) onCompleteSale;
  final Future<void> Function() onRefresh;

  const CashierPOSTab({
    super.key,
    required this.allProducts,
    required this.categories,
    required this.selectedCategory,
    required this.currentOrder,
    required this.showSalesHistory,
    required this.salesLogs,
    required this.isLoadingSales,
    required this.cashierName,
    required this.onCategorySelected,
    required this.onAddToCart,
    required this.onShowCartSummary,
    required this.onUpdateItemQuantity,
    required this.onRemoveItem,
    required this.onClearCart,
    required this.onCompleteSale,
    required this.onRefresh,
  });

  @override
  State<CashierPOSTab> createState() => _CashierPOSTabState();
}

class _CashierPOSTabState extends State<CashierPOSTab> {
  static const Color _brandNavy = Color(0xFF18314F);
  static const Color _cardBorder = Color(0xFFE2E8F0);
  static const Color _emeraldGreen = Color(0xFF10B981);
  static const Color _criticalRed = Color(0xFFDC2626);

  final TextEditingController _searchCtrl = TextEditingController();
  bool _viewSalesHistory = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return '₱${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  void _openCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCartModal(),
    );
  }

  void _openCheckoutModal() {
    if (widget.currentOrder.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty. Please add items to proceed.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CashierCheckoutModal(
        currentOrder: widget.currentOrder,
        cashierName: widget.cashierName,
        onConfirmCheckout: ({
          required customerName,
          required customerType,
          required paymentMethod,
          required tenderedAmount,
          required changeAmount,
          required order,
        }) async {
          await widget.onCompleteSale(
            customerName: customerName,
            customerType: customerType,
            paymentMethod: paymentMethod,
            tenderedAmount: tenderedAmount,
            changeAmount: changeAmount,
            order: order,
          );

          if (!mounted) return;
          final orderSnapshot = List<OrderItem>.from(order.items);
          final totalSnapshot = order.total;
          widget.onClearCart();

          // Show Digital Receipt Modal
          showDialog(
            context: this.context,
            barrierDismissible: false,
            builder: (ctx) => CashierReceiptModal(
              receiptNumber: DateTime.now().millisecondsSinceEpoch.toString().substring(5),
              customerName: customerName,
              cashierName: widget.cashierName,
              timestamp: DateTime.now(),
              items: orderSnapshot,
              totalAmount: totalSnapshot,
              paymentMethod: paymentMethod,
              tenderedAmount: tenderedAmount,
              changeAmount: changeAmount,
              onDone: () {
                Navigator.pop(ctx);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCartModal() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        final order = widget.currentOrder;

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Modal Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Order Cart',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: _brandNavy,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _brandNavy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${order.totalItems} items',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _brandNavy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (order.items.isNotEmpty) ...[
                        TextButton.icon(
                          onPressed: () {
                            widget.onClearCart();
                            setModalState(() {});
                            setState(() {});
                          },
                          icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.red),
                          label: Text(
                            'Clear',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                // Cart Items List
                Expanded(
                  child: order.items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text(
                                'Your cart is empty',
                                style: GoogleFonts.plusJakartaSans(
                                  color: PiggyTrunkTheme.ptMuted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          itemCount: order.items.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = order.items[index];

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  // Thumbnail
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: item.image != null && item.image!.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(item.image!, fit: BoxFit.cover),
                                          )
                                        : const Icon(Icons.inventory_2_rounded, color: _brandNavy, size: 22),
                                  ),
                                  const SizedBox(width: 12),

                                  // Title & Unit Price
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                            color: _brandNavy,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_formatCurrency(item.price)} each',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            color: PiggyTrunkTheme.ptMuted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Stepper Controls (- Qty +)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFD7E3F3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            if (item.quantity > 1) {
                                              widget.onUpdateItemQuantity(item, item.quantity - 1);
                                            } else {
                                              widget.onRemoveItem(item);
                                            }
                                            setModalState(() {});
                                            setState(() {});
                                          },
                                          borderRadius: BorderRadius.circular(8),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            child: Icon(Icons.remove, size: 14, color: _brandNavy),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Text(
                                            '${item.quantity}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: _brandNavy,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            widget.onUpdateItemQuantity(item, item.quantity + 1);
                                            setModalState(() {});
                                            setState(() {});
                                          },
                                          borderRadius: BorderRadius.circular(8),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            child: Icon(Icons.add, size: 14, color: _brandNavy),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Item Total (Symmetrically aligned on the right)
                                  SizedBox(
                                    width: 78,
                                    child: Text(
                                      _formatCurrency(item.total),
                                      textAlign: TextAlign.right,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                        color: _brandNavy,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // Bottom Checkout Action Bar (Cleanly pinned to bottom)
                if (order.items.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Grand Total',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: PiggyTrunkTheme.ptMuted,
                              ),
                            ),
                            Text(
                              _formatCurrency(order.total),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: _brandNavy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _openCheckoutModal();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _brandNavy,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: Text(
                              'Proceed to Payment (${_formatCurrency(order.total)})',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_viewSalesHistory) {
      return Column(
        children: [
          // Header Bar to return to POS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _viewSalesHistory = false),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _brandNavy),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Sales & Receipts Log',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _brandNavy,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_rounded, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.salesLogs.length} Receipts',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CashierSalesHistoryView(
              salesLogs: widget.salesLogs,
              isLoadingSales: widget.isLoadingSales,
              cashierName: widget.cashierName,
              onBackToPOS: () => setState(() => _viewSalesHistory = false),
            ),
          ),
        ],
      );
    }

    final query = _searchCtrl.text.trim().toLowerCase();
    final activeProducts = widget.allProducts.where((p) => !p.isArchived).toList();

    final filtered = activeProducts.where((p) {
      // Category filter
      if (widget.selectedCategory != 'All' &&
          p.category.toLowerCase() != widget.selectedCategory.toLowerCase()) {
        return false;
      }

      // Search filter
      if (query.isNotEmpty) {
        final matchesName = p.name.toLowerCase().contains(query);
        final matchesDesc = p.description.toLowerCase().contains(query);
        final matchesCat = p.category.toLowerCase().contains(query);
        return matchesName || matchesDesc || matchesCat;
      }
      return true;
    }).toList();

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          RefreshIndicator(
            onRefresh: widget.onRefresh,
            color: _brandNavy,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                20.0,
                16.0,
                20.0,
                widget.currentOrder.items.isNotEmpty ? 110.0 : 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Search Bar & Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _cardBorder),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (_) => setState(() {}),
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _brandNavy),
                            decoration: InputDecoration(
                              hintText: 'Search products by name or category...',
                              hintStyle: GoogleFonts.plusJakartaSans(color: PiggyTrunkTheme.ptMuted, fontSize: 12),
                              prefixIcon: const Icon(Icons.search, color: PiggyTrunkTheme.ptMuted, size: 20),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16, color: PiggyTrunkTheme.ptMuted),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Sales History / Receipts Button
                      Container(
                        height: 46,
                        width: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _cardBorder),
                        ),
                        child: IconButton(
                          onPressed: () => setState(() => _viewSalesHistory = true),
                          icon: const Icon(Icons.receipt_long_rounded, color: _brandNavy, size: 22),
                          tooltip: 'Sales History',
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Cart Icon Button with Live Counter Badge
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 46,
                            width: 46,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: widget.currentOrder.items.isNotEmpty
                                    ? _brandNavy.withValues(alpha: 0.4)
                                    : _cardBorder,
                              ),
                            ),
                            child: IconButton(
                              onPressed: _openCartBottomSheet,
                              icon: const Icon(Icons.shopping_cart_outlined, color: _brandNavy, size: 22),
                              tooltip: 'View Cart & Checkout',
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          if (widget.currentOrder.totalItems > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${widget.currentOrder.totalItems}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Categories Selector - Balanced 5-item full width Row
                  Row(
                    children: widget.categories.map((cat) {
                      final isSelected = widget.selectedCategory.toLowerCase() == cat.toLowerCase();
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.5),
                          child: GestureDetector(
                            onTap: () => widget.onCategorySelected(cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? _brandNavy : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? _brandNavy : _cardBorder,
                                  width: 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: _brandNavy.withValues(alpha: 0.18),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                cat,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? Colors.white : const Color(0xFF475569),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Product Catalog Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filtered.length} Products in Catalog',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _brandNavy,
                        ),
                      ),
                      if (widget.currentOrder.totalItems > 0) ...[
                        Text(
                          '${widget.currentOrder.totalItems} in Cart',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _emeraldGreen,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Products List
                  filtered.isEmpty
                      ? const CashierEmptyState(
                          message: 'No available products in this category.',
                          icon: Icons.storefront_outlined,
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final p = filtered[index];
                            final isInCart = widget.currentOrder.containsProduct(p.id);
                            final cartQty = widget.currentOrder.quantityFor(p.id);
                            final isOutOfStock = p.stock <= 0;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isInCart ? _brandNavy : _cardBorder,
                                  width: isInCart ? 1.5 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _brandNavy.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Thumbnail
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F8FE),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: _cardBorder),
                                    ),
                                    child: p.image != null && p.image!.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(14),
                                            child: Image.network(p.image!, fit: BoxFit.cover),
                                          )
                                        : const Icon(Icons.inventory_2_rounded, color: _brandNavy, size: 28),
                                  ),
                                  const SizedBox(width: 14),

                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: _brandNavy.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                p.category.toUpperCase(),
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  color: _brandNavy,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isOutOfStock ? '• Out of Stock' : '• ${p.stock} in stock',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isOutOfStock ? _criticalRed : _emeraldGreen,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          p.name,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: _brandNavy,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₱${p.price.toStringAsFixed(2)}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: _brandNavy,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Add to Cart / Quantity Badge Button
                                  if (isOutOfStock) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Empty',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ),
                                  ] else if (isInCart) ...[
                                    GestureDetector(
                                      onTap: _openCartBottomSheet,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: _brandNavy,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check, size: 16, color: Colors.white),
                                            const SizedBox(width: 4),
                                            Text(
                                              'x$cartQty',
                                              style: GoogleFonts.plusJakartaSans(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    ElevatedButton.icon(
                                      onPressed: () => widget.onAddToCart(p),
                                      icon: const Icon(Icons.add_shopping_cart, size: 16, color: Colors.white),
                                      label: Text(
                                        'Add',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _brandNavy,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),

          // Bottom Cart & Checkout Bar (Docked flush at the bottom of the screen)
          if (widget.currentOrder.items.isNotEmpty) ...[
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                decoration: BoxDecoration(
                  color: _brandNavy,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: _openCartBottomSheet,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${widget.currentOrder.totalItems} Items Selected',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatCurrency(widget.currentOrder.total),
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _openCheckoutModal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _brandNavy,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Checkout',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: _brandNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
