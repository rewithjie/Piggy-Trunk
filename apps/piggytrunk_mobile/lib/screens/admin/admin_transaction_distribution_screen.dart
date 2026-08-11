import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminMobileTransactionDistributionScreen extends StatefulWidget {
  final Map<String, dynamic>? transactionData;

  const AdminMobileTransactionDistributionScreen({
    super.key,
    this.transactionData,
  });

  @override
  State<AdminMobileTransactionDistributionScreen> createState() =>
      _AdminMobileTransactionDistributionScreenState();
}

class _AdminMobileTransactionDistributionScreenState
    extends State<AdminMobileTransactionDistributionScreen> {
  // Brand color tokens (Aligned with Piggy Trunk Design System)
  static const Color _brandNavy = Color(0xFF18314F);
  static const Color _cardBorder = Color(0xFFE2E8F0);
  static const Color _textMuted = Color(0xFF6F8096);
  static const Color _emeraldGreen = Color(0xFF10B981);
  static const Color _wineRed = Color(0xFF8B1D35); // Solid wine button color

  late String _productName;
  late String _categoryName;
  late int _sackQuantity;
  late double _totalPrice;
  late String _hogRaiserName;
  late String _dateStr;
  late String _timeStr;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final data = widget.transactionData ?? {};
    _productName = (data['productName'] as String?) ?? 'IMMUNOBOOSTER';
    _categoryName = (data['category'] as String?) ?? 'Pigrolac Early Wean';
    _sackQuantity = (data['sackQuantity'] as num?)?.toInt() ?? 2;
    _totalPrice = (data['totalPrice'] as num?)?.toDouble() ?? 10000.00;
    _hogRaiserName = (data['raiserName'] as String?) ?? 'Juan Dela Cruz';

    final now = DateTime.now();
    _dateStr = '${now.month}/${now.day}/${now.year}';
    final int hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final String minute = now.minute.toString().padLeft(2, '0');
    final String period = now.hour >= 12 ? 'PM' : 'AM';
    _timeStr = '$hour:$minute $period';
  }

  Future<void> _handleConfirm() async {
    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // 1. Insert into inventory_logs table
      try {
        await Supabase.instance.client.from('inventory_logs').insert({
          'product_name': _productName,
          'action': 'distributed',
          'units': _sackQuantity,
          'price': _totalPrice,
          'details': 'Distributed to $_hogRaiserName',
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Inventory log insert fallback: $e');
      }

      // 2. Insert into sales/distribution record
      try {
        await Supabase.instance.client.from('sales').insert({
          'quantity': _sackQuantity,
          'total_amount': _totalPrice,
          'sale_date': DateTime.now().toIso8601String(),
          'type': 'raiser_distribution',
        });
      } catch (e) {
        debugPrint('Sales distribution insert fallback: $e');
      }

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Transaction confirmed! $_sackQuantity sacks distributed to $_hogRaiserName.',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: _emeraldGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Pop back to distribution portal or root
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error confirming transaction: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _buildDistributionInfoCard(),
              ),
            ),
            _buildBottomActionButtons(),
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
        'Transaction Distribution',
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
              child: Text('Cancel Transaction'),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // 2. Main Distribution Information Card matching uploaded screenshot
  Widget _buildDistributionInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
          // Section Title: Distribution Information
          Text(
            'Distribution Information',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF991B1B), // Wine Red
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),

          // Product Row (Image, Category, Product Title, Sack Qty, Total Price)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Box
              Container(
                width: 72,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _cardBorder),
                ),
                child: const Center(
                  child: Icon(
                    Icons.inventory_2_rounded,
                    size: 40,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Product Details
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
                        fontSize: 17.5,
                        fontWeight: FontWeight.w900,
                        color: _brandNavy,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),

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
                    const SizedBox(height: 8),

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

          // Divider Line
          const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1.2),
          const SizedBox(height: 20),

          // Hog Raiser Name Field
          Text(
            'Hog Raiser Name:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: _brandNavy,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _hogRaiserName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 16),

          // Date Field
          Text(
            'Date:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: _brandNavy,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _dateStr,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 16),

          // Time Field
          Text(
            'Time:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: _brandNavy,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _timeStr,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // 3. Dual Bottom Action Buttons: [ ✕ Cancel ] and [ ✓ Confirm ]
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

          // Confirm Button (Solid Wine)
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
                onPressed: _isSubmitting ? null : _handleConfirm,
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
                  _isSubmitting ? 'CONFIRMING...' : 'Confirm',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
