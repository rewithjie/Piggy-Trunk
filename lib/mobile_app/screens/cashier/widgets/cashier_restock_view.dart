import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/models/pos_model.dart';
import 'package:piggytrunk/theme/app_theme.dart';

class CashierRestockView extends StatelessWidget {
  final POSProduct product;
  final int restockQuantity;
  final TextEditingController priceController;
  final ValueChanged<int> onQuantityChanged;
  final Future<void> Function(POSProduct product, int amount, double newPrice) onPerformRestock;

  const CashierRestockView({
    super.key,
    required this.product,
    required this.restockQuantity,
    required this.priceController,
    required this.onQuantityChanged,
    required this.onPerformRestock,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Product summary card
          Container(
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
                  child: product.image != null && product.image!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(product.image!, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.inventory_2_outlined, color: Color(0xFF18314F), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.description.trim().isNotEmpty ? product.description : 'Pigrolac Early Wean',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: PiggyTrunkTheme.ptMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.name.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF18314F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Unit Price/Sack',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: PiggyTrunkTheme.ptMuted,
                            ),
                          ),
                          Text(
                            '₱${product.price.toStringAsFixed(2)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF18314F),
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
          const SizedBox(height: 20),

          // Quantity Stepper Block
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PiggyTrunkTheme.ptBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ilang Sack ang idadagdag?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: PiggyTrunkTheme.ptMuted,
                      ),
                    ),
                    Text(
                      'Stock: ${product.units}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF18314F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (restockQuantity > 1) {
                            onQuantityChanged(restockQuantity - 1);
                          }
                        },
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: PiggyTrunkTheme.ptBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: PiggyTrunkTheme.ptBorder),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.remove, color: Color(0xFF18314F)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: PiggyTrunkTheme.ptBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: PiggyTrunkTheme.ptBorder),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$restockQuantity',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF18314F),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onQuantityChanged(restockQuantity + 1),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: PiggyTrunkTheme.ptBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: PiggyTrunkTheme.ptBorder),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.add, color: Color(0xFF18314F)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Price Field Block
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PiggyTrunkTheme.ptBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bagong Presyo bawat Sack (₱)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: PiggyTrunkTheme.ptMuted,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF18314F),
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF18314F)),
                    filled: true,
                    fillColor: PiggyTrunkTheme.ptBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: PiggyTrunkTheme.ptBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: PiggyTrunkTheme.ptBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF18314F), width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Submit Restock Button
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                final double? parsedPrice = double.tryParse(priceController.text);
                if (parsedPrice != null && parsedPrice > 0) {
                  onPerformRestock(product, restockQuantity, parsedPrice);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'RESTOCK',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
