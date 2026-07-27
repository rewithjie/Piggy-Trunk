import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:piggytrunk/theme/app_theme.dart';

class RequestHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> raiserData;
  final VoidCallback onBack;

  const RequestHistoryScreen({
    super.key,
    required this.raiserData,
    required this.onBack,
  });

  @override
  State<RequestHistoryScreen> createState() => _RequestHistoryScreenState();
}

class _RequestHistoryScreenState extends State<RequestHistoryScreen> {
  String _activeTab = 'Lahat'; // 'Lahat', 'Kasalukuyan', 'Natapos'
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  static const Color _brandColor = Color(0xFF18314F);

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    final raiserId = widget.raiserData['hog_raiser_id'] ?? widget.raiserData['id'];
    if (raiserId == null) return;

    setState(() => _isLoading = true);

    try {
      final res = await Supabase.instance.client
          .from('stock_requests')
          .select('*, assignments(*, batches(*))')
          .eq('hog_raiser_id', raiserId)
          .order('request_date', ascending: false);

      setState(() {
        _requests = List<Map<String, dynamic>>.from(res);
      });
    } catch (e) {
      debugPrint('Error fetching request history: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredRequests {
    if (_activeTab == 'Lahat') return _requests;
    if (_activeTab == 'Kasalukuyan') {
      return _requests.where((r) => (r['status'] as String).toLowerCase() == 'pending').toList();
    }
    // Natapos includes anything that is not pending (approved, rejected, delivered)
    return _requests.where((r) => (r['status'] as String).toLowerCase() != 'pending').toList();
  }

  String _formatDateString(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final formattedDate = '${months[date.month - 1]} ${date.day}, ${date.year}';
      
      // If it contains time (like ISO string with T or space)
      if (dateStr.contains('T') || dateStr.contains(' ')) {
        final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
        final ampm = date.hour >= 12 ? 'PM' : 'AM';
        final minute = date.minute.toString().padLeft(2, '0');
        return '$formattedDate • $hour:$minute $ampm';
      }
      return formattedDate;
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildTabItem(String title) {
    final isSelected = _activeTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = title;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? _brandColor : const Color(0xff718096),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRequests;

    return Scaffold(
      backgroundColor: PiggyTrunkTheme.ptBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _brandColor, size: 20),
          onPressed: widget.onBack,
        ),
        title: Text(
          'Kasaysayan ng Request',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: _brandColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tabs Bar matching mockup
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xfff0f2f5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildTabItem('Lahat'),
                  _buildTabItem('Kasalukuyan'),
                  _buildTabItem('Natapos'),
                ],
              ),
            ),

            // History logs list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_brandColor),
                      ),
                    )
                  : filtered.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: PiggyTrunkTheme.ptBorder),
                              ),
                              child: Center(
                                child: Text(
                                  'Walang kamakailang aktibidad.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: PiggyTrunkTheme.ptMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchRequests,
                          color: _brandColor,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final req = filtered[index];
                              final dateStr = _formatDateString(req['request_date']);
                              final status = req['status'] as String;
                              final quantity = req['quantity'] ?? 1;
                              final category = req['category'] ?? 'Feeds';
                              final feedType = req['feed_type'];
                              
                              Color statusColor = const Color(0xffa0aec0);
                              Color statusBgColor = const Color(0xffa0aec0).withValues(alpha: 0.15);
                              
                              if (status.toLowerCase() == 'approved') {
                                statusColor = PiggyTrunkTheme.ptSuccess;
                                statusBgColor = PiggyTrunkTheme.ptSuccess.withValues(alpha: 0.15);
                              } else if (status.toLowerCase() == 'pending') {
                                statusColor = PiggyTrunkTheme.ptInProgress;
                                statusBgColor = PiggyTrunkTheme.ptInProgress.withValues(alpha: 0.15);
                              } else if (status.toLowerCase() == 'rejected') {
                                statusColor = const Color(0xffef5b6c);
                                statusBgColor = const Color(0xffef5b6c).withValues(alpha: 0.15);
                              } else if (status.toLowerCase() == 'delivered') {
                                statusColor = const Color(0xFF7B52AB);
                                statusBgColor = const Color(0xFF7B52AB).withValues(alpha: 0.15);
                              }

                              String iconPath = 'assets/feeds_icon.png';
                              Color iconColor = const Color(0xFFff9d7d);
                              Color iconBgColor = const Color(0xFFff9d7d).withValues(alpha: 0.15);

                              if (category == 'Vitamins') {
                                iconPath = 'assets/vitamins_icon.png';
                                iconColor = const Color(0xFF4385F4);
                                iconBgColor = const Color(0xFF4385F4).withValues(alpha: 0.15);
                              } else if (category == 'Medicine') {
                                iconPath = 'assets/medicine_icon.png';
                                iconColor = const Color(0xFF8B5CF6);
                                iconBgColor = const Color(0xFF8B5CF6).withValues(alpha: 0.15);
                              }

                              String subtitleText = '$quantity na sako';
                              if (category == 'Feeds' && feedType != null) {
                                subtitleText = '$quantity na sako ($feedType)';
                              } else if (category != 'Feeds') {
                                subtitleText = '$quantity na piraso';
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: PiggyTrunkTheme.ptBorder, width: 0.8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: iconBgColor,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: Image.asset(
                                                iconPath,
                                                color: iconColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  category == 'Feeds'
                                                      ? 'Feeds (Pagkain)'
                                                      : (category == 'Vitamins'
                                                          ? 'Vitamins (Bitamina)'
                                                          : 'Medicine (Gamot)'),
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                    color: _brandColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  subtitleText,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 13,
                                                    color: PiggyTrunkTheme.ptMuted,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: statusBgColor,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  status.toUpperCase(),
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: statusColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: Color(0xffa0aec0),
                                            size: 14,
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24, color: PiggyTrunkTheme.ptBorder),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_month_outlined,
                                            size: 14,
                                            color: Color(0xffa0aec0),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            dateStr,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: PiggyTrunkTheme.ptMuted,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
