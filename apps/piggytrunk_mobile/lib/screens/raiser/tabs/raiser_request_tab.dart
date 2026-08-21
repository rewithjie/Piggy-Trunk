import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../request_form_screen.dart';
import '../request_history_screen.dart';
import '../widgets/raiser_empty_state.dart';

class RaiserRequestTab extends StatefulWidget {
  final List<Map<String, dynamic>> activeAssignments;
  final Map<String, dynamic> raiserData;
  final List<Map<String, dynamic>> requestsList;
  final Future<void> Function() onRefresh;

  const RaiserRequestTab({
    super.key,
    required this.activeAssignments,
    required this.raiserData,
    required this.requestsList,
    required this.onRefresh,
  });

  @override
  State<RaiserRequestTab> createState() => _RaiserRequestTabState();
}

class _RaiserRequestTabState extends State<RaiserRequestTab> {
  String _requestView = 'home';
  String? _previousRequestView;
  String _selectedCategoryForForm = 'Feeds';
  String _selectedFilter = 'Lahat'; // 'Lahat', 'Pending', 'Approved'
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearching = false;

  static const Color _brandColor = Color(0xFF18314F);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _warningAmber = Color(0xFFF59E0B);
  static const Color _dangerRed = Color(0xFFEF4444);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openRequestForm([String category = 'Feeds']) {
    setState(() {
      _selectedCategoryForForm = category;
      _previousRequestView = 'home';
      _requestView = 'form';
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  List<Map<String, dynamic>> get _filteredRequests {
    final query = _searchCtrl.text.trim().toLowerCase();
    return widget.requestsList.where((req) {
      final status = (req['status'] ?? '').toString().toLowerCase();
      final category = (req['category'] ?? '').toString().toLowerCase();
      final feedType = (req['feed_type'] ?? '').toString().toLowerCase();
      final batchName = (req['assignments']?['batches']?['batch_name'] ?? '').toString().toLowerCase();

      // Filter by status tab
      if (_selectedFilter == 'Pending' && status != 'pending' && status != 'for_approval') {
        return false;
      }
      if (_selectedFilter == 'Approved' && status != 'approved') {
        return false;
      }

      // Filter by search query
      if (query.isNotEmpty) {
        final matches = category.contains(query) ||
            feedType.contains(query) ||
            batchName.contains(query) ||
            status.contains(query);
        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : _brandColor;

    if (_requestView == 'form') {
      return RequestFormScreen(
        activeAssignments: widget.activeAssignments,
        raiserData: widget.raiserData,
        initialCategory: _selectedCategoryForForm,
        onBack: () {
          setState(() {
            _requestView = 'home';
          });
        },
        onSuccess: () {
          setState(() {
            _requestView = 'home';
          });
          widget.onRefresh();
        },
        onViewHistory: () {
          setState(() {
            _previousRequestView = 'form';
            _requestView = 'history';
          });
        },
      );
    } else if (_requestView == 'history') {
      return RequestHistoryScreen(
        raiserData: widget.raiserData,
        onBack: () {
          setState(() {
            _requestView = _previousRequestView ?? 'home';
            _previousRequestView = null;
          });
        },
      );
    }

    final int pendingCount = widget.requestsList.where((r) {
      final s = (r['status'] ?? '').toString().toLowerCase();
      return s == 'pending' || s == 'for_approval';
    }).length;

    final int approvedCount = widget.requestsList.where((r) {
      return (r['status'] ?? '').toString().toLowerCase() == 'approved';
    }).length;

    final displayList = _filteredRequests;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: widget.onRefresh,
        color: _brandColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================== TOP ACTION ICONS & HEADER BAR ====================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock Requests',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Humiling ng feeds, gamot, o bitamina',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: PiggyTrunkTheme.ptMuted,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded, color: textColor),
                        tooltip: 'Search Requests',
                        onPressed: () {
                          setState(() {
                            _isSearching = !_isSearching;
                            if (!_isSearching) _searchCtrl.clear();
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.history_rounded, color: textColor),
                        tooltip: 'Request History',
                        onPressed: () {
                          setState(() {
                            _previousRequestView = 'home';
                            _requestView = 'history';
                          });
                        },
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton.icon(
                        onPressed: () => _openRequestForm('Feeds'),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(
                          'Request',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : _brandColor,
                          foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search Bar (When Active)
              if (_isSearching) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: PiggyTrunkTheme.ptBorder),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Maghanap ng batch, feeds, o status...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: PiggyTrunkTheme.ptMuted),
                      prefixIcon: const Icon(Icons.search, size: 20, color: PiggyTrunkTheme.ptMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],

              // ==================== QUICK SUPPLY REQUEST CARDS ====================
              Row(
                children: [
                  Expanded(
                    child: _buildQuickCategoryCard(
                      label: 'Feeds',
                      sublabel: 'Pagkain',
                      imagePath: 'assets/feeds_icon.png',
                      accentColor: const Color(0xFF10B981),
                      onTap: () => _openRequestForm('Feeds'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickCategoryCard(
                      label: 'Medicine',
                      sublabel: 'Gamot',
                      imagePath: 'assets/medicine_icon.png',
                      accentColor: const Color(0xFFEF4444),
                      onTap: () => _openRequestForm('Medicine'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickCategoryCard(
                      label: 'Vitamins',
                      sublabel: 'Bitamina',
                      imagePath: 'assets/vitamins_icon.png',
                      accentColor: const Color(0xFF8B5CF6),
                      onTap: () => _openRequestForm('Vitamins'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ==================== ENLARGED BALANCED FILTER PILLS ====================
              Row(
                children: [
                  Expanded(
                    child: _buildFilterChip('Lahat', widget.requestsList.length),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFilterChip('Pending', pendingCount, color: _warningAmber),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFilterChip('Approved', approvedCount, color: _successGreen),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ==================== SECTION TITLE ====================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Requests Activity',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  Text(
                    '${displayList.length} items',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: PiggyTrunkTheme.ptMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ==================== REQUESTS LIST / EMPTY STATE ====================
              Expanded(
                child: displayList.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: RaiserEmptyState(
                          icon: Icons.assignment_outlined,
                          message: _searchCtrl.text.isNotEmpty
                              ? 'Walang nahanap na request.'
                              : 'Walang kamakailang aktibidad.',
                          subtitle: _searchCtrl.text.isNotEmpty
                              ? 'Subukang maghanap ng ibang keyword.'
                              : 'Pumili sa mga kategorya sa itaas o pindutin ang "+ Request" sa itaas upang humiling ng feeds, gamot, o bitamina.',
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        itemCount: displayList.length,
                        padding: const EdgeInsets.only(bottom: 80),
                        itemBuilder: (context, index) {
                          final req = displayList[index];
                          final dateStr = _formatDate(req['request_date']);
                          final status = (req['status'] ?? 'Pending').toString();
                          final quantity = req['quantity'] ?? 1;
                          final category = (req['category'] ?? 'Feeds').toString();
                          final feedType = req['feed_type'];
                          final rawBatchName = (req['assignments']?['batches']?['batch_name'] ?? 'Batch').toString();
                          
                          String batchName = rawBatchName;
                          if (rawBatchName.contains('(')) {
                            final parts = rawBatchName.split('(');
                            if (parts.last.endsWith(')')) {
                              batchName = parts.sublist(0, parts.length - 1).join('(').trim();
                            }
                          }

                          Color statusColor;
                          Color statusBg;
                          final lowerStatus = status.toLowerCase();
                          if (lowerStatus == 'approved') {
                            statusColor = _successGreen;
                            statusBg = const Color(0xFFECFDF5);
                          } else if (lowerStatus == 'rejected' || lowerStatus == 'cancelled') {
                            statusColor = _dangerRed;
                            statusBg = const Color(0xFFFEF2F2);
                          } else {
                            statusColor = _warningAmber;
                            statusBg = const Color(0xFFFFFBEB);
                          }

                          IconData itemIcon = Icons.grass_rounded;
                          Color itemColor = const Color(0xFF10B981);
                          Color itemBg = const Color(0xFFECFDF5);

                          if (category.toLowerCase() == 'vitamins') {
                            itemIcon = Icons.medication_liquid_rounded;
                            itemColor = const Color(0xFF8B5CF6);
                            itemBg = const Color(0xFFF3E8FF);
                          } else if (category.toLowerCase() == 'medicine') {
                            itemIcon = Icons.medical_services_rounded;
                            itemColor = const Color(0xFFEF4444);
                            itemBg = const Color(0xFFFEE2E2);
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: PiggyTrunkTheme.ptBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
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
                                          color: _brandColor,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '$batchName • $dateStr',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: PiggyTrunkTheme.ptMuted,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (lowerStatus == 'rejected' && (req['rejection_reason'] != null && req['rejection_reason'].toString().trim().isNotEmpty)) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          'Dahilan: "${req['rejection_reason']}"',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFEF4444),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusBg,
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
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCategoryCard({
    required String label,
    required String sublabel,
    required String imagePath,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PiggyTrunkTheme.ptBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  imagePath,
                  width: 22,
                  height: 22,
                  color: accentColor,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    label == 'Feeds' ? Icons.grass_rounded : (label == 'Vitamins' ? Icons.medication_liquid_rounded : Icons.medical_services_rounded),
                    size: 22,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _brandColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: PiggyTrunkTheme.ptMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, {Color? color}) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? _brandColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _brandColor : PiggyTrunkTheme.ptBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _brandColor.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
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
                color: isSelected ? Colors.white : _brandColor,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.22)
                    : (color?.withValues(alpha: 0.12) ?? PiggyTrunkTheme.ptBg),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : (color ?? _brandColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
