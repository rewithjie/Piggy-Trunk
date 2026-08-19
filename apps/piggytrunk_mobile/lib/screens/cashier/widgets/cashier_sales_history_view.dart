import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/models/pos_model.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import 'cashier_receipt_modal.dart';

class CashierSalesHistoryView extends StatefulWidget {
  final List<Map<String, dynamic>> salesLogs;
  final bool isLoadingSales;
  final String cashierName;
  final VoidCallback? onBackToPOS;

  const CashierSalesHistoryView({
    super.key,
    required this.salesLogs,
    required this.isLoadingSales,
    this.cashierName = 'Cashier Staff',
    this.onBackToPOS,
  });

  @override
  State<CashierSalesHistoryView> createState() => _CashierSalesHistoryViewState();
}

class _CashierSalesHistoryViewState extends State<CashierSalesHistoryView> {
  int _selectedFilterIndex = 0; // 0 = All, 1 = Today, 2 = Feeds, 3 = Meds
  final TextEditingController _searchCtrl = TextEditingController();

  static const Color _brandNavy = Color(0xFF18314F);
  static const Color _emeraldGreen = Color(0xFF10B981);
  static const Color _cardBorder = Color(0xFFE2E8F0);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return '₱${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return 'Recent';
    try {
      final dt = DateTime.parse(dateVal.toString());
      final now = DateTime.now();
      final difference = now.difference(dt);

      if (difference.inMinutes < 60) {
        return difference.inMinutes <= 1 ? 'Just now' : '${difference.inMinutes}m ago';
      }

      final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');

      if (isToday) {
        return 'Today • $hour:$min $ampm';
      }

      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $hour:$min $ampm';
    } catch (_) {
      return dateVal.toString();
    }
  }

  void _showReceiptModal(Map<String, dynamic> sale) {
    final product = sale['product'] as Map<String, dynamic>?;
    final String productName = product != null ? (product['name'] as String) : (sale['product_name'] ?? 'IMMUNOBOOSTER');
    final double totalAmount = (sale['total_amount'] as num?)?.toDouble() ?? 0.0;
    final int quantity = sale['quantity'] as int? ?? 1;
    final double unitPrice = quantity > 0 ? totalAmount / quantity : totalAmount;
    final String dateStr = sale['sale_date'] ?? sale['created_at'] ?? DateTime.now().toIso8601String();
    final DateTime dt = DateTime.tryParse(dateStr) ?? DateTime.now();
    final String receiptNumber = sale['id'] != null
        ? sale['id'].toString().padLeft(6, '0')
        : dt.millisecondsSinceEpoch.toString().substring(6);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CashierReceiptModal(
        receiptNumber: receiptNumber,
        customerName: sale['customer_name'] ?? 'Walk-in Customer',
        cashierName: sale['cashier_name'] ?? widget.cashierName,
        timestamp: dt,
        items: [
          OrderItem(
            id: sale['id'] is int ? sale['id'] as int : 1,
            productId: (sale['product_id'] ?? '0').toString(),
            productName: productName,
            price: unitPrice,
            quantity: quantity,
            image: product != null ? product['image'] : null,
          ),
        ],
        totalAmount: totalAmount,
        paymentMethod: sale['payment_method'] ?? 'Cash',
        tenderedAmount: (sale['tendered_amount'] as num?)?.toDouble() ?? totalAmount,
        changeAmount: (sale['change_amount'] as num?)?.toDouble() ?? 0.0,
        onDone: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim().toLowerCase();

    // Compute Metrics
    double totalRevenue = 0.0;
    double todayRevenue = 0.0;
    final now = DateTime.now();

    for (final sale in widget.salesLogs) {
      final amount = (sale['total_amount'] as num?)?.toDouble() ?? 0.0;
      totalRevenue += amount;
      final dateVal = sale['sale_date'] ?? sale['created_at'];
      if (dateVal != null) {
        final dt = DateTime.tryParse(dateVal.toString());
        if (dt != null && dt.year == now.year && dt.month == now.month && dt.day == now.day) {
          todayRevenue += amount;
        }
      }
    }

    // Filter Logs
    final filteredLogs = widget.salesLogs.where((sale) {
      final product = sale['product'] as Map<String, dynamic>?;
      final pName = (product != null ? (product['name'] as String) : (sale['product_name'] ?? '')).toString().toLowerCase();
      final category = (product != null ? (product['category'] ?? '') : (sale['category'] ?? '')).toString().toLowerCase();
      final idStr = (sale['id'] ?? '').toString().toLowerCase();
      final customer = (sale['customer_name'] ?? '').toString().toLowerCase();

      // Tab filter
      if (_selectedFilterIndex == 1) {
        // Today
        final dateVal = sale['sale_date'] ?? sale['created_at'];
        if (dateVal != null) {
          final dt = DateTime.tryParse(dateVal.toString());
          if (dt == null || dt.year != now.year || dt.month != now.month || dt.day != now.day) {
            return false;
          }
        }
      } else if (_selectedFilterIndex == 2) {
        // Feeds
        if (!category.contains('feed') && !pName.contains('pigrolac') && !pName.contains('starter') && !pName.contains('booster')) {
          return false;
        }
      } else if (_selectedFilterIndex == 3) {
        // Medicines / Vitamins
        if (!category.contains('med') && !category.contains('vit') && !pName.contains('vetracin') && !pName.contains('apralyte') && !pName.contains('latigo')) {
          return false;
        }
      }

      // Search query filter
      if (query.isNotEmpty) {
        return pName.contains(query) || idStr.contains(query) || customer.contains(query) || category.contains(query);
      }

      return true;
    }).toList();

    return Column(
      children: [
        // Top KPI Stats Bar
        Container(
          margin: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_brandNavy, Color(0xFF1E3A5F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _brandNavy.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL SALES LOGS',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white70,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(totalRevenue),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 36,
                width: 1,
                color: Colors.white24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TODAY\'S VOLUME',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white70,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(todayRevenue),
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF34D399),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Search Field & Quick Filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _cardBorder),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: _brandNavy),
              decoration: InputDecoration(
                hintText: 'Search receipts by product, customer, or ID...',
                hintStyle: GoogleFonts.plusJakartaSans(color: PiggyTrunkTheme.ptMuted, fontSize: 11.5),
                prefixIcon: const Icon(Icons.search_rounded, color: PiggyTrunkTheme.ptMuted, size: 18),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Modern Segmented Filter Pills
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _buildFilterPill(0, 'All Logs (${widget.salesLogs.length})'),
              const SizedBox(width: 8),
              _buildFilterPill(1, 'Today'),
              const SizedBox(width: 8),
              _buildFilterPill(2, 'Feeds'),
              const SizedBox(width: 8),
              _buildFilterPill(3, 'Meds & Vits'),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Logs List or Lively Empty State
        Expanded(
          child: widget.isLoadingSales
              ? const Center(child: CircularProgressIndicator(color: _brandNavy))
              : (filteredLogs.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                      itemCount: filteredLogs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildReceiptCard(filteredLogs[index]);
                      },
                    )),
        ),
      ],
    );
  }

  Widget _buildFilterPill(int index, String title) {
    final isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilterIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? _brandNavy : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? _brandNavy : _cardBorder),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _brandNavy.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptCard(Map<String, dynamic> sale) {
    final product = sale['product'] as Map<String, dynamic>?;
    final String productName = product != null ? (product['name'] as String) : (sale['product_name'] ?? 'IMMUNOBOOSTER');
    final String categoryName = product != null ? (product['category'] ?? product['description'] ?? 'Feeds') : (sale['category'] ?? 'POS Item');
    final String imageUrl = product != null ? (product['image'] as String? ?? '') : (sale['image'] ?? '');
    final int quantity = sale['quantity'] as int? ?? 1;
    final double totalAmount = (sale['total_amount'] as num?)?.toDouble() ?? 0.0;
    final String paymentMethod = sale['payment_method'] ?? 'CASH';
    final String dateStr = sale['sale_date'] ?? sale['created_at'] ?? '';
    final String formattedDate = _formatDate(dateStr);
    final String receiptId = sale['id'] != null ? '#REC-${sale['id'].toString().padLeft(5, '0')}' : '#REC-POS';

    final isKilo = productName.toLowerCase().contains('kilo') || categoryName.toLowerCase().contains('kilo');
    final String quantityLabel = isKilo ? '$quantity kg' : '$quantity ${quantity > 1 ? 'Units' : 'Unit'}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: _brandNavy.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showReceiptModal(sale),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Top Row: Receipt ID, Date & Payment Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            receiptId,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _brandNavy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formattedDate,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: PiggyTrunkTheme.ptMuted,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: paymentMethod.toUpperCase().contains('GCASH')
                            ? const Color(0xFF007DFE).withValues(alpha: 0.1)
                            : _emeraldGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        paymentMethod.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: paymentMethod.toUpperCase().contains('GCASH')
                              ? const Color(0xFF007DFE)
                              : _emeraldGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                ),

                // Middle Row: Thumbnail, Product Name & Quantity
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _cardBorder),
                      ),
                      child: imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(imageUrl, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.receipt_long_rounded, color: _brandNavy, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _brandNavy,
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
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  categoryName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: PiggyTrunkTheme.ptMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '•  Qty: $quantityLabel',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _brandNavy,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatCurrency(totalAmount),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            color: _brandNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 12, color: _emeraldGreen),
                            const SizedBox(width: 3),
                            Text(
                              'Paid',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _emeraldGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _brandNavy.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(color: _brandNavy.withValues(alpha: 0.1), width: 2),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 38,
                color: _brandNavy,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Sales Records Found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _brandNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completed POS orders and customer digital receipts will automatically appear here with full transaction records.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: PiggyTrunkTheme.ptMuted,
                height: 1.4,
              ),
            ),
            if (widget.onBackToPOS != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: widget.onBackToPOS,
                icon: const Icon(Icons.point_of_sale_rounded, size: 18, color: Colors.white),
                label: Text(
                  'Open POS Terminal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandNavy,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
