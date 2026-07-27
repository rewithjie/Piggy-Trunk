import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/models/pos_model.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../widgets/cashier_empty_state.dart';
import '../widgets/cashier_restock_view.dart';

class CashierInventoryTab extends StatelessWidget {
  final List<POSProduct> allProducts;
  final POSProduct? selectedRestockProduct;
  final int restockQuantity;
  final TextEditingController priceController;
  final int selectedInventoryTab; // 0 = Fattening, 1 = Sow
  final ValueChanged<int> onTabChanged;
  final ValueChanged<POSProduct> onOpenRestockScreen;
  final ValueChanged<int> onQuantityChanged;
  final Future<void> Function(POSProduct product, int amount, double newPrice) onPerformRestock;

  const CashierInventoryTab({
    super.key,
    required this.allProducts,
    required this.selectedRestockProduct,
    required this.restockQuantity,
    required this.priceController,
    required this.selectedInventoryTab,
    required this.onTabChanged,
    required this.onOpenRestockScreen,
    required this.onQuantityChanged,
    required this.onPerformRestock,
  });

  bool _isSowProduct(POSProduct p) {
    final nameLower = p.name.toLowerCase();
    final descLower = p.description.toLowerCase();
    final catLower = p.category.toLowerCase();
    if (catLower.contains('sow')) return true;
    final sowKeywords = ['sow', 'gestating', 'lactating', 'gestation', 'lactation', 'breeding', 'breed', 'brood'];
    for (final kw in sowKeywords) {
      if (nameLower.contains(kw) || descLower.contains(kw)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (selectedRestockProduct != null) {
      return CashierRestockView(
        product: selectedRestockProduct!,
        restockQuantity: restockQuantity,
        priceController: priceController,
        onQuantityChanged: onQuantityChanged,
        onPerformRestock: onPerformRestock,
      );
    }

    final filtered = allProducts.where((p) {
      final isSow = _isSowProduct(p);
      final matchesTab = (selectedInventoryTab == 0 && !isSow) || (selectedInventoryTab == 1 && isSow);
      return matchesTab;
    }).toList();

    return Column(
      children: [
        const SizedBox(height: 16),
        // Tabs selector (Fattening & Sow)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Container(
            height: 50,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE6EDF6),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTabChanged(0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selectedInventoryTab == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(21),
                        boxShadow: selectedInventoryTab == 0
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF18314F).withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Fattening',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: selectedInventoryTab == 0 ? const Color(0xFF18314F) : const Color(0xFF909BB0),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTabChanged(1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selectedInventoryTab == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(21),
                        boxShadow: selectedInventoryTab == 1
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF18314F).withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Sow',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: selectedInventoryTab == 1 ? const Color(0xFF18314F) : const Color(0xFF909BB0),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Product list view
        Expanded(
          child: filtered.isEmpty
              ? const CashierEmptyState(
                  message: 'Walang laman sa kasalukuyan',
                  icon: Icons.inventory_2_outlined,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final p = filtered[index];
                    final double maxCapacity = 73.0;
                    final int percent = (p.units / maxCapacity * 100).round().clamp(0, 100);
                    final bool isCritical = percent <= 15;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: PiggyTrunkTheme.ptBorder,
                          width: 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 68,
                                      height: 68,
                                      decoration: BoxDecoration(
                                        color: PiggyTrunkTheme.ptBg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: PiggyTrunkTheme.ptBorder),
                                      ),
                                      child: p.image != null && p.image!.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.network(p.image!, fit: BoxFit.cover),
                                            )
                                          : const Icon(Icons.inventory_2_outlined, color: Color(0xFF18314F), size: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.description.trim().isNotEmpty ? p.description : 'Pigrolac Early Wean',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: PiggyTrunkTheme.ptMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            p.name.toUpperCase(),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF18314F),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isCritical ? const Color(0xFFFFF1F2) : const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Capacity Stock:',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isCritical ? const Color(0xFFE11D48) : const Color(0xFF16A34A),
                                        ),
                                      ),
                                      Text(
                                        '${p.units} / 73 Sacks',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: isCritical ? const Color(0xFFE11D48) : const Color(0xFF16A34A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 8,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEBEBEB),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: percent / 100.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isCritical ? const Color(0xFFF43F5E) : const Color(0xFF2DD4BF),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: () => onOpenRestockScreen(p),
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: Text(
                                      'RESTOCK',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3F8CFF),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          if (isCritical)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFD5D5),
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'CRITICAL STOCK',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFFD32F2F),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            )
                        ],
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }
}
