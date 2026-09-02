import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../../../utils/app_strings.dart';
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
  String _selectedFilter = 'All'; // 'All', 'Pending', 'Approved'
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
    final strings = AppStrings.of(context);

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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          strings.stockRequestsTitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.isFilipino ? 'Humiling ng pakain, gamot, o bitamina' : 'Request feeds, medicine, or vitamins',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: PiggyTrunkTheme.ptMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded, color: textColor, size: 20),
                        tooltip: strings.searchRequests,
                        onPressed: () {
                          setState(() {
                            _isSearching = !_isSearching;
                            if (!_isSearching) _searchCtrl.clear();
                          });
                        },
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        icon: Icon(Icons.history_rounded, color: textColor, size: 20),
                        tooltip: strings.requestHistory,
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
                        icon: const Icon(Icons.add_rounded, size: 15),
                        label: Text(
                          strings.request,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : _brandColor,
                          foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          elevation: 0,
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                    color: isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDark ? PiggyTrunkTheme.ptTextDark : _brandColor,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: strings.isFilipino ? 'Maghanap ng batch, pakain, o status...' : 'Search batch, feeds, or status...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted),
                      prefixIcon: Icon(Icons.search, size: 20, color: isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted),
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
                      label: strings.isFilipino ? 'Pakain' : 'Feeds',
                      sublabel: strings.isFilipino ? 'Nutrisyon' : 'Nutrition',
                      imagePath: 'assets/feeds_icon.png',
                      accentColor: const Color(0xFF10B981),
                      onTap: () => _openRequestForm('Feeds'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickCategoryCard(
                      label: strings.isFilipino ? 'Gamot' : 'Medicine',
                      sublabel: strings.isFilipino ? 'Panggagamot' : 'Treatments',
                      imagePath: 'assets/medicine_icon.png',
                      accentColor: const Color(0xFFEF4444),
                      onTap: () => _openRequestForm('Medicine'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickCategoryCard(
                      label: strings.isFilipino ? 'Bitamina' : 'Vitamins',
                      sublabel: strings.isFilipino ? 'Suplemento' : 'Supplements',
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
                    child: _buildFilterChip(strings.filterAll, widget.requestsList.length, filterKey: 'All'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFilterChip(strings.filterPending, pendingCount, color: _warningAmber, filterKey: 'Pending'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFilterChip(strings.filterApproved, approvedCount, color: _successGreen, filterKey: 'Approved'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ==================== SECTION TITLE ====================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.isFilipino ? 'Aktibidad ng Kahilingan' : 'Requests Activity',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  Text(
                    '${displayList.length} ${strings.isFilipino ? 'aytem' : 'items'}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ==================== REQUESTS LIST / EMPTY STATE ====================
              Expanded(
                child: displayList.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24.0),
                          child: RaiserEmptyState(
                            icon: Icons.inventory_2_outlined,
                            message: strings.isFilipino ? 'Walang kahilingan.' : 'No requests found.',
                            subtitle: strings.isFilipino
                                ? 'Pindutin ang "+ Humiling" upang mag-request.'
                                : 'Tap "+ Request" above to request supplies.',
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: displayList.length,
                        itemBuilder: (context, index) {
                          final req = displayList[index];
                          final dateStr = _formatDate(req['request_date']);
                          final status = (req['status'] ?? 'Pending').toString();
                          final quantity = req['quantity'] ?? 1;
                          final category = (req['category'] ?? 'Feeds').toString();
                          final feedType = req['feed_type'];
                          final rawBatchName = (req['assignments']?['batches']?['batch_name'] ?? 'N/A').toString();
                          
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
                            statusBg = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
                          } else if (lowerStatus == 'pending' || lowerStatus == 'for_approval') {
                            statusColor = _warningAmber;
                            statusBg = isDark ? const Color(0xFF78350F) : const Color(0xFFFFFBEB);
                          } else if (lowerStatus == 'rejected' || lowerStatus == 'cancelled') {
                            statusColor = _dangerRed;
                            statusBg = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2);
                          } else {
                            statusColor = const Color(0xFF6366F1);
                            statusBg = isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF);
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
                              color: isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
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
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '$batchName • $dateStr',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (lowerStatus == 'rejected' && (req['rejection_reason'] != null && req['rejection_reason'].toString().trim().isNotEmpty)) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          'Reason: "${req['rejection_reason']}"',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
    final cardBorder = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
    final textColor = isDark ? Colors.white : _brandColor;
    final mutedColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
                  color: accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  imagePath,
                  width: 22,
                  height: 22,
                  color: accentColor,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    label == 'Feeds' || label == 'Pakain' ? Icons.grass_rounded : (label == 'Vitamins' || label == 'Bitamina' ? Icons.medication_liquid_rounded : Icons.medical_services_rounded),
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
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: mutedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, {Color? color, String? filterKey}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final key = filterKey ?? label;
    final isSelected = _selectedFilter == key;
    final inactiveBg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
    final inactiveBorder = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
    final inactiveText = isDark ? PiggyTrunkTheme.ptTextDark : _brandColor;
    final selectedBg = isDark ? Colors.white : _brandColor;
    final selectedText = isDark ? const Color(0xFF0F172A) : Colors.white;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
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
