import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../../utils/app_strings.dart';
import 'widgets/raiser_empty_state.dart';

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
  String _activeTab = 'All'; // 'All', 'Pending', 'Completed'
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  static const Color _brandColor = Color(0xFF18314F);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _warningAmber = Color(0xFFF59E0B);
  static const Color _dangerRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    final raiserId = widget.raiserData['hog_raiser_id'] ?? widget.raiserData['id'];
    if (raiserId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await Supabase.instance.client
          .from('stock_requests')
          .select('''
            request_id,
            product_name,
            quantity,
            request_date,
            status,
            rejection_reason,
            notes,
            batches(batch_name)
          ''')
          .eq('hog_raiser_id', raiserId)
          .order('request_date', ascending: false);

      if (mounted) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(res as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredRequests {
    if (_activeTab == 'All' || _activeTab == 'Lahat') return _requests;
    if (_activeTab == 'Pending') {
      return _requests.where((r) {
        final s = (r['status'] ?? '').toString().toLowerCase();
        return s == 'pending' || s == 'for_approval';
      }).toList();
    }
    // Completed includes approved, rejected, delivered, completed
    return _requests.where((r) {
      final s = (r['status'] ?? '').toString().toLowerCase();
      return s != 'pending' && s != 'for_approval';
    }).toList();
  }

  String _formatDateString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final formattedDate = '${months[date.month - 1]} ${date.day}, ${date.year}';

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

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? PiggyTrunkTheme.ptBgDark : PiggyTrunkTheme.ptBg;
    final surfaceBg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
    final cardBorder = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
    final textColor = isDark ? PiggyTrunkTheme.ptTextDark : _brandColor;
    final mutedColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;
    final filtered = _filteredRequests;

    final int pendingCount = _requests.where((r) {
      final s = (r['status'] ?? '').toString().toLowerCase();
      return s == 'pending' || s == 'for_approval';
    }).length;

    final int completedCount = _requests.where((r) {
      final s = (r['status'] ?? '').toString().toLowerCase();
      return s != 'pending' && s != 'for_approval';
    }).length;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: surfaceBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : _brandColor.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 16),
            ),
          ),
          onPressed: widget.onBack,
        ),
        title: Text(
          strings.isFilipino ? 'Kasaysayan ng Request' : 'Request History',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: textColor,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: cardBorder, height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterChip(
                      'All',
                      strings.filterAll,
                      _requests.length,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFilterChip(
                      'Pending',
                      strings.filterPending,
                      pendingCount,
                      color: _warningAmber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFilterChip(
                      'Completed',
                      strings.isFilipino ? 'Natapos' : 'Completed',
                      completedCount,
                      color: _successGreen,
                    ),
                  ),
                ],
              ),
            ),

            // ==================== HISTORY LOGS LIST / EMPTY STATE ====================
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white : _brandColor),
                      ),
                    )
                  : filtered.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: RaiserEmptyState(
                              icon: Icons.history_rounded,
                              message: strings.noStockRequestsYet,
                              subtitle: strings.isFilipino
                                  ? 'Wala pang rekord ng mga request.'
                                  : 'No request records available.',
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchRequests,
                          color: isDark ? Colors.white : _brandColor,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final req = filtered[index];
                              final dateStr = _formatDateString(req['request_date']);
                              final status = (req['status'] ?? 'Pending').toString();
                              final quantity = req['quantity'] ?? 1;
                              final category = (req['category'] ?? 'Feeds').toString();
                              final feedType = req['feed_type'];
                              final notes = (req['notes'] ?? '').toString().trim();
                              final rawBatchName = (req['assignments']?['batches']?['batch_name'] ?? 'Batch').toString();

                              String batchName = rawBatchName;
                              if (rawBatchName.contains('(')) {
                                final parts = rawBatchName.split('(');
                                if (parts.last.endsWith(')')) {
                                  batchName = parts.sublist(0, parts.length - 1).join('(').trim();
                                }
                              }

                              Color statusColor;
                              Color statusBgColor;

                              final lowerStatus = status.toLowerCase();
                              if (lowerStatus == 'approved') {
                                statusColor = _successGreen;
                                statusBgColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
                              } else if (lowerStatus == 'pending' || lowerStatus == 'for_approval') {
                                statusColor = _warningAmber;
                                statusBgColor = isDark ? const Color(0xFF78350F) : const Color(0xFFFFFBEB);
                              } else if (lowerStatus == 'rejected' || lowerStatus == 'cancelled') {
                                statusColor = _dangerRed;
                                statusBgColor = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2);
                              } else {
                                statusColor = const Color(0xFF6366F1);
                                statusBgColor = isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF);
                              }

                              IconData itemIcon = Icons.grass_rounded;
                              Color itemColor = const Color(0xFF10B981);
                              Color itemBg = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);

                              if (category.toLowerCase() == 'vitamins') {
                                itemIcon = Icons.medication_liquid_rounded;
                                itemColor = const Color(0xFF8B5CF6);
                                itemBg = isDark ? const Color(0xFF4C1D95) : const Color(0xFFF3E8FF);
                              } else if (category.toLowerCase() == 'medicine') {
                                itemIcon = Icons.medical_services_rounded;
                                itemColor = const Color(0xFFEF4444);
                                itemBg = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2);
                              }

                              String titleText = '$quantity Sacks of $category';
                              if (category.toLowerCase() == 'feeds' && feedType != null) {
                                titleText = '$quantity Sacks of $feedType';
                              } else if (category.toLowerCase() != 'feeds') {
                                titleText = '$quantity Units of $category';
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: surfaceBg,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: cardBorder),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: itemBg,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(itemIcon, color: itemColor, size: 22),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                titleText,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '$batchName • $dateStr',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 12,
                                                  color: mutedColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusBgColor,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: statusColor,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (notes.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.notes_rounded, size: 14, color: mutedColor),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                notes,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11.5,
                                                  color: mutedColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (lowerStatus == 'rejected' && (req['rejection_reason'] != null && req['rejection_reason'].toString().trim().isNotEmpty)) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5)),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'Dahilan: ${req['rejection_reason']}',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11.5,
                                                  color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
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

  Widget _buildFilterChip(String key, String label, int count, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _activeTab == key;
    final inactiveBg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
    final inactiveBorder = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
    final inactiveText = isDark ? PiggyTrunkTheme.ptTextDark : _brandColor;
    final selectedBg = isDark ? Colors.white : _brandColor;
    final selectedText = isDark ? const Color(0xFF0F172A) : Colors.white;

    return GestureDetector(
      onTap: () => setState(() => _activeTab = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : inactiveBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? selectedBg : inactiveBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark ? Colors.white : _brandColor).withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? selectedText : inactiveText,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? const Color(0xFF0F172A).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.22))
                    : (color?.withValues(alpha: isDark ? 0.2 : 0.12) ?? (isDark ? const Color(0xFF1E293B) : PiggyTrunkTheme.ptBg)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? selectedText : (color ?? inactiveText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
