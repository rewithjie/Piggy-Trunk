import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminMobilePendingInvestorsScreen extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const AdminMobilePendingInvestorsScreen({
    super.key,
    this.onBackToDashboard,
  });

  @override
  State<AdminMobilePendingInvestorsScreen> createState() =>
      _AdminMobilePendingInvestorsScreenState();
}

class _AdminMobilePendingInvestorsScreenState
    extends State<AdminMobilePendingInvestorsScreen> {
  // Brand Color Tokens (Aligned with Piggy Trunk Design System)
  static const Color _brandNavy = Color(0xFF18314F);
  static const Color _cardBorder = Color(0xFFE2E8F0);
  static const Color _textMuted = Color(0xFF6F8096);
  static const Color _criticalRed = Color(0xFFDC2626);
  static const Color _emeraldGreen = Color(0xFF10B981);
  static const Color _actionBlue = Color(0xFF3B82F6);

  final int _selectedTabIndex = 2; // Investment Tab
  bool _isLoading = false;

  List<Map<String, dynamic>> _pendingInvestors = [];

  @override
  void initState() {
    super.initState();
    _fetchLivePendingInvestors();
  }

  Future<void> _fetchLivePendingInvestors() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final res = await Supabase.instance.client
          .from('partner_investors')
          .select('partner_investor_id, address, contact_number, registration_date, app_users(name, email, status)')
          .order('registration_date', ascending: false)
          .limit(20);

      if (res.isNotEmpty && mounted) {
        List<Map<String, dynamic>> parsed = [];

        for (var i in res) {
          final user = i['app_users'] as Map<String, dynamic>? ?? {};
          final String status = (user['status'] as String?) ?? 'pending';

          // Only show pending applications
          if (status.toLowerCase() == 'pending') {
            final String name = (user['name'] as String?) ?? (user['email'] as String?) ?? 'Pending Partner Investor';
            final String address = (i['address'] as String?) ?? 'Location not specified';
            final String contact = (i['contact_number'] as String?) ?? 'No contact number';
            final String regDate = (i['registration_date'] as String?) ?? DateTime.now().toLocal().toString().split(' ')[0];

            parsed.add({
              'id': i['partner_investor_id']?.toString() ?? '',
              'name': name,
              'location': address,
              'contact': contact,
              'appliedDate': regDate,
            });
          }
        }

        setState(() => _pendingInvestors = parsed);
      } else if (mounted) {
        setState(() => _pendingInvestors = []);
      }
    } catch (e) {
      debugPrint('Error fetching pending investors: $e');
      if (mounted) setState(() => _pendingInvestors = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAccept(Map<String, dynamic> investor) async {
    final String invId = investor['id'] as String;
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (invId.isNotEmpty) {
        await Supabase.instance.client
            .from('partner_investors')
            .update({'status': 'active'}).eq('partner_investor_id', invId);
      }
    } catch (e) {
      debugPrint('Investor accept fallback: $e');
    }

    if (mounted) {
      setState(() {
        _pendingInvestors.removeWhere((item) => item['id'] == invId);
      });

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Application accepted for ${investor['name']}! Account is now active.',
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
    }
  }

  Future<void> _handleDecline(Map<String, dynamic> investor) async {
    final String invId = investor['id'] as String;
    final messenger = ScaffoldMessenger.of(context);

    if (mounted) {
      setState(() {
        _pendingInvestors.removeWhere((item) => item['id'] == invId);
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text('Application declined for ${investor['name']}.'),
          backgroundColor: _criticalRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          color: _brandNavy,
          onRefresh: _fetchLivePendingInvestors,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoading) ...[
                  const LinearProgressIndicator(
                    minHeight: 2.5,
                    color: _brandNavy,
                    backgroundColor: Colors.transparent,
                  ),
                  const SizedBox(height: 12),
                ],

                // Pending Investor Cards List or Clean Empty State
                _buildInvestorCardsList(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // 1. Top App Bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: _brandNavy, size: 24),
        onPressed: widget.onBackToDashboard ?? () => Navigator.pop(context),
      ),
      title: Text(
        'Pending Partner Investor',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 21,
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
            if (val == 'refresh') _fetchLivePendingInvestors();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh_rounded, size: 18, color: _brandNavy),
                  SizedBox(width: 10),
                  Text('Refresh List'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // 2. Investor Cards List (or Clean Empty State)
  Widget _buildInvestorCardsList() {
    if (_pendingInvestors.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _brandNavy.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.how_to_reg_outlined,
                  size: 32, color: _emeraldGreen),
            ),
            const SizedBox(height: 14),
            Text(
              'No Pending Partner Investors',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: _brandNavy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'When new partners register to fund hog rearing cycles, their KYC applications will appear here for verification.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: _textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _pendingInvestors.length,
      separatorBuilder: (context, index) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final investor = _pendingInvestors[index];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFFDE8E8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE11D48).withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Profile Row (Avatar, Name, Location)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar Box
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _cardBorder),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: _brandNavy,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name & Location Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          investor['name'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18.5,
                            fontWeight: FontWeight.w900,
                            color: _brandNavy,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          investor['location'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Divider Line
              const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
              const SizedBox(height: 14),

              // Contact Number Row
              Text(
                'CONTACT NUMBER:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: _brandNavy,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                investor['contact'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),

              // Applied Date Row
              Text(
                'APPLIED ON',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: _brandNavy,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                investor['appliedDate'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 20),

              // Divider Line
              const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
              const SizedBox(height: 16),

              // Dual Action Buttons: [ ACCEPT ] and [ DECLINE ]
              Row(
                children: [
                  // ACCEPT Button (Action Blue)
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _actionBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _handleAccept(investor),
                        child: Text(
                          'ACCEPT',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // DECLINE Button (Outlined Coral)
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(
                              color: Color(0xFFFCA5A5), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _handleDecline(investor),
                        child: Text(
                          'DECLINE',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 3. Bottom Navigation Bar (5 Dedicated Tabs matching screenshot)
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
