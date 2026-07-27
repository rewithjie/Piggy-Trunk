import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import 'cashier_empty_state.dart';

class CashierSalesHistoryView extends StatefulWidget {
  final List<Map<String, dynamic>> salesLogs;
  final bool isLoadingSales;

  const CashierSalesHistoryView({
    super.key,
    required this.salesLogs,
    required this.isLoadingSales,
  });

  @override
  State<CashierSalesHistoryView> createState() => _CashierSalesHistoryViewState();
}

class _CashierSalesHistoryViewState extends State<CashierSalesHistoryView> {
  int _selectedSalesHistoryTab = 0; // 0 = Recent, 1 = Historical

  @override
  Widget build(BuildContext context) {
    final displayLogs = widget.salesLogs.where((log) {
      if (_selectedSalesHistoryTab == 0) {
        return true;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Tabs Header Bar
        Container(
          height: 48,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: PiggyTrunkTheme.ptBorder)),
          ),
          child: Row(
            children: [
              // Recent Purchased tab
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedSalesHistoryTab = 0),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedSalesHistoryTab == 0 ? const Color(0xFF18314F) : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      'RECENT PURCHASED',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _selectedSalesHistoryTab == 0 ? const Color(0xFF18314F) : PiggyTrunkTheme.ptMuted,
                      ),
                    ),
                  ),
                ),
              ),
              // Historical tab
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedSalesHistoryTab = 1),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedSalesHistoryTab == 1 ? const Color(0xFF18314F) : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      'HISTORICAL',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _selectedSalesHistoryTab == 1 ? const Color(0xFF18314F) : PiggyTrunkTheme.ptMuted,
                      ),
                    ),
                  ),
                ),
              ),
              // Filter button
              InkWell(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: double.infinity,
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, size: 16, color: PiggyTrunkTheme.ptMuted),
                      const SizedBox(width: 4),
                      Text(
                        'FILTER',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: PiggyTrunkTheme.ptMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Logs list
        Expanded(
          child: widget.isLoadingSales
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF18314F)))
              : (displayLogs.isEmpty
                  ? const CashierEmptyState(
                      message: 'Walang laman sa kasalukuyan',
                      icon: Icons.receipt_long_outlined,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: displayLogs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildSalesCard(displayLogs[index]);
                      },
                    )),
        ),
      ],
    );
  }

  Widget _buildSalesCard(Map<String, dynamic> sale) {
    final product = sale['product'] as Map<String, dynamic>?;
    final String productName = product != null ? (product['name'] as String).toUpperCase() : 'IMMUNOBOOSTER';
    final String categoryName = product != null ? (product['description'] as String? ?? '').trim() : 'Pigrolac Early Wean';
    final String imageUrl = product != null ? (product['image'] as String? ?? '') : '';
    final int quantity = sale['quantity'] as int? ?? 1;
    final double totalAmount = (sale['total_amount'] as num?)?.toDouble() ?? 0.0;
    
    final bool isKilo = productName.toLowerCase().contains('kilo') || categoryName.toLowerCase().contains('kilo');
    final String quantityLabel = isKilo ? 'Total Kilo:' : 'Total Sack:';
    final String quantityValue = isKilo ? '1/2' : '$quantity';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PiggyTrunkTheme.ptBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: PiggyTrunkTheme.ptBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PiggyTrunkTheme.ptBorder),
            ),
            child: imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(imageUrl, fit: BoxFit.cover),
                  )
                : const Icon(Icons.inventory_2_outlined, color: Color(0xFF18314F), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName.isNotEmpty ? categoryName : 'Pigrolac Early Wean',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: PiggyTrunkTheme.ptMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  productName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF18314F),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      quantityLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PiggyTrunkTheme.ptMuted,
                      ),
                    ),
                    Text(
                      quantityValue,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF18314F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Price:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PiggyTrunkTheme.ptMuted,
                      ),
                    ),
                    Text(
                      '₱${totalAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFC04F5E),
                      ),
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
}
