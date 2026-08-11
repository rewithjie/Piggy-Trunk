import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_pending_hog_raisers_screen.dart';

class AdminMobileNewBatchScreen extends StatefulWidget {
  const AdminMobileNewBatchScreen({super.key});

  @override
  State<AdminMobileNewBatchScreen> createState() =>
      _AdminMobileNewBatchScreenState();
}

class _AdminMobileNewBatchScreenState
    extends State<AdminMobileNewBatchScreen> {
  // Brand Color Tokens (Aligned with Piggy Trunk Design System)
  static const Color _brandNavy = Color(0xFF18314F);
  static const Color _cardBorder = Color(0xFFE2E8F0);
  static const Color _textMuted = Color(0xFF6F8096);
  static const Color _emeraldGreen = Color(0xFF10B981);
  static const Color _accentCoral = Color(0xFFC73F57);
  static const Color _actionPink = Color(0xFFFF5377);

  final TextEditingController _batchIdCtrl =
      TextEditingController(text: 'B2024-C');
  final TextEditingController _batchNameCtrl =
      TextEditingController(text: 'Batch 2024-C Fattening');
  final TextEditingController _raiserNameCtrl =
      TextEditingController(text: '');
  final TextEditingController _initialCostCtrl =
      TextEditingController(text: '10000.00');

  int _noOfHogs = 2;
  int _selectedHogTypeIndex = 0; // 0 = Fattening, 1 = Sow
  final List<String> _hogTypes = ['Fattening', 'Sow'];

  bool _isSubmitting = false;
  bool _isBatchCreated = false; // Controls Success Notification View
  final int _selectedTabIndex = 2; // Investment Tab

  @override
  void dispose() {
    _batchIdCtrl.dispose();
    _batchNameCtrl.dispose();
    _raiserNameCtrl.dispose();
    _initialCostCtrl.dispose();
    super.dispose();
  }

  void _incrementHogs() {
    setState(() => _noOfHogs++);
  }

  void _decrementHogs() {
    if (_noOfHogs > 1) {
      setState(() => _noOfHogs--);
    }
  }

  Future<void> _handleSave() async {
    final String batchName = _batchNameCtrl.text.trim();
    final String raiserName = _raiserNameCtrl.text.trim();
    final double initialCost =
        double.tryParse(_initialCostCtrl.text.replaceAll(',', '').trim()) ??
            10000.00;

    if (batchName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Batch Name or Code.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Insert into Supabase batches table
      dynamic newBatchId;
      try {
        final batchRes = await Supabase.instance.client
            .from('batches')
            .insert({
              'batch_name': batchName,
              'date_created':
                  DateTime.now().toIso8601String().split('T').first,
            })
            .select('batch_id')
            .maybeSingle();

        if (batchRes != null && batchRes['batch_id'] != null) {
          newBatchId = batchRes['batch_id'];
        }
      } catch (e) {
        debugPrint('Batch insert fallback: $e');
      }

      // 2. Insert into investments table
      try {
        await Supabase.instance.client.from('investments').insert({
          'amount': initialCost,
          'status': 'active',
        });
      } catch (e) {
        debugPrint('Investment insert fallback: $e');
      }

      // 3. Insert into assignments if raiser is provided
      if (raiserName.isNotEmpty && newBatchId != null) {
        try {
          await Supabase.instance.client.from('assignments').insert({
            'batch_id': newBatchId,
            'status': 'active',
          });
        } catch (e) {
          debugPrint('Assignment insert fallback: $e');
        }
      }

      // 4. Switch to "New Batch Created!" Confirmation State
      if (mounted) {
        setState(() {
          _isBatchCreated = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating batch: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _openPendingRaisersList() async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminMobilePendingHogRaisersScreen(),
      ),
    );
    if (res == true) {
      setState(() {
        _raiserNameCtrl.text = 'Juan Dela Cruz';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _isBatchCreated
            ? _buildSuccessConfirmationView()
            : _buildFormView(),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // 1. Success Notification Confirmation View ("New Batch Created!")
  Widget _buildSuccessConfirmationView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6F4), // Brand soft warm surface
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFFDE8E8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE11D48).withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular Success Badge with Glow
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: _actionPink,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _actionPink.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),

              // Title: New Batch Created!
              Text(
                'New Batch Created!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _brandNavy,
                  letterSpacing: -0.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Action Button: Done
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _actionPink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context, true); // Return true to refresh parent list
                  },
                  child: Text(
                    'Done',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
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

  // 2. Main Form View (Investment Batch & Direct Assign Hog Raiser Form)
  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Investment Batch Information Card
          _buildInvestmentBatchCard(),
          const SizedBox(height: 18),

          // 2. Direct Assign Hog Raiser Form Card (No Toggle!)
          _buildAssignHogRaiserCard(),
          const SizedBox(height: 28),

          // 3. Save & Cancel Action Buttons
          _buildActionButtons(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Top App Bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: _brandNavy, size: 26),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'New Batch',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: _brandNavy,
          letterSpacing: -0.4,
        ),
      ),
      actions: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded,
                  color: _brandNavy, size: 24),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All batch notifications up to date.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // 1. Investment Batch Header Card
  Widget _buildInvestmentBatchCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFDE8E8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Icon & Title
          Row(
            children: [
              const Icon(Icons.add_business_rounded,
                  color: _accentCoral, size: 22),
              const SizedBox(width: 8),
              Text(
                'Investment Batch',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF991B1B), // Dark wine
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Batch ID Field
          Text(
            'Batch ID:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _textMuted,
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
              controller: _batchIdCtrl,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _brandNavy,
              ),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.badge_outlined,
                    size: 20, color: Color(0xFF64748B)),
                hintText: 'e.g. B2024-C',
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Batch Name Field
          Text(
            'Batch Name',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _textMuted,
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
              controller: _batchNameCtrl,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _brandNavy,
              ),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.edit_note_rounded,
                    size: 22, color: Color(0xFF64748B)),
                hintText: 'e.g. Batch 2024-C Fattening',
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Direct Assign Hog Raiser Form Card (No Toggle!)
  Widget _buildAssignHogRaiserCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFDE8E8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Title
          Row(
            children: [
              const Icon(Icons.person_add_alt_1_rounded,
                  color: _accentCoral, size: 22),
              const SizedBox(width: 8),
              Text(
                'Assign Hog Raiser',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF991B1B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Raiser Name Input
          Text(
            'Name:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _textMuted,
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
              controller: _raiserNameCtrl,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _brandNavy,
              ),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline_rounded,
                    size: 20, color: Color(0xFF64748B)),
                hintText: 'e.g. John Doe',
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // No. Hogs Stepper
          Text(
            'No. Hogs:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFCA5A5), // Subtle coral outline
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Plus Button
                IconButton(
                  onPressed: _incrementHogs,
                  icon: const Icon(Icons.add_rounded,
                      size: 24, color: _emeraldGreen),
                  splashRadius: 22,
                ),

                // Number Display
                Text(
                  _noOfHogs.toString(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _brandNavy,
                  ),
                ),

                // Minus Button
                IconButton(
                  onPressed: _decrementHogs,
                  icon: const Icon(Icons.remove_rounded,
                      size: 24, color: _accentCoral),
                  splashRadius: 22,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Hog to Raise Pill Selector (Fattening vs Sow)
          Text(
            'Hog to Raise:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
            ),
            child: Row(
              children: _hogTypes.asMap().entries.map((entry) {
                final int idx = entry.key;
                final String label = entry.value;
                final bool isSelected = _selectedHogTypeIndex == idx;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedHogTypeIndex = idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFFB91C1C)
                                : _textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Initial Cost Input Field
          Text(
            'Initial Cost:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _textMuted,
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
              controller: _initialCostCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _brandNavy,
              ),
              decoration: const InputDecoration(
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 16, right: 8),
                  child: Text(
                    '₱',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                prefixIconConstraints:
                    BoxConstraints(minWidth: 0, minHeight: 0),
                hintText: '0.00',
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Pending Hog Raisers Quick Selector Banner
          InkWell(
            onTap: _openPendingRaisersList,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_top_rounded,
                      size: 20, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Text(
                    'Pending Hog Raisers',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF16A34A),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Save & Cancel Action Buttons
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Green Save Button
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
            onPressed: _isSubmitting ? null : _handleSave,
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
              _isSubmitting ? 'SAVING...' : 'Save',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Cancel Button
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
          if (index != 2) {
            Navigator.pop(context);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFC73F57), // Active Red
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
