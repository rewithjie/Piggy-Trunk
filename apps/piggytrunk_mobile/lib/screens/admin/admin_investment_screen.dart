import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_pending_hog_raisers_screen.dart';
import 'admin_new_batch_screen.dart';

class AdminMobileInvestmentScreen extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const AdminMobileInvestmentScreen({
    super.key,
    this.onBackToDashboard,
  });

  @override
  State<AdminMobileInvestmentScreen> createState() =>
      _AdminMobileInvestmentScreenState();
}

class _AdminMobileInvestmentScreenState
    extends State<AdminMobileInvestmentScreen> {
  // Brand Color Tokens (Aligned with Piggy Trunk Design System)
  static const Color _brandNavy = Color(0xFF18314F);
  static const Color _primarySlate = Color(0xFF243B53);
  static const Color _cardBorder = Color(0xFFE2E8F0);
  static const Color _textMuted = Color(0xFF6F8096);
  static const Color _criticalRed = Color(0xFFDC2626);
  static const Color _actionBlue = Color(0xFF3B82F6);
  static const Color _accentCoral = Color(0xFFC73F57);

  final int _selectedTabIndex = 2; // Investment Tab (Active)
  bool _isLoading = false;

  List<Map<String, dynamic>> _activeBatches = [];
  List<Map<String, dynamic>> _activeAssignments = [];

  @override
  void initState() {
    super.initState();
    _fetchLiveInvestmentData();
  }

  Future<void> _fetchLiveInvestmentData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. Fetch Batches & Invested amounts
      final batchRes = await Supabase.instance.client
          .from('batches')
          .select('batch_id, batch_name, date_created')
          .order('date_created', ascending: false)
          .limit(10);

      if (batchRes.isNotEmpty && mounted) {
        List<Map<String, dynamic>> parsedBatches = [];

        for (var b in batchRes) {
          final String bName = (b['batch_name'] as String?) ?? 'Batch 2024-B';
          final String dCreated = (b['date_created'] as String?) ?? 'May 20, 2024';

          parsedBatches.add({
            'id': b['batch_id']?.toString() ?? '',
            'name': bName,
            'code': '#${bName.replaceAll(' ', '')}',
            'status': 'IN PROGRESS',
            'totalRaisers': 3,
            'totalHogs': 42,
            'mortality': 0,
            'startDate': dCreated,
            'investmentAmount': 10000.00,
          });
        }

        setState(() => _activeBatches = parsedBatches);
      } else if (mounted) {
        setState(() => _activeBatches = []);
      }

      // 2. Fetch Active Assignments & Raisers
      final assignRes = await Supabase.instance.client
          .from('hog_raisers')
          .select('hog_raiser_id, name, pig_type, status')
          .limit(10);

      if (assignRes.isNotEmpty && mounted) {
        List<Map<String, dynamic>> parsedAssignments = [];
        for (var a in assignRes) {
          final String rName = (a['name'] as String?) ?? 'Norma Deuda';
          parsedAssignments.add({
            'id': a['hog_raiser_id']?.toString() ?? '',
            'name': rName,
            'batch': 'Batch 2024-A',
            'healthStatus': 'Healthy',
          });
        }
        setState(() => _activeAssignments = parsedAssignments);
      } else if (mounted) {
        setState(() => _activeAssignments = []);
      }
    } catch (e) {
      debugPrint('Error fetching investment data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openCreateBatchModal() async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminMobileNewBatchScreen(),
      ),
    );
    if (res == true) {
      _fetchLiveInvestmentData();
    }
  }

  Future<void> _showPendingRaisersModal() async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminMobilePendingHogRaisersScreen(),
      ),
    );
    if (res == true) {
      _fetchLiveInvestmentData();
    }
  }

  void _showRaiserProfileModal(Map<String, dynamic> item) {
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
                  item['name'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
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
            const SizedBox(height: 4),
            Text(
              'Contract Hog Raiser Profile • ${item['batch']}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: _textMuted,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cardBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Health Status:'),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '✓ Healthy',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF15803D),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Assigned Hogs:'),
                      Text('14 Head (Fattening)',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primarySlate,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close Profile',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
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
        child: RefreshIndicator(
          color: _brandNavy,
          onRefresh: _fetchLiveInvestmentData,
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

                // 1. Dual Top Action Cards (Create Investment Batch & Pending Hog Raisers)
                _buildTopActionCardsRow(),
                const SizedBox(height: 26),

                // 2. Active Batches Section
                _buildActiveBatchesSection(),
                const SizedBox(height: 28),

                // 3. Active Assignments Section
                _buildActiveAssignmentsSection(),
                const SizedBox(height: 32),
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
        'Investment',
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
                content: Text('Search batches or raiser portfolio.'),
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
                    content: Text('All investment notifications up to date.'),
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

  // 1. Dual Top Action Cards (Create Investment Batch & Pending Hog Raisers)
  Widget _buildTopActionCardsRow() {
    return Row(
      children: [
        // Card 1: Create Investment Batch
        Expanded(
          child: InkWell(
            onTap: _openCreateBatchModal,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 100,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEE), // Soft pink surface
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFDE8E8), width: 1.5),
              ),
              child: Center(
                child: Text(
                  'Create Investment\nBatch',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFC73F57),
                    height: 1.25,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Card 2: Pending Hog Raisers
        Expanded(
          child: InkWell(
            onTap: _showPendingRaisersModal,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 100,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFDE8E8), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_top_rounded,
                      color: Color(0xFFC73F57), size: 24),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Pending\nHog Raisers',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFC73F57),
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 2. Active Batches Section
  Widget _buildActiveBatchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Batches',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _brandNavy,
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Displaying all active investment batches.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Text(
                'View All >',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _accentCoral,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_activeBatches.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _cardBorder),
            ),
            child: Column(
              children: [
                const Icon(Icons.batch_prediction_rounded,
                    size: 40, color: _textMuted),
                const SizedBox(height: 10),
                Text(
                  'No Active Batches Found',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: _brandNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap "Create Investment Batch" above to start your first hog rearing cycle.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: _textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activeBatches.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final batch = _activeBatches[index];
              final double amount =
                  (batch['investmentAmount'] as num?)?.toDouble() ?? 10000.00;

              return Container(
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Status Pill, Batch Code, 3-dots Menu
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            batch['status'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF15803D),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          batch['code'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded,
                              color: _textMuted, size: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          onSelected: (val) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Action: $val selected.')),
                            );
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                                value: 'details', child: Text('Batch Details')),
                            const PopupMenuItem(
                                value: 'edit', child: Text('Edit Cycle')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Batch Title
                    Text(
                      batch['name'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _brandNavy,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3-Column Mini Metrics Box
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniMetric(
                              'TOTAL RAISER', batch['totalRaisers'].toString()),
                          Container(
                              width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                          _buildMiniMetric(
                              'TOTAL HOG', batch['totalHogs'].toString()),
                          Container(
                              width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                          _buildMiniMetric(
                              'MORTALITY', batch['mortality'].toString()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Start Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Start Date:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textMuted,
                          ),
                        ),
                        Text(
                          batch['startDate'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _brandNavy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Total Investment Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Investment Amount',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textMuted,
                          ),
                        ),
                        Text(
                          '₱${amount.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: _brandNavy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Dual Action Buttons: [ Print Report ] and [ View Hog Raiser ]
                    Row(
                      children: [
                        // Button 1: Print Report
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE2E8F0),
                                foregroundColor: const Color(0xFF334155),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Generating PDF Report...'),
                                  ),
                                );
                              },
                              child: Text(
                                'Print Report',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Button 2: View Hog Raiser
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _actionBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Viewing raisers for ${batch['name']}'),
                                    backgroundColor: _actionBlue,
                                  ),
                                );
                              },
                              child: Text(
                                'View Hog Raiser',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
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
          ),
      ],
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: _brandNavy,
          ),
        ),
      ],
    );
  }

  // 3. Active Assignments Section
  Widget _buildActiveAssignmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Assignments',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _brandNavy,
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Displaying all active raiser assignments.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Text(
                'View All >',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _accentCoral,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_activeAssignments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _cardBorder),
            ),
            child: Column(
              children: [
                const Icon(Icons.assignment_ind_outlined,
                    size: 40, color: _textMuted),
                const SizedBox(height: 10),
                Text(
                  'No Active Raiser Assignments',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: _brandNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Assignments will appear here once raisers are assigned to active batches.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: _textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activeAssignments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final assign = _activeAssignments[index];

              return Container(
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Raiser Name & Batch Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                assign['name'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: _brandNavy,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                assign['batch'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // View Profile Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _actionBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                          onPressed: () => _showRaiserProfileModal(assign),
                          child: Text(
                            'View Profile',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Health Status Indicator
                    Row(
                      children: [
                        Text(
                          'Health Status:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  size: 14, color: Color(0xFF15803D)),
                              const SizedBox(width: 4),
                              Text(
                                assign['healthStatus'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF15803D),
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
            },
          ),
      ],
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
