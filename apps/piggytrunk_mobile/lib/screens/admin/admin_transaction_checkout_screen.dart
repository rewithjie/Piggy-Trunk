import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminMobileTransactionCheckoutScreen extends StatefulWidget {
  final Map<String, dynamic>? checkoutData;

  const AdminMobileTransactionCheckoutScreen({
    super.key,
    this.checkoutData,
  });

  @override
  State<AdminMobileTransactionCheckoutScreen> createState() =>
      _AdminMobileTransactionCheckoutScreenState();
}

class _AdminMobileTransactionCheckoutScreenState
    extends State<AdminMobileTransactionCheckoutScreen> {
  // Brand color tokens (Aligned with Piggy Trunk Design System)
  static const Color _brandNavy = Color(0xFF18314F);
  static const Color _cardBorder = Color(0xFFE2E8F0);
  static const Color _textMuted = Color(0xFF6F8096);
  static const Color _emeraldGreen = Color(0xFF10B981);
  static const Color _wineRed = Color(0xFF8B1D35); // Solid wine button color

  final TextEditingController _customerIdCtrl = TextEditingController();
  bool _isDigitalReceipt = true;
  String _selectedPaymentMethod = 'Cash'; // 'Cash' or 'E-Wallet'
  bool _isSubmitting = false;
  bool _showSuccessConfirmation = false;

  late String _productName;
  late String _categoryName;
  late int _sackQuantity;
  late double _totalPrice;

  @override
  void initState() {
    super.initState();
    final data = widget.checkoutData ?? {};
    _productName = (data['productName'] as String?) ?? 'IMMUNOBOOSTER';
    _categoryName = (data['category'] as String?) ?? 'Pigrolac Early Wean';
    _sackQuantity = (data['sackQuantity'] as num?)?.toInt() ?? 2;
    _totalPrice = (data['totalPrice'] as num?)?.toDouble() ?? 10000.00;
  }

  @override
  void dispose() {
    _customerIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCompleteTransaction() async {
    setState(() => _isSubmitting = true);

    try {
      final String customerId = _customerIdCtrl.text.trim().isNotEmpty
          ? _customerIdCtrl.text.trim()
          : 'Walk-in Customer';

      // 1. Insert into Supabase sales table
      try {
        await Supabase.instance.client.from('sales').insert({
          'total_amount': _totalPrice,
          'quantity': _sackQuantity,
          'sale_date': DateTime.now().toIso8601String(),
          'type': 'pos_cashier',
        });
      } catch (e) {
        debugPrint('Sales record fallback: $e');
      }

      // 2. Insert into inventory_logs table
      try {
        await Supabase.instance.client.from('inventory_logs').insert({
          'product_name': _productName,
          'action': 'SALE',
          'units': _sackQuantity,
          'price': _totalPrice,
          'details': 'POS Sale to $customerId via $_selectedPaymentMethod',
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Inventory logs insert fallback: $e');
      }

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _showSuccessConfirmation = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card 1: Product & Customer Details
                        _buildProductAndCustomerCard(),
                        const SizedBox(height: 16),

                        // Card 2: Select Payment Method
                        _buildPaymentMethodCard(),
                      ],
                    ),
                  ),
                ),
                _buildBottomActionButtons(),
              ],
            ),

            // Success Confirmation Overlay Card
            if (_showSuccessConfirmation) _buildSuccessNotificationCard(),
          ],
        ),
      ),
    );
  }

  // 1. Top App Bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: _brandNavy, size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Transaction Checkout',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF991B1B), // Dark wine accent
          letterSpacing: -0.4,
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: _brandNavy, size: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onSelected: (val) {
            if (val == 'cancel') Navigator.pop(context);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'cancel',
              child: Text('Cancel Checkout'),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // 2. Card 1: Product & Customer Details
  Widget _buildProductAndCustomerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFDE8E8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Box
              Container(
                width: 70,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _cardBorder),
                ),
                child: const Center(
                  child: Icon(
                    Icons.inventory_2_rounded,
                    size: 38,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _categoryName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _productName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: _brandNavy,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Sack Quantity Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sack Quantity:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        Text(
                          _sackQuantity.toString(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _brandNavy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Total Price Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Price:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        Text(
                          '₱${_totalPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF991B1B), // Wine red
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Customer Details Section Header
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF991B1B)),
              const SizedBox(width: 8),
              Text(
                'Customer Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF991B1B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Customer ID Label & Input
          Text(
            'Customer ID:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _brandNavy,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _cardBorder),
            ),
            child: TextField(
              controller: _customerIdCtrl,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: _brandNavy,
              ),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF94A3B8)),
                hintText: 'e.g. John Doe',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Receipt Delivery Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6F4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE8E8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receipt Delivery',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Digital Receipt (E-Receipt)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: _textMuted,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _isDigitalReceipt,
                  activeThumbColor: _wineRed,
                  activeTrackColor: const Color(0xFFFCA5A5),
                  onChanged: (val) => setState(() => _isDigitalReceipt = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Card 2: Select Payment Method
  Widget _buildPaymentMethodCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFDE8E8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Payment Method',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: _brandNavy,
            ),
          ),
          const SizedBox(height: 14),

          // 2-Column Payment Method Selector (Cash vs E-Wallet)
          Row(
            children: [
              // Cash Pill
              Expanded(
                child: _buildPaymentPill(
                  label: 'Cash',
                  icon: Icons.payments_outlined,
                  isSelected: _selectedPaymentMethod == 'Cash',
                  onTap: () => setState(() => _selectedPaymentMethod = 'Cash'),
                ),
              ),
              const SizedBox(width: 12),

              // E-Wallet Pill
              Expanded(
                child: _buildPaymentPill(
                  label: 'E-Wallet',
                  icon: Icons.credit_card_rounded,
                  isSelected: _selectedPaymentMethod == 'E-Wallet',
                  onTap: () => setState(() => _selectedPaymentMethod = 'E-Wallet'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF1F2) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B1D35) : _cardBorder,
            width: isSelected ? 1.8 : 1.2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? _wineRed : const Color(0xFF64748B),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isSelected ? _wineRed : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Dual Bottom Action Buttons: [ ✕ Cancel ] and [ ✓ Complete Transaction ]
  Widget _buildBottomActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel Button (Outlined Wine)
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _wineRed,
                  side: const BorderSide(color: _wineRed, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 20),
                label: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Complete Transaction Button (Solid Wine)
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _wineRed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isSubmitting ? null : _handleCompleteTransaction,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: Text(
                  _isSubmitting ? 'PROCESSING...' : 'Complete\nTransaction',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Success Notification Card Overlay matching Piggy Trunk branding
  Widget _buildSuccessNotificationCard() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6F4),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFFDE8E8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Circular Success Badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _emeraldGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: _emeraldGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title: Transaction Successfully Completed!
              Text(
                'Transaction Successfully Completed!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _brandNavy,
                  letterSpacing: -0.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Subtitle Breakdown
              Text(
                'Total Amount: ₱${_totalPrice.toStringAsFixed(2)}\n$_sackQuantity Sacks of $_productName\nPayment: $_selectedPaymentMethod',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textMuted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 26),

              // Done Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _wineRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    // Return all the way to POS/Portal
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: Text(
                    'Done',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
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
