import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/models/pos_model.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CashierCheckoutModal extends StatefulWidget {
  final Order currentOrder;
  final String cashierName;
  final Future<void> Function({
    required String customerName,
    required String customerType,
    required String paymentMethod,
    required double tenderedAmount,
    required double changeAmount,
    required Order order,
  }) onConfirmCheckout;

  const CashierCheckoutModal({
    super.key,
    required this.currentOrder,
    required this.cashierName,
    required this.onConfirmCheckout,
  });

  @override
  State<CashierCheckoutModal> createState() => _CashierCheckoutModalState();
}

class _CashierCheckoutModalState extends State<CashierCheckoutModal> {
  static const Color _brandNavy = Color(0xFF18314F);

  String _customerType = 'Walk-in'; // 'Walk-in' or 'Hog Raiser'
  String _selectedPaymentMethod = 'Cash'; // 'Cash' or 'GCash'
  final TextEditingController _walkInNameCtrl = TextEditingController(text: 'Walk-in Customer');

  List<Map<String, dynamic>> _hogRaisers = [];
  Map<String, dynamic>? _selectedHogRaiser;
  bool _isLoadingRaisers = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchHogRaisers();
  }

  @override
  void dispose() {
    _walkInNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchHogRaisers() async {
    setState(() => _isLoadingRaisers = true);
    try {
      final res = await Supabase.instance.client
          .from('hog_raisers')
          .select('hog_raiser_id, name, email, avatar_url')
          .order('name', ascending: true);
      if (mounted) {
        setState(() {
          _hogRaisers = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (e) {
      debugPrint('Error fetching hog raisers for checkout: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRaisers = false);
    }
  }

  Future<void> _handleConfirm() async {
    final String finalCustomerName = _customerType == 'Walk-in'
        ? (_walkInNameCtrl.text.trim().isNotEmpty ? _walkInNameCtrl.text.trim() : 'Walk-in Customer')
        : (_selectedHogRaiser?['name'] ?? 'Unassigned Raiser');

    setState(() => _isSubmitting = true);
    try {
      await widget.onConfirmCheckout(
        customerName: finalCustomerName,
        customerType: _customerType,
        paymentMethod: _selectedPaymentMethod,
        tenderedAmount: widget.currentOrder.total,
        changeAmount: 0.0,
        order: widget.currentOrder,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout failed: $e'),
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
    final total = widget.currentOrder.total;

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
            // Top Drag Handle & Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 20, 12),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payment & Checkout',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _brandNavy,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: PiggyTrunkTheme.ptMuted),
                        splashRadius: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Body Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Due Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_brandNavy, Color(0xFF2A4A70)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: _brandNavy.withValues(alpha: 0.22),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL AMOUNT DUE',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₱${total.toStringAsFixed(2)}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${widget.currentOrder.totalItems} Items',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Customer Type Selector
                    Text(
                      'Customer Type',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _brandNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _customerType = 'Walk-in'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _customerType == 'Walk-in' ? _brandNavy : const Color(0xFFF5F8FE),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _customerType == 'Walk-in' ? _brandNavy : const Color(0xFFD7E3F3)),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_outline_rounded,
                                      size: 18, color: _customerType == 'Walk-in' ? Colors.white : _brandNavy),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Walk-in Customer',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _customerType == 'Walk-in' ? Colors.white : _brandNavy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _customerType = 'Hog Raiser'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _customerType == 'Hog Raiser' ? _brandNavy : const Color(0xFFF5F8FE),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _customerType == 'Hog Raiser' ? _brandNavy : const Color(0xFFD7E3F3)),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.pets_rounded,
                                      size: 18, color: _customerType == 'Hog Raiser' ? Colors.white : _brandNavy),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Hog Raiser',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _customerType == 'Hog Raiser' ? Colors.white : _brandNavy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Customer Name Input or Hog Raiser Dropdown
                    if (_customerType == 'Walk-in') ...[
                      TextField(
                        controller: _walkInNameCtrl,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _brandNavy),
                        decoration: InputDecoration(
                          hintText: 'Customer Name / Note',
                          filled: true,
                          fillColor: const Color(0xFFF5F8FE),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFD7E3F3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFD7E3F3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _brandNavy, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ] else ...[
                      _isLoadingRaisers
                          ? const Center(child: CircularProgressIndicator(color: _brandNavy))
                          : DropdownButtonFormField<Map<String, dynamic>?>(
                              initialValue: _selectedHogRaiser,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _brandNavy),
                              hint: Text(
                                'Unassigned (Select Hog Raiser)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  color: PiggyTrunkTheme.ptMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF5F8FE),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFD7E3F3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFD7E3F3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _brandNavy, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              items: [
                                DropdownMenuItem<Map<String, dynamic>?>(
                                  value: null,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person_outline_rounded, size: 16, color: PiggyTrunkTheme.ptMuted),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Unassigned (General Raiser)',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: PiggyTrunkTheme.ptMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ..._hogRaisers.map((r) {
                                  return DropdownMenuItem<Map<String, dynamic>?>(
                                    value: r,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.pets_rounded, size: 15, color: _brandNavy),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            r['name'] ?? 'Hog Raiser #${r['hog_raiser_id']}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: _brandNavy,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (val) {
                                setState(() => _selectedHogRaiser = val);
                              },
                            ),
                    ],
                    const SizedBox(height: 22),

                    // Payment Method (Only Cash & GCash)
                    Text(
                      'Payment Method',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _brandNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Cash', 'GCash'].map((method) {
                        final isSelected = _selectedPaymentMethod == method;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () => setState(() => _selectedPaymentMethod = method),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? _brandNavy : const Color(0xFFF5F8FE),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isSelected ? _brandNavy : const Color(0xFFD7E3F3)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  method,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isSelected ? Colors.white : _brandNavy,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Buttons
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Complete Transaction',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
