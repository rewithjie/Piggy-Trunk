import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_feed_allocation_screen.dart';

class AdminMobileRequestsScreen extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const AdminMobileRequestsScreen({
    super.key,
    this.onBackToDashboard,
  });

  @override
  State<AdminMobileRequestsScreen> createState() =>
      _AdminMobileRequestsScreenState();
}

class _AdminMobileRequestsScreenState extends State<AdminMobileRequestsScreen> {
  // Brand color tokens
  static const Color _brandNavy = Color(0xFF18314F);
  static const Color _primarySlate = Color(0xFF243B53);
  static const Color _cardBorder = Color(0xFFE2E8F0);
  static const Color _textMuted = Color(0xFF6F8096);
  static const Color _criticalRed = Color(0xFFDC2626);
  static const Color _emeraldGreen = Color(0xFF10B981);
  static const Color _accentRose = Color(0xFFF87171);
  static const Color _actionBlue = Color(0xFF3B82F6);

  int _selectedSubTab = 0; // 0 = ALL REQUESTS, 1 = HISTORY
  final int _selectedTabIndex = 0;
  bool _isLoading = false;

  List<Map<String, dynamic>> _requestsList = [];

  @override
  void initState() {
    super.initState();
    _fetchLiveRequests();
  }

  Future<void> _fetchLiveRequests() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final res = await Supabase.instance.client
          .from('stock_requests')
          .select('request_id, request_date, status, quantity, feed_type, hog_raisers(first_name, last_name)')
          .eq('status', _selectedSubTab == 0 ? 'pending' : 'approved')
          .order('request_date', ascending: false)
          .limit(20);

      if (res.isNotEmpty && mounted) {
        List<Map<String, dynamic>> parsed = [];
        for (var r in res) {
          final raiser = r['hog_raisers'] as Map<String, dynamic>? ?? {};
          final fname = (raiser['first_name'] as String?) ?? '';
          final lname = (raiser['last_name'] as String?) ?? '';
          final fullName = '$fname $lname'.trim().isNotEmpty
              ? '$fname $lname'.trim()
              : 'Hog Raiser';

          final int qty = (r['quantity'] as num?)?.toInt() ?? 1;
          final String feed = (r['feed_type'] as String?) ?? 'Starter';

          parsed.add({
            'id': r['request_id']?.toString() ?? '',
            'raiserName': fullName,
            'items': [
              {'type': feed, 'sacks': qty},
            ],
            'status': r['status'] ?? 'pending',
          });
        }

        setState(() => _requestsList = parsed);
      } else if (mounted) {
        setState(() => _requestsList = []);
      }
    } catch (e) {
      debugPrint('Error fetching requests: $e');
      if (mounted) setState(() => _requestsList = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Requests',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _brandNavy,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: _textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.all_inbox_rounded, color: _primarySlate),
              title: const Text('All Feed Types'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.fastfood_rounded, color: _primarySlate),
              title: const Text('Booster Feeds Only'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_rounded, color: _primarySlate),
              title: const Text('Starter / Finisher Feeds'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAllocateDialog(Map<String, dynamic> req) async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AdminMobileFeedAllocationScreen(request: req),
      ),
    );
    if (res == true) {
      _fetchLiveRequests();
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
          onRefresh: _fetchLiveRequests,
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

                // Sub-Tabs Header (ALL REQUESTS / HISTORY & FILTER)
                _buildSubTabsHeader(),
                const SizedBox(height: 20),

                // Request Feed Cards List
                _buildRequestsList(),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // 1. Top App Bar with Menu, Title, Search, and Notification Bell
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: _brandNavy, size: 26),
        onPressed: widget.onBackToDashboard ?? () => Navigator.maybePop(context),
      ),
      title: Text(
        'Requests',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: _brandNavy,
          letterSpacing: -0.4,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: _brandNavy, size: 22),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Search filter active.'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded,
                  color: _brandNavy, size: 24),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All raiser feed requests are up to date.'),
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
                  color: _criticalRed,
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

  // 2. Sub-Tabs Header (ALL REQUESTS / HISTORY & FILTER)
  Widget _buildSubTabsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // ALL REQUESTS Tab
            GestureDetector(
              onTap: () {
                setState(() => _selectedSubTab = 0);
                _fetchLiveRequests();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ALL REQUESTS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _selectedSubTab == 0 ? _accentRose : _textMuted,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 96,
                    height: 2.5,
                    color: _selectedSubTab == 0 ? const Color(0xFF22C55E) : Colors.transparent,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),

            // HISTORY Tab
            GestureDetector(
              onTap: () {
                setState(() => _selectedSubTab = 1);
                _fetchLiveRequests();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HISTORY',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _selectedSubTab == 1 ? _accentRose : _textMuted,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 60,
                    height: 2.5,
                    color: _selectedSubTab == 1 ? const Color(0xFF22C55E) : Colors.transparent,
                  ),
                ],
              ),
            ),
          ],
        ),

        // FILTER Button
        InkWell(
          onTap: _showFilterModal,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.filter_list_rounded, size: 18, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  'FILTER',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 3. Requests Cards List
  Widget _buildRequestsList() {
    if (_requestsList.isEmpty) {
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
              child: const Icon(Icons.assignment_turned_in_outlined,
                  size: 32, color: _emeraldGreen),
            ),
            const SizedBox(height: 14),
            Text(
              'No Pending Feed Requests',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _brandNavy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'When hog raisers submit new feed requests from their mobile app, they will automatically appear here for allocation.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
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
      itemCount: _requestsList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final req = _requestsList[index];
        final List items = req['items'] as List? ?? [];

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
              // Raiser Name Header
              Text(
                req['raiserName'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  color: _brandNavy,
                ),
              ),
              const SizedBox(height: 14),

              // Requested Feed Sacks List
              ...items.map<Widget>((item) {
                final String feedName = item['type'] as String;
                final int sacks = item['sacks'] as int;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        feedName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFF87171), // Soft coral/rose text
                          letterSpacing: -0.3,
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$sacks ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
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
              const SizedBox(height: 12),

              // Blue ALLOCATE FEEDS Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _actionBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _openAllocateDialog(req),
                  child: Text(
                    'ALLOCATE FEEDS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 4. Bottom Navigation Bar (5 Dedicated Tabs matching screenshot)
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
          if (index != 0) {
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
