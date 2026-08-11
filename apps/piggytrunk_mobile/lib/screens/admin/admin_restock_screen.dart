import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminMobileRestockScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const AdminMobileRestockScreen({
    super.key,
    this.product,
  });

  @override
  State<AdminMobileRestockScreen> createState() =>
      _AdminMobileRestockScreenState();
}

class _AdminMobileRestockScreenState extends State<AdminMobileRestockScreen> {
  // Brand Color Tokens (Aligned with Piggy Trunk Design System)
  static const Color _brandNavy = Color(0xFF18314F);
  static const Color _primarySlate = Color(0xFF243B53);
  static const Color _cardBorder = Color(0xFFE2E8F0);
  static const Color _textMuted = Color(0xFF6F8096);
  static const Color _emeraldGreen = Color(0xFF10B981);
  static const Color _actionBlue = Color(0xFF3B82F6);

  late TextEditingController _priceCtrl;
  int _quantity = 2;
  bool _isSubmitting = false;

  late String _productId;
  late String _productName;
  late String _productBrand;
  late double _currentPrice;
  late int _currentUnits;

  final int _selectedTabIndex = 1; // Default to Inventory tab

  @override
  void initState() {
    super.initState();
    final p = widget.product ?? {};
    _productId = (p['id'] ?? '').toString();
    _productName = (p['name'] as String?) ?? 'IMMUNOBOOSTER';
    _productBrand = (p['brand'] as String?) ?? 'Pigrolac Early Wean';
    _currentPrice = (p['price'] as num?)?.toDouble() ?? 1850.00;
    _currentUnits = (p['units'] as num?)?.toInt() ?? 60;

    _priceCtrl = TextEditingController(
      text: _currentPrice > 0 ? _currentPrice.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  void _incrementQty() {
    setState(() => _quantity++);
  }

  void _decrementQty() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  Future<void> _handleRestockSubmit() async {
    if (_quantity <= 0) return;
    setState(() => _isSubmitting = true);

    try {
      final double newPrice =
          double.tryParse(_priceCtrl.text.replaceAll(',', '').trim()) ??
              _currentPrice;
      final int newTotalUnits = _currentUnits + _quantity;
      final user = Supabase.instance.client.auth.currentUser;
      final String adminIdentifier = user?.email ?? 'admin@piggytrunk.com';

      // 1. Update live product in Supabase if productId exists
      if (_productId.isNotEmpty) {
        try {
          await Supabase.instance.client.from('inventory_products').update({
            'units': newTotalUnits,
            'price': newPrice,
          }).eq('id', _productId);
        } catch (_) {
          try {
            await Supabase.instance.client.from('products').update({
              'units': newTotalUnits,
              'price': newPrice,
            }).eq('id', _productId);
          } catch (e) {
            debugPrint('Product table update fallback: $e');
          }
        }

        // 2. Log entry in inventory_logs
        try {
          await Supabase.instance.client.from('inventory_logs').insert({
            'product_name': _productName,
            'action': 'RESTOCK',
            'performed_by': adminIdentifier,
            'price': newPrice,
            'units': _quantity,
            'details': 'Restocked +$_quantity bags via Mobile Admin',
          });
        } catch (e) {
          debugPrint('Inventory logs insert fallback: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Successfully restocked +$_quantity bags for $_productName!',
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
        Navigator.pop(context, true); // Return true to trigger refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating stock: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showEditProductDialog() {
    final TextEditingController nameCtrl =
        TextEditingController(text: _productName);
    final TextEditingController brandCtrl =
        TextEditingController(text: _productBrand);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Product Details',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: _brandNavy,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Product Name',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _cardBorder),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: brandCtrl,
              decoration: InputDecoration(
                labelText: 'Brand / Subtitle',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _cardBorder),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: _textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primarySlate,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              setState(() {
                _productName = nameCtrl.text.trim();
                _productBrand = brandCtrl.text.trim();
              });
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Product Summary Card
              _buildProductSummaryCard(),
              const SizedBox(height: 20),

              // 2. Restock Form Card (Price, Quantity Stepper, Stock Button)
              _buildRestockFormCard(),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Top App Bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: _brandNavy, size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Restock',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: _brandNavy,
          letterSpacing: -0.4,
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded,
              color: _brandNavy, size: 22),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onSelected: (val) {
            if (val == 'edit') _showEditProductDialog();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18, color: _brandNavy),
                  SizedBox(width: 10),
                  Text('Edit Product'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // 1. Top Product Summary Card
  Widget _buildProductSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFDE8E8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Feed Sack Thumbnail Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _cardBorder),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: _brandNavy,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),

              // Brand Subtitle & Product Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _productBrand,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _productName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _brandNavy,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Divider Line
          const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
          const SizedBox(height: 14),

          // Unit Price & Edit Button Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unit Price/Sack',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₱${_currentPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFE11D48),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _actionBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: _showEditProductDialog,
                icon: const Icon(Icons.edit, size: 15),
                label: Text(
                  'EDIT',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Restock Form Card (New Price, Sack Quantity Stepper, Stock Button)
  Widget _buildRestockFormCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // New Price Label
          Text(
            'NEW PRICE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF475569),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),

          // New Price Input Box
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: TextField(
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _brandNavy,
              ),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Text(
                    '₱',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
                hintText: '0.00',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF94A3B8),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Sack Quantity Label
          Text(
            'SACK QUANTITY',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF475569),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),

          // Sack Quantity Stepper Box (Minus - Number - Plus)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Minus Button
                IconButton(
                  onPressed: _decrementQty,
                  icon: const Icon(Icons.remove_rounded,
                      size: 26, color: Color(0xFFE11D48)),
                  splashRadius: 24,
                ),

                // Quantity Display
                Text(
                  _quantity.toString(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _brandNavy,
                  ),
                ),

                // Plus Button
                IconButton(
                  onPressed: _incrementQty,
                  icon: const Icon(Icons.add_rounded,
                      size: 26, color: _emeraldGreen),
                  splashRadius: 24,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Green STOCK Confirm Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _isSubmitting ? null : _handleRestockSubmit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 22),
              label: Text(
                _isSubmitting ? 'SAVING...' : 'STOCK',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bottom Navigation Bar
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
          if (index == 0 || index == 1) {
            Navigator.pop(context);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFC73F57),
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
