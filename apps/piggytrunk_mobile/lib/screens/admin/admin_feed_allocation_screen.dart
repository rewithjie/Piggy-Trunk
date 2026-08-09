import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_transaction_distribution_screen.dart';

class AdminMobileFeedAllocationScreen extends StatefulWidget {
  final Map<String, dynamic>? request;

  const AdminMobileFeedAllocationScreen({
    super.key,
    this.request,
  });

  @override
  State<AdminMobileFeedAllocationScreen> createState() =>
      _AdminMobileFeedAllocationScreenState();
}

class _AdminMobileFeedAllocationScreenState
    extends State<AdminMobileFeedAllocationScreen> {
  // Piggy Trunk Brand Color Tokens
  static const Color _brandNavy = Color(0xFF18314F);
  static const Color _cardBorder = Color(0xFFE2E8F0);
  static const Color _textMuted = Color(0xFF6F8096);
  static const Color _emeraldGreen = Color(0xFF10B981);
  static const Color _coralRed = Color(0xFFE11D48);

  late String _requestId;
  late String _raiserName;
  late List<Map<String, dynamic>> _requestedItems;
  late String _timeAgo;

  int _currentAvailableStock = 420;
  int _amountOfSacks = 15;
  int _kiloRequested = 1;
  bool _isSubmitting = false;

  final int _selectedTabIndex = 2; // Investment / Allocation

  @override
  void initState() {
    super.initState();
    final req = widget.request ?? {};
    _requestId = (req['id'] ?? '').toString();
    _raiserName = (req['raiserName'] as String?) ?? 'John Dela Cruz';
    _timeAgo = (req['time'] as String?) ?? 'Requested 2h ago';

    final items = req['items'] as List<dynamic>?;
    if (items != null && items.isNotEmpty) {
      _requestedItems = items.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      _requestedItems = [
        {'type': 'Booster', 'sacks': 3},
        {'type': 'Milk-Maker', 'sacks': 1},
      ];
    }

    _fetchWarehouseStock();
  }

  Future<void> _fetchWarehouseStock() async {
    try {
      final res = await Supabase.instance.client
          .from('inventory_products')
          .select('units')
          .eq('is_archived', false);

      if (res.isNotEmpty && mounted) {
        int totalUnits = 0;
        for (var p in res) {
          totalUnits += (p['units'] as num?)?.toInt() ?? 0;
        }
        if (totalUnits > 0) {
          setState(() => _currentAvailableStock = totalUnits);
        }
      }
    } catch (_) {}
  }

  void _incrementSacks() {
    setState(() => _amountOfSacks++);
  }

  void _decrementSacks() {
    if (_amountOfSacks > 0) {
      setState(() => _amountOfSacks--);
    }
  }

  Future<void> _handleConfirmAllocation() async {
    final String prodName = _requestedItems.isNotEmpty
        ? (_requestedItems.first['type'] as String)
        : 'IMMUNOBOOSTER';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminMobileTransactionDistributionScreen(
          transactionData: {
            'requestId': _requestId,
            'productName': prodName.toUpperCase(),
            'category': 'Pigrolac Early Wean',
            'sackQuantity': _amountOfSacks > 0 ? _amountOfSacks : 2,
            'totalPrice': (_amountOfSacks > 0 ? _amountOfSacks : 2) * 5000.00,
            'raiserName': _raiserName,
          },
        ),
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
              // 1. Raiser Request Summary Card
              _buildRaiserRequestCard(),
              const SizedBox(height: 18),

              // 2. Current Stock Availability Card
              _buildStockAvailabilityCard(),
              const SizedBox(height: 18),

              // 3. Allocation Input Form Card (Sacks Stepper & Kilo Input)
              _buildAllocationInputsCard(),
              const SizedBox(height: 28),

              // 4. Action Buttons (Confirm Allocation & Cancel)
              _buildActionButtons(),
              const SizedBox(height: 24),
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
        'Feed Allocation',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: _brandNavy,
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  // 1. Raiser Request Summary Card
  Widget _buildRaiserRequestCard() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Raiser Request',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _raiserName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _brandNavy,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 14),

                // Requested Items
                ..._requestedItems.map((item) {
                  final String feed = item['type'] as String;
                  final int sacks = item['sacks'] as int;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          feed,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: _emeraldGreen, // High-impact brand green
                            letterSpacing: -0.4,
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$sacks ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: _brandNavy,
                                ),
                              ),
                              TextSpan(
                                text: 'Sacks',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // Footer Strip: Requested time
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 16, color: _coralRed),
                const SizedBox(width: 8),
                Text(
                  _timeAgo,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Current Stock Availability Card
  Widget _buildStockAvailabilityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CURRENT STOCK AVAILABILITY',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF475569),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '$_currentAvailableStock Sacks',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF047857), // Deep emerald
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Green Stock Level Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (_currentAvailableStock / 600).clamp(0.1, 1.0),
              minHeight: 9,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF047857),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Allocation Input Form Card (Sacks Stepper & Kilo Input)
  Widget _buildAllocationInputsCard() {
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
          Text(
            'Can proceed without filling out the two',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // Column 1: Amount of Sack Stepper
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount of Sack',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFCA5A5), // Subtle coral outline
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Minus Button
                          InkWell(
                            onTap: _decrementSacks,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: const Color(0xFFCBD5E1)),
                              ),
                              child: const Icon(Icons.remove_rounded,
                                  size: 18, color: _coralRed),
                            ),
                          ),

                          // Sacks Count
                          Text(
                            _amountOfSacks.toString(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: _brandNavy,
                            ),
                          ),

                          // Plus Button (Solid Coral/Rose)
                          InkWell(
                            onTap: _incrementSacks,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _coralRed,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add_rounded,
                                  size: 18, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Column 2: Kilo Requested Input Box
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kilo requested',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF), // Soft lavender/blue
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.scale_rounded,
                              size: 20, color: Color(0xFF4338CA)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              initialValue: _kiloRequested.toString(),
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: _brandNavy,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (val) {
                                _kiloRequested = int.tryParse(val) ?? 0;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Action Buttons (Confirm Allocation & Cancel)
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Confirm Allocation Button (Green)
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
            onPressed: _isSubmitting ? null : _handleConfirmAllocation,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.5,
                    ),
                  )
                : const Icon(Icons.check_circle_outline_rounded, size: 22),
            label: Text(
              _isSubmitting ? 'CONFIRMING...' : 'Confirm Allocation',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Cancel Button (Outlined White/Coral)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
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
        selectedItemColor: const Color(0xFFC73F57), // Active tab
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
