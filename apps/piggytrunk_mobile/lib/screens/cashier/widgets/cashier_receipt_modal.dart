import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/models/pos_model.dart';
import 'package:piggytrunk/theme/app_theme.dart';

class CashierReceiptModal extends StatelessWidget {
  final String receiptNumber;
  final String customerName;
  final String cashierName;
  final DateTime timestamp;
  final List<OrderItem> items;
  final double totalAmount;
  final String paymentMethod;
  final double tenderedAmount;
  final double changeAmount;
  final VoidCallback onDone;

  const CashierReceiptModal({
    super.key,
    required this.receiptNumber,
    required this.customerName,
    required this.cashierName,
    required this.timestamp,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.tenderedAmount,
    required this.changeAmount,
    required this.onDone,
  });

  static const Color _brandNavy = Color(0xFF18314F);
  static const Color _emeraldGreen = Color(0xFF10B981);

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $hour:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _emeraldGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: _emeraldGreen, size: 40),
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                'Payment Successful!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _brandNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Receipt #$receiptNumber',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: PiggyTrunkTheme.ptMuted,
                ),
              ),
              const SizedBox(height: 16),

              // Total Amount Hero
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8FE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD7E3F3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'TOTAL PAID',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: PiggyTrunkTheme.ptMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${totalAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _brandNavy,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Meta details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Customer:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: PiggyTrunkTheme.ptMuted)),
                  Text(customerName, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: _brandNavy)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cashier:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: PiggyTrunkTheme.ptMuted)),
                  Text(cashierName, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: _brandNavy)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Payment:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: PiggyTrunkTheme.ptMuted)),
                  Text(paymentMethod, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: _brandNavy)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Date/Time:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: PiggyTrunkTheme.ptMuted)),
                  Text(_formatDate(timestamp), style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: _brandNavy)),
                ],
              ),
              const SizedBox(height: 14),

              // Divider line
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 8),

              // Items breakdown
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Purchased Items',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _brandNavy,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, idx) {
                  final item = items[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity}x ${item.productName}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _brandNavy, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '₱${item.total.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: _brandNavy),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 6),

              // Payment Calculation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Amount Tendered:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: PiggyTrunkTheme.ptMuted)),
                  Text('₱${tenderedAmount.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: _brandNavy)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Change Due (Sukli):', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: _emeraldGreen)),
                  Text('₱${changeAmount.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: _emeraldGreen)),
                ],
              ),
              const SizedBox(height: 24),

              // Done Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandNavy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Done & New Transaction',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
