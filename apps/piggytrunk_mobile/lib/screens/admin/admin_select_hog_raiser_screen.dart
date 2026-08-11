import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_feed_allocation_screen.dart';

class AdminMobileSelectHogRaiserScreen extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const AdminMobileSelectHogRaiserScreen({
    super.key,
    this.onBackToDashboard,
  });

  @override
  State<AdminMobileSelectHogRaiserScreen> createState() =>
      _AdminMobileSelectHogRaiserScreenState();
}

class _AdminMobileSelectHogRaiserScreenState
    extends State<AdminMobileSelectHogRaiserScreen> {
  // Brand color tokens (Aligned with Piggy Trunk Design System)
  static const Color _brandNavy = Color(0xFF18314F);
  static const Color _cardBorder = Color(0xFFE2E8F0);
  static const Color _textMuted = Color(0xFF6F8096);
  static const Color _wineRed = Color(0xFF8B1D35); // Solid wine button color

  final int _selectedTabIndex = 3; // POS Tab (Active)
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  List<Map<String, dynamic>> _raisersList = [];

  @override
  void initState() {
    super.initState();
    _fetchLiveHogRaisers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveHogRaisers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final res = await Supabase.instance.client
          .from('hog_raisers')
          .select('hog_raiser_id, name, address, phone, account_status, app_users(name, email)')
          .order('name', ascending: true);

      if (res.isNotEmpty && mounted) {
        List<Map<String, dynamic>> parsed = [];
        for (var r in res) {
          final user = r['app_users'] as Map<String, dynamic>? ?? {};
          final String rName = (r['name'] as String?) ?? (user['name'] as String?) ?? (user['email'] as String?) ?? 'Registered Raiser';
          final String rAddress = (r['address'] as String?) ?? 'Bulacan, Region III';

          parsed.add({
            'id': r['hog_raiser_id']?.toString() ?? '',
            'name': rName,
            'address': rAddress,
          });
        }
        setState(() => _raisersList = parsed);
      } else if (mounted) {
        setState(() => _raisersList = []);
      }
    } catch (e) {
      debugPrint('Error fetching hog raisers: $e');
      if (mounted) setState(() => _raisersList = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectRaiser(Map<String, dynamic> raiser) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminMobileFeedAllocationScreen(
          request: {
            'id': raiser['id'],
            'raiserName': raiser['name'],
            'requestedItems': 'Booster 3 Sacks, Milk-Maker 1 Sacks',
            'timeAgo': 'Just now',
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRaisers = _raisersList.where((r) {
      final String name = (r['name'] as String).toLowerCase();
      final String id = (r['id'] as String).toLowerCase();
      final String q = _searchQuery.toLowerCase();
      return name.contains(q) || id.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          color: _brandNavy,
          onRefresh: _fetchLiveHogRaisers,
          child: Column(
            children: [
              if (_isLoading) ...[
                const LinearProgressIndicator(
                  minHeight: 2.5,
                  color: _brandNavy,
                  backgroundColor: Colors.transparent,
                ),
              ],

              // 1. Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _buildSearchBar(),
              ),

              // 2. Raiser Cards List (or Clean Empty State)
              Expanded(
                child: filteredRaisers.isEmpty
                    ? _buildCleanEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        itemCount: filteredRaisers.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return _buildRaiserCard(filteredRaisers[index]);
                        },
                      ),
              ),
            ],
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
        'Select Hog Raiser',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF991B1B), // Dark wine / deep navy accent
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  // 2. Search Bar
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE8E8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: _brandNavy,
        ),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded, color: _textMuted, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: _textMuted),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          hintText: 'Search by name or ID...',
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // 3. Raiser Card
  Widget _buildRaiserCard(Map<String, dynamic> raiser) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFDE8E8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar Circle with Farmer / Agriculture Icon
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
              border: Border.all(color: _cardBorder, width: 1.2),
            ),
            child: const Icon(
              Icons.agriculture_rounded,
              color: _brandNavy,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Raiser Name
          Expanded(
            child: Text(
              raiser['name'] as String,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17.5,
                fontWeight: FontWeight.w800,
                color: _brandNavy,
                letterSpacing: -0.2,
              ),
            ),
          ),

          // Select Button (Solid Wine)
          SizedBox(
            height: 38,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _wineRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              onPressed: () => _selectRaiser(raiser),
              child: Text(
                'Select',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Clean Empty State Placeholder
  Widget _buildCleanEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _brandNavy.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline_rounded, size: 32, color: _wineRed),
            ),
            const SizedBox(height: 14),
            Text(
              'No Registered Hog Raisers',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: _brandNavy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Active hog raisers will appear here for feed distribution and allocation.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: _textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 5. Bottom Navigation Bar (5 Dedicated Tabs matching screenshot)
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
          if (index != 3) {
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
