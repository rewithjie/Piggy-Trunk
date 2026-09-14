import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../common/shimmer_loading.dart';

class StockRequestsTab extends StatefulWidget {
  final List<Product> products;
  final VoidCallback onProductsReload;
  final void Function(String msg, {Color? backgroundColor}) onShowSnackBar;
  final Future<void> Function({
    required String? productId,
    required String productName,
    required String action,
    required double price,
    required int units,
    String? details,
  }) onInsertLog;

  const StockRequestsTab({
    super.key,
    required this.products,
    required this.onProductsReload,
    required this.onShowSnackBar,
    required this.onInsertLog,
  });

  @override
  State<StockRequestsTab> createState() => _StockRequestsTabState();
}

class _StockRequestsTabState extends State<StockRequestsTab> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _stockRequests = [];
  bool _isLoadingRequests = false;
  String _requestsFilter = 'All';
  bool _isProcessingRequest = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg => _isDark ? const Color(0xFF132238) : Colors.white;
  Color get _cardBorder => _isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
  Color get _titleColor => _isDark ? Colors.white : const Color(0xFF18314F);
  Color get _mutedColor => _isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);
  Color get _fieldBg => _isDark ? const Color(0xFF1A2B44) : const Color(0xFFF5F8FE);
  Color get _fieldText => _isDark ? Colors.white : const Color(0xFF18314F);
  Color get _fieldFocus => _isDark ? const Color(0xFF88A7CE) : const Color(0xFF315C8F);

  @override
  void initState() {
    super.initState();
    _loadStockRequests();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStockRequests() async {
    if (!mounted) return;
    setState(() => _isLoadingRequests = true);
    try {
      // 1. Fetch raw stock requests
      List<dynamic> res = [];
      try {
        res = await _supabase
            .from('stock_requests')
            .select('*, assignments(*, batches(*))')
            .order('request_date', ascending: false)
            .order('request_id', ascending: false);
      } catch (_) {
        try {
          res = await _supabase
              .from('stock_requests')
              .select('*')
              .order('request_date', ascending: false)
              .order('request_id', ascending: false);
        } catch (e1) {
          try {
            res = await _supabase
                .from('stock_requests')
                .select('*')
                .order('created_at', ascending: false);
          } catch (e2) {
            res = await _supabase.from('stock_requests').select('*');
          }
        }
      }

      // 2. Fetch raisers with app_users
      List<dynamic> raisersRaw = [];
      try {
        raisersRaw = await _supabase
            .from('hog_raisers')
            .select('hog_raiser_id, name, app_users!hog_raisers_user_id_fkey(name, email)');
      } catch (_) {
        try {
          raisersRaw = await _supabase.from('hog_raisers').select('hog_raiser_id, name');
        } catch (_) {}
      }

      final Map<String, String> raisersMap = {};
      for (var r in raisersRaw) {
        if (r is! Map) continue;
        final rId = (r['hog_raiser_id'] ?? r['id'])?.toString() ?? '';
        if (rId.isEmpty) continue;

        dynamic appUsersRaw = r['app_users'];
        Map<String, dynamic>? appUsers;
        if (appUsersRaw is Map) {
          appUsers = Map<String, dynamic>.from(appUsersRaw);
        } else if (appUsersRaw is List && appUsersRaw.isNotEmpty && appUsersRaw.first is Map) {
          appUsers = Map<String, dynamic>.from(appUsersRaw.first);
        }

        final googleOrAppName = (appUsers?['name'] ?? '').toString().trim();
        final raiserDbName = (r['name'] ?? '').toString().trim();
        final resolvedName = (googleOrAppName.isNotEmpty && googleOrAppName.toLowerCase() != 'hog raiser')
            ? googleOrAppName
            : (raiserDbName.isNotEmpty ? raiserDbName : 'Hog Raiser');

        raisersMap[rId] = resolvedName;
      }

      // 3. Fetch assignments and batches
      List<dynamic> assignmentsRaw = [];
      try {
        assignmentsRaw = await _supabase
            .from('assignments')
            .select('assignment_id, batch_id, hog_raiser_id, status');
      } catch (_) {
        try {
          assignmentsRaw = await _supabase.from('assignments').select('*');
        } catch (_) {}
      }

      List<dynamic> batchesRaw = [];
      try {
        batchesRaw = await _supabase.from('batches').select('batch_id, batch_name');
      } catch (_) {
        try {
          batchesRaw = await _supabase.from('batches').select('*');
        } catch (_) {}
      }

      final Map<String, String> batchNameMap = {};
      for (var b in batchesRaw) {
        if (b is! Map) continue;
        final bId = (b['batch_id'] ?? b['id'])?.toString() ?? '';
        final bName = (b['batch_name'] ?? b['name'])?.toString() ?? '';
        if (bId.isNotEmpty && bName.isNotEmpty) {
          batchNameMap[bId] = bName;
        }
      }

      final Map<String, String> assignToBatchMap = {};
      final Map<String, String> assignToRaiserMap = {};
      final Map<String, String> raiserToActiveBatchMap = {};
      for (var a in assignmentsRaw) {
        if (a is! Map) continue;
        final aId = (a['assignment_id'] ?? a['id'])?.toString() ?? '';
        final bId = a['batch_id']?.toString() ?? '';
        final rId = a['hog_raiser_id']?.toString() ?? '';
        final status = (a['status'] ?? '').toString().toLowerCase();
        if (aId.isNotEmpty) {
          if (bId.isNotEmpty && batchNameMap.containsKey(bId)) {
            assignToBatchMap[aId] = batchNameMap[bId]!;
          }
          if (rId.isNotEmpty) {
            assignToRaiserMap[aId] = rId;
          }
        }
        if (rId.isNotEmpty && bId.isNotEmpty && batchNameMap.containsKey(bId)) {
          if (status == 'active' || !raiserToActiveBatchMap.containsKey(rId)) {
            raiserToActiveBatchMap[rId] = batchNameMap[bId]!;
          }
        }
      }

      final List<Map<String, dynamic>> enriched = [];
      for (var r in res) {
        if (r is! Map) continue;
        final rMap = Map<String, dynamic>.from(r);

        final rId = (rMap['hog_raiser_id'] ?? '').toString();
        final aId = (rMap['assignment_id'] ?? '').toString();

        String resolvedName = 'Hog Raiser';
        if (rId.isNotEmpty && raisersMap.containsKey(rId)) {
          resolvedName = raisersMap[rId]!;
        } else if (aId.isNotEmpty && assignToRaiserMap.containsKey(aId) && raisersMap.containsKey(assignToRaiserMap[aId])) {
          resolvedName = raisersMap[assignToRaiserMap[aId]]!;
        } else if ((rMap['user_name'] ?? '').toString().trim().isNotEmpty) {
          resolvedName = (rMap['user_name'] ?? '').toString().trim();
        } else if ((rMap['raiser_name'] ?? '').toString().trim().isNotEmpty) {
          resolvedName = (rMap['raiser_name'] ?? '').toString().trim();
        }

        String resolvedBatch = 'Unassigned';
        final joinedAssignment = rMap['assignments'] is Map ? rMap['assignments'] as Map : null;
        final joinedBatch = joinedAssignment?['batches'] is Map ? joinedAssignment!['batches'] as Map : null;
        final joinedBatchName = (joinedBatch?['batch_name'] ?? '').toString().trim();

        if (joinedBatchName.isNotEmpty && joinedBatchName.toLowerCase() != 'null') {
          resolvedBatch = joinedBatchName;
        } else if (aId.isNotEmpty && assignToBatchMap.containsKey(aId)) {
          resolvedBatch = assignToBatchMap[aId]!;
        } else if (rId.isNotEmpty && raiserToActiveBatchMap.containsKey(rId)) {
          resolvedBatch = raiserToActiveBatchMap[rId]!;
        }

        if (resolvedBatch.contains('(')) {
          final parts = resolvedBatch.split('(');
          if (parts.last.endsWith(')')) {
            resolvedBatch = parts.sublist(0, parts.length - 1).join('(').trim();
          }
        }

        rMap['fetched_raiser_name'] = resolvedName;
        rMap['fetched_batch_name'] = resolvedBatch;
        enriched.add(rMap);
      }

      enriched.sort((a, b) {
        final dateA = (a['request_date'] ?? '').toString();
        final dateB = (b['request_date'] ?? '').toString();
        final dateComp = dateB.compareTo(dateA);
        if (dateComp != 0) return dateComp;
        final idA = a['request_id'] is num
            ? (a['request_id'] as num).toInt()
            : (int.tryParse(a['request_id']?.toString() ?? '') ?? 0);
        final idB = b['request_id'] is num
            ? (b['request_id'] as num).toInt()
            : (int.tryParse(b['request_id']?.toString() ?? '') ?? 0);
        return idB.compareTo(idA);
      });

      if (!mounted) return;
      setState(() {
        _stockRequests = enriched;
      });
    } catch (e) {
      debugPrint('Error loading stock requests: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRequests = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    final filteredRequests = _stockRequests.where((req) {
      final status = req['status']?.toString().toUpperCase() ?? 'PENDING';
      if (_requestsFilter != 'All' && status != _requestsFilter.toUpperCase()) {
        return false;
      }
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final raiserName = (req['fetched_raiser_name'] ?? '').toString().toLowerCase();
        final category = (req['category'] ?? '').toString().toLowerCase();
        final feedType = (req['feed_type'] ?? '').toString().toLowerCase();
        if (!raiserName.contains(q) && !category.contains(q) && !feedType.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Controls Row
        isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.plusJakartaSans(color: _fieldText, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Search request or raiser...',
                      hintStyle: GoogleFonts.plusJakartaSans(color: _mutedColor, fontSize: 13.5),
                      prefixIcon: Icon(Icons.search_rounded, color: _mutedColor, size: 20),
                      filled: true,
                      fillColor: _fieldBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _fieldFocus, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRequestFilterChip(
                          'All',
                          'All Requests (${_stockRequests.length})',
                          isMobile: true,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildRequestFilterChip(
                          'Pending',
                          'Pending (${_stockRequests.where((r) => (r['status'] ?? '').toString().toUpperCase() == 'PENDING').length})',
                          isMobile: true,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildRequestFilterChip(
                          'Approved',
                          'Approved',
                          isMobile: true,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildRequestFilterChip(
                          'Rejected',
                          'Rejected',
                          isMobile: true,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.plusJakartaSans(color: _fieldText, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search raiser name, category, or feed type...',
                        hintStyle: GoogleFonts.plusJakartaSans(color: _mutedColor, fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded, color: _mutedColor, size: 20),
                        filled: true,
                        fillColor: _fieldBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _fieldFocus, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Row(
                    children: [
                      _buildRequestFilterChip('All', 'All (${_stockRequests.length})'),
                      const SizedBox(width: 8),
                      _buildRequestFilterChip('Pending', 'Pending (${_stockRequests.where((r) => (r['status'] ?? '').toString().toUpperCase() == 'PENDING').length})'),
                      const SizedBox(width: 8),
                      _buildRequestFilterChip('Approved', 'Approved'),
                      const SizedBox(width: 8),
                      _buildRequestFilterChip('Rejected', 'Rejected'),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isLoadingRequests ? null : _loadStockRequests,
                        tooltip: 'Refresh requests',
                        icon: _isLoadingRequests
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                                ),
                              )
                            : Icon(
                                Icons.refresh_rounded,
                                size: 20,
                                color: _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
        const SizedBox(height: 18),

        // Requests Table
        if (_isLoadingRequests)
          TableSkeletonLoader(
            isDark: _isDark,
            minWidth: 720,
            cardBg: _cardBg,
            cardBorder: _cardBorder,
            headerBg: _isDark ? const Color(0xFF1B2E48) : const Color(0xFFEDF4FC),
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(0.95),
              2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(0.85),
              4: FlexColumnWidth(0.8),
              5: FixedColumnWidth(180),
            },
            headers: const [
              'RAISER NAME',
              'REQUEST DATE',
              'ITEM & CATEGORY',
              'QUANTITY',
              'STATUS',
              'ACTIONS',
            ],
            rowCount: 5,
          )
        else if (filteredRequests.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: _mutedColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No stock requests found',
                    style: GoogleFonts.plusJakartaSans(
                      color: _titleColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Raiser feed and supplies requests will appear here in real-time.',
                    style: GoogleFonts.plusJakartaSans(
                      color: _mutedColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: _cardBg,
              border: Border.all(color: _cardBorder),
              borderRadius: BorderRadius.circular(18),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tableWidth = constraints.maxWidth > 720 ? constraints.maxWidth : 720.0;
                  return Scrollbar(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tableWidth,
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1.2),
                            1: FlexColumnWidth(0.95),
                            2: FlexColumnWidth(1.2),
                            3: FlexColumnWidth(0.85),
                            4: FlexColumnWidth(0.8),
                            5: FixedColumnWidth(180),
                          },
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          children: [
                            TableRow(
                              decoration: BoxDecoration(
                                color: _isDark ? const Color(0xFF1B2E48) : const Color(0xFFEDF4FC),
                                border: Border(bottom: BorderSide(color: _cardBorder)),
                              ),
                              children: [
                                _tableHeaderCell('RAISER NAME'),
                                _tableHeaderCell('REQUEST DATE'),
                                _tableHeaderCell('ITEM & CATEGORY'),
                                _tableHeaderCell('QUANTITY'),
                                _tableHeaderCell('STATUS', isCenter: true),
                                _tableHeaderCell('ACTIONS', isCenter: true),
                              ],
                            ),
                            ...filteredRequests.map((req) => _buildRequestRow(req)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _tableHeaderCell(String label, {bool isCenter = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Text(
        label,
        textAlign: isCenter ? TextAlign.center : TextAlign.start,
        maxLines: 1,
        softWrap: false,
        style: GoogleFonts.plusJakartaSans(
          color: _titleColor,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildRequestFilterChip(String filterValue, String label, {bool isMobile = false}) {
    final isSelected = _requestsFilter == filterValue;
    final activeBg = _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary;
    final activeTextColor = _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white;
    final unselectedBg = _isDark ? const Color(0xFF1A2B44) : const Color(0xFFF1F5F9);
    final unselectedBorder = _isDark ? const Color(0xFF28405D) : const Color(0xFFE2E8F0);
    final unselectedTextColor = _mutedColor;

    return InkWell(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _requestsFilter = filterValue;
          });
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: BoxConstraints(minHeight: isMobile ? 38 : 38, minWidth: isMobile ? 0 : 48),
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 16, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeBg : unselectedBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.transparent : unselectedBorder,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isDark ? 0.25 : 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected ? activeTextColor : unselectedTextColor,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: isMobile ? 11.5 : 13,
          ),
        ),
      ),
    );
  }

  TableRow _buildRequestRow(Map<String, dynamic> req) {
    final raiser = req['hog_raisers'] as Map<String, dynamic>?;
    final raiserName = req['fetched_raiser_name'] ??
        req['raiser_name'] ??
        req['hog_raiser_name'] ??
        req['user_name'] ??
        raiser?['name'] ??
        'Unknown Raiser';
    final requestDate = req['request_date']?.toString() ?? 'N/A';
    final category = req['category']?.toString().trim() ?? 'Feeds';
    final rawFeedType = req['feed_type']?.toString().trim() ?? '';
    final hasDistinctFeedType = rawFeedType.isNotEmpty &&
        rawFeedType.toUpperCase() != 'N/A' &&
        rawFeedType.toLowerCase() != category.toLowerCase();
    final mainItem = hasDistinctFeedType ? rawFeedType : category;
    final subItem = hasDistinctFeedType ? category : null;
    final quantity = req['quantity']?.toString() ?? '0';
    final status = req['status']?.toString().toUpperCase() ?? 'PENDING';

    Color statusBg;
    Color statusFg;
    if (status == 'APPROVED') {
      statusBg = const Color(0x3343CB89);
      statusFg = const Color(0xFF43CB89);
    } else if (status == 'REJECTED') {
      statusBg = const Color(0x33FF758C);
      statusFg = const Color(0xFFFF758C);
    } else {
      statusBg = const Color(0x33FFAA00);
      statusFg = const Color(0xFFFFAA00);
    }

    return TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _cardBorder.withValues(alpha: 0.5))),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Text(
            raiserName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: _titleColor,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Text(
            requestDate,
            style: GoogleFonts.plusJakartaSans(
              color: _mutedColor,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mainItem,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: _titleColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              if (subItem != null) ...[
                const SizedBox(height: 2),
                Text(
                  subItem,
                  style: GoogleFonts.plusJakartaSans(
                    color: _mutedColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Text(
            '$quantity units',
            style: GoogleFonts.plusJakartaSans(
              color: _titleColor,
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: statusFg,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Details Action Button
                  InkWell(
                    onTap: () => _showRequestDetailsModal(req),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (_isDark ? Colors.white : PiggyTrunkTheme.ptPrimary).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (_isDark ? Colors.white : PiggyTrunkTheme.ptPrimary).withValues(alpha: 0.22),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 14,
                            color: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Details',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (status == 'PENDING') ...[
                    const SizedBox(width: 5),
                    // Quick Approve Icon Button
                    Tooltip(
                      message: 'Approve Request',
                      child: InkWell(
                        onTap: _isProcessingRequest ? null : () => _showApproveDialog(req),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: PiggyTrunkTheme.ptSuccess.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: PiggyTrunkTheme.ptSuccess.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: PiggyTrunkTheme.ptSuccess,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    // Quick Reject Icon Button
                    Tooltip(
                      message: 'Reject Request',
                      child: InkWell(
                        onTap: _isProcessingRequest ? null : () => _confirmRejectRequest(req),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF758C).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFFF758C).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Color(0xFFFF758C),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showRequestDetailsModal(Map<String, dynamic> req) {
    final raiser = req['hog_raisers'] as Map<String, dynamic>?;
    final raiserName = req['fetched_raiser_name'] ??
        req['raiser_name'] ??
        req['hog_raiser_name'] ??
        req['user_name'] ??
        raiser?['name'] ??
        'Unknown Raiser';
    final batchName = req['fetched_batch_name'] ?? 'General Stock';
    final requestDate = req['request_date']?.toString() ?? req['created_at']?.toString() ?? 'N/A';
    final category = req['category']?.toString() ?? 'Feeds';
    final feedType = req['feed_type']?.toString() ?? 'N/A';
    final quantity = req['quantity']?.toString() ?? '0';
    final status = req['status']?.toString().toUpperCase() ?? 'PENDING';
    final notes = (req['notes'] ?? '').toString().trim();
    final decisionDate = req['decision_date']?.toString();
    final rejectionReason = (req['rejection_reason'] ?? '').toString().trim();

    Color statusBg;
    Color statusFg;
    IconData statusIcon;
    if (status == 'APPROVED') {
      statusBg = const Color(0x3343CB89);
      statusFg = const Color(0xFF43CB89);
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (status == 'REJECTED') {
      statusBg = const Color(0x33FF758C);
      statusFg = const Color(0xFFFF758C);
      statusIcon = Icons.cancel_outlined;
    } else {
      statusBg = const Color(0x33FFAA00);
      statusFg = const Color(0xFFFFAA00);
      statusIcon = Icons.hourglass_top_rounded;
    }

    // Matching products for stock visibility
    final categoryClean = category.trim().toLowerCase();
    final matchingProducts = widget.products.where((p) {
      final pCat = p.category.trim().toLowerCase();
      if (categoryClean.contains('feed') || categoryClean == 'feeds' || categoryClean == 'pagkain') {
        return pCat.contains('feed') || pCat == 'feeds';
      } else if (categoryClean.contains('vitamin') || categoryClean == 'bitamina') {
        return pCat.contains('vitamin') || pCat == 'vitamins';
      } else if (categoryClean.contains('med') || categoryClean == 'gamot') {
        return pCat.contains('med') || pCat == 'medicines' || pCat == 'medicine';
      }
      return pCat == categoryClean;
    }).toList();

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Request Details Drawer',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogCtx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (dialogCtx, anim1, anim2, child) {
        final curvedValue = Curves.easeOutCubic.transform(anim1.value);
        final screenWidth = MediaQuery.of(dialogCtx).size.width;
        final isMobile = screenWidth < 600;
        final drawerWidth = isMobile ? screenWidth : 460.0;

        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark || Theme.of(context).brightness == Brightness.dark;
        final drawerBg = isDark ? const Color(0xFF132238) : Colors.white;
        final borderColor = isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
        final titleColor = isDark ? Colors.white : const Color(0xFF18314F);
        final mutedColor = isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);
        final cardBg = isDark ? const Color(0xFF1A2B44) : const Color(0xFFF8FAFC);
        final cardBorder = isDark ? const Color(0xFF28405D) : const Color(0xFFE2E8F0);

        return Transform.translate(
          offset: Offset((1.0 - curvedValue) * drawerWidth, 0.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: drawerWidth,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: drawerBg,
                  border: Border(left: BorderSide(color: borderColor, width: 1.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
                      blurRadius: 24,
                      offset: const Offset(-4, 0),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                        decoration: BoxDecoration(
                          color: drawerBg,
                          border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : PiggyTrunkTheme.ptPrimary).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.assignment_outlined,
                                color: isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stock Request Details',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: titleColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Request ID #${req['request_id'] ?? ''}',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: mutedColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(dialogCtx).pop(),
                              icon: Icon(Icons.close_rounded, color: titleColor, size: 22),
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                      ),

                      // Content Body
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status Banner
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: statusFg.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(statusIcon, color: statusFg, size: 20),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Status: $status',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: statusFg,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        Text(
                                          'Requested on $requestDate',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Raiser & Batch Card
                              _buildDetailSectionTitle('RAISER & BATCH INFORMATION', titleColor),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: cardBorder),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    _buildDetailRow('Hog Raiser', raiserName, Icons.person_outline_rounded, titleColor, mutedColor, isDark),
                                    const Divider(height: 20, thickness: 0.8),
                                    _buildDetailRow('Assigned Batch', batchName, Icons.layers_outlined, titleColor, mutedColor, isDark),
                                    const Divider(height: 20, thickness: 0.8),
                                    _buildDetailRow('Date Submitted', requestDate, Icons.calendar_today_outlined, titleColor, mutedColor, isDark),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Requested Item Card
                              _buildDetailSectionTitle('REQUESTED SUPPLY', titleColor),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: cardBorder),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    _buildDetailRow('Category', category, Icons.category_outlined, titleColor, mutedColor, isDark),
                                    const Divider(height: 20, thickness: 0.8),
                                    _buildDetailRow('Item / Feed Type', feedType.isNotEmpty && feedType != 'N/A' ? feedType : category, Icons.inventory_2_outlined, titleColor, mutedColor, isDark),
                                    const Divider(height: 20, thickness: 0.8),
                                    _buildDetailRow('Quantity Requested', '$quantity units / sacks', Icons.format_list_numbered_rounded, titleColor, mutedColor, isDark, isHighlight: true),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // RAISER'S MESSAGE (HIGHLIGHTED)
                              _buildDetailSectionTitle("RAISER'S MESSAGE / NOTE", titleColor),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: cardBorder),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          size: 16,
                                          color: isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          notes.isNotEmpty ? 'Message from Raiser' : 'No Message Attached',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      notes.isNotEmpty ? notes : 'The raiser did not include any specific notes with this stock request.',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: notes.isNotEmpty ? titleColor : mutedColor,
                                        fontSize: 13.5,
                                        fontWeight: notes.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
                                        fontStyle: notes.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Rejection Reason (if rejected)
                              if (status == 'REJECTED' && rejectionReason.isNotEmpty) ...[
                                const SizedBox(height: 18),
                                _buildDetailSectionTitle('REJECTION REASON', const Color(0xFFFF758C)),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF758C).withValues(alpha: _isDark ? 0.12 : 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFFF758C).withValues(alpha: 0.3)),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFFF758C)),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Admin Reason ($decisionDate)',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: const Color(0xFFFF758C),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        rejectionReason,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: titleColor,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Matching Inventory Stocks
                              if (matchingProducts.isNotEmpty) ...[
                                const SizedBox(height: 18),
                                _buildDetailSectionTitle('CURRENT INVENTORY STOCKS', titleColor),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: cardBorder),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: matchingProducts.take(3).map((prod) {
                                      final inStock = prod.units;
                                      final isLow = inStock <= 5;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                prod.name,
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: titleColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12.5,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isLow
                                                    ? const Color(0xFFFF758C).withValues(alpha: 0.15)
                                                    : PiggyTrunkTheme.ptSuccess.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '$inStock in stock',
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: isLow ? const Color(0xFFFF758C) : PiggyTrunkTheme.ptSuccess,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Footer Actions
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: drawerBg,
                          border: Border(top: BorderSide(color: borderColor, width: 1)),
                        ),
                        child: status == 'PENDING'
                            ? Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.of(dialogCtx).pop();
                                        _confirmRejectRequest(req);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFFF758C),
                                        side: BorderSide(color: const Color(0xFFFF758C).withValues(alpha: _isDark ? 0.35 : 0.3)),
                                        backgroundColor: const Color(0xFFFF758C).withValues(alpha: _isDark ? 0.1 : 0.08),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: Text(
                                        'Reject',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.of(dialogCtx).pop();
                                        _showApproveDialog(req);
                                      },
                                      icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                                      label: Text(
                                        'Approve & Fulfill',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: PiggyTrunkTheme.ptSuccess,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(dialogCtx).pop(),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: BorderSide(color: borderColor),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: Text(
                                    'Close',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: titleColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailSectionTitle(String title, Color color) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color titleColor, Color mutedColor, bool isDark, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: mutedColor),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: mutedColor,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w700,
            color: isHighlight ? (isDark ? Colors.white : PiggyTrunkTheme.ptPrimary) : titleColor,
          ),
        ),
      ],
    );
  }

  Future<void> _showApproveDialog(Map<String, dynamic> req) async {
    final category = req['category']?.toString() ?? 'Feeds';
    final feedType = req['feed_type']?.toString() ?? '';
    final requestedQuantity = (req['quantity'] as num?)?.toInt() ?? 1;
    final raiser = req['hog_raisers'] as Map<String, dynamic>?;
    final raiserName = req['fetched_raiser_name'] ?? raiser?['name'] ?? 'Unknown Raiser';
    final requestId = req['request_id'];
    final notes = (req['notes'] ?? '').toString().trim();

    final categoryClean = category.trim().toLowerCase();
    List<Product> matchingProducts = widget.products.where((p) {
      final pCat = p.category.trim().toLowerCase();
      if (categoryClean.contains('feed') || categoryClean == 'feeds' || categoryClean == 'pagkain') {
        return pCat.contains('feed') || pCat == 'feeds';
      } else if (categoryClean.contains('vitamin') || categoryClean == 'bitamina') {
        return pCat.contains('vitamin') || pCat == 'vitamins';
      } else if (categoryClean.contains('med') || categoryClean == 'gamot') {
        return pCat.contains('med') || pCat == 'medicines' || pCat == 'medicine';
      }
      return pCat == categoryClean;
    }).toList();

    if (matchingProducts.isEmpty) {
      matchingProducts = widget.products;
    }

    Product? selectedProduct;
    if (matchingProducts.isNotEmpty) {
      if (categoryClean.contains('feed') && feedType.isNotEmpty) {
        selectedProduct = matchingProducts.firstWhere(
          (p) => p.name.toLowerCase().contains(feedType.toLowerCase()),
          orElse: () => matchingProducts.first,
        );
      } else {
        selectedProduct = matchingProducts.first;
      }
    }

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Approve Request Drawer',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogCtx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (dialogCtx, anim1, anim2, child) {
        final curvedValue = Curves.easeOutCubic.transform(anim1.value);
        final screenWidth = MediaQuery.of(dialogCtx).size.width;
        final isMobile = screenWidth < 600;
        final drawerWidth = isMobile ? screenWidth : 420.0;

        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark || Theme.of(context).brightness == Brightness.dark;
        final drawerBg = isDark ? const Color(0xFF132238) : Colors.white;
        final borderColor = isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
        final titleColor = isDark ? Colors.white : const Color(0xFF18314F);
        final mutedColor = isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);
        final fieldBg = isDark ? const Color(0xFF1A2B44) : const Color(0xFFF5F8FE);
        final fieldBorder = isDark ? const Color(0xFF2A3E5B) : const Color(0xFFC9D8EC);
        final cardBg = isDark ? const Color(0xFF1A2B44) : const Color(0xFFEFF6FF);
        final cardBorder = isDark ? const Color(0xFF28405D) : const Color(0xFFBFDBFE);

        return Transform.translate(
          offset: Offset((1.0 - curvedValue) * drawerWidth, 0.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(
                builder: (stfCtx, setStateDialog) {
                  Product? selectedProdInDialog = selectedProduct;
                  final hasSufficientStock = selectedProdInDialog != null && selectedProdInDialog.units >= requestedQuantity;

                  return Container(
                    width: drawerWidth,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: drawerBg,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
                          blurRadius: 24,
                          offset: const Offset(-4, 0),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.task_alt_rounded,
                                    color: Color(0xFF10B981),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Approve Request',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: titleColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Release stock from inventory',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: mutedColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close_rounded, color: mutedColor, size: 20),
                                  splashRadius: 20,
                                  onPressed: () => Navigator.of(dialogCtx).pop(),
                                ),
                              ],
                            ),
                          ),

                          // Body
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Raiser Request Card
                                  Text(
                                    'REQUEST DETAILS',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: mutedColor,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: cardBorder),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              raiserName,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w800,
                                                color: titleColor,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                category,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: const Color(0xFF3B82F6),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Item: ${feedType.isNotEmpty ? feedType : category}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: titleColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Requested Amount: $requestedQuantity units',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF10B981),
                                          ),
                                        ),
                                        if (notes.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF111C2E) : Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isDark ? const Color(0xFF2C3E55) : const Color(0xFFCBD5E1),
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(Icons.speaker_notes_outlined, size: 15, color: Color(0xFFD97706)),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'Notes: "$notes"',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      fontStyle: FontStyle.italic,
                                                      color: titleColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Product to Deduct Stock From
                                  Text(
                                    'SELECT PRODUCT TO DISPATCH FROM ($category ONLY) *',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: mutedColor,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<Product>(
                                    initialValue: selectedProduct,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: fieldBg,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: fieldBorder),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                      ),
                                    ),
                                    dropdownColor: fieldBg,
                                    borderRadius: BorderRadius.circular(12),
                                    style: GoogleFonts.plusJakartaSans(
                                      color: titleColor,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    items: matchingProducts.map((prod) {
                                      return DropdownMenuItem<Product>(
                                        value: prod,
                                        child: Text(
                                          '${prod.name} (${prod.units} in stock)',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setStateDialog(() {
                                        selectedProduct = val;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Stock availability warning / preview
                                  if (selectedProdInDialog != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: hasSufficientStock
                                            ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.12 : 0.08)
                                            : const Color(0xFFFF758C).withValues(alpha: isDark ? 0.12 : 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: hasSufficientStock
                                              ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                              : const Color(0xFFFF758C).withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            hasSufficientStock ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                                            color: hasSufficientStock ? const Color(0xFF10B981) : const Color(0xFFFF758C),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              hasSufficientStock
                                                  ? 'Stock available. ${selectedProdInDialog.units} units in stock. After dispatch: ${selectedProdInDialog.units - requestedQuantity} units.'
                                                  : 'Insufficient stock! Only ${selectedProdInDialog.units} units available ($requestedQuantity needed).',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                                color: hasSufficientStock
                                                    ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46))
                                                    : (isDark ? const Color(0xFFFDA4AF) : const Color(0xFF9F1239)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Footer Actions
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: drawerBg,
                              border: Border(top: BorderSide(color: borderColor, width: 1)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isProcessingRequest ? null : () => Navigator.of(dialogCtx).pop(),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      side: BorderSide(color: fieldBorder),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: titleColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                    child: ElevatedButton.icon(
                                      onPressed: (_isProcessingRequest || !hasSufficientStock)
                                          ? null
                                          : () async {
                                              Navigator.of(dialogCtx).pop();
                                              await _processApproveRequest(
                                                requestId: requestId,
                                                product: selectedProdInDialog,
                                                requestedUnits: requestedQuantity,
                                                raiserName: raiserName,
                                                raiserId: req['hog_raiser_id'],
                                              );
                                            },
                                      icon: _isProcessingRequest
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.check_rounded, size: 18),
                                      label: Text(
                                        _isProcessingRequest ? 'Processing...' : 'Confirm Approval',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
    }

  Future<void> _processApproveRequest({
    required dynamic requestId,
    required Product product,
    required int requestedUnits,
    required String raiserName,
    dynamic raiserId,
  }) async {
    setState(() => _isProcessingRequest = true);
    try {
      final newUnits = product.units - requestedUnits;
      await _supabase
          .from('inventory_products')
          .update({'units': newUnits})
          .eq('id', product.id);

      await _supabase.from('stock_requests').update({
        'status': 'approved',
        'decision_date': DateTime.now().toIso8601String().split('T').first,
      }).eq('request_id', requestId);

      if (raiserId != null) {
        try {
          await _supabase.from('raiser_notifications').insert({
            'hog_raiser_id': raiserId,
            'title': 'Stock Request Update',
            'message': 'Your request for $requestedUnits ${product.name} has been approved.',
            'type': 'request_approved',
            'is_read': false,
          });
        } catch (_) {}
      }

      await widget.onInsertLog(
        productId: product.id,
        productName: product.name,
        action: 'REQUEST_APPROVE',
        price: product.price,
        units: newUnits,
        details: 'Approved request for $raiserName. Dispatched -$requestedUnits units. Remaining: $newUnits units.',
      );

      widget.onShowSnackBar(
        'Stock request for $raiserName approved successfully! Dispatched $requestedUnits units.',
        backgroundColor: PiggyTrunkTheme.ptSuccess,
      );

      await _loadStockRequests();
      widget.onProductsReload();
    } catch (e) {
      debugPrint('Error approving stock request: $e');
      widget.onShowSnackBar(
        'Failed to approve request: $e',
        backgroundColor: Colors.redAccent,
      );
    } finally {
      setState(() => _isProcessingRequest = false);
    }
  }

  void _confirmRejectRequest(Map<String, dynamic> req) async {
    final category = req['category']?.toString() ?? 'Feeds';
    final feedType = req['feed_type']?.toString() ?? '';
    final requestedQuantity = (req['quantity'] as num?)?.toInt() ?? 1;
    final raiser = req['hog_raisers'] as Map<String, dynamic>?;
    final raiserName = req['fetched_raiser_name'] ?? raiser?['name'] ?? 'Unknown Raiser';
    final requestId = req['request_id'];
    final raiserId = req['hog_raiser_id'];
    final itemDesc = feedType.isNotEmpty ? '$requestedQuantity $feedType' : '$requestedQuantity $category';

    final reasonController = TextEditingController();

    final isConfirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Reject Request Modal',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogCtx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (dialogCtx, anim1, anim2, child) {
        final curvedValue = Curves.easeOutCubic.transform(anim1.value);
        final screenWidth = MediaQuery.of(dialogCtx).size.width;
        final isMobile = screenWidth < 600;
        final drawerWidth = isMobile ? screenWidth : 420.0;

        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark || Theme.of(context).brightness == Brightness.dark;
        final drawerBg = isDark ? const Color(0xFF132238) : Colors.white;
        final borderColor = isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
        final titleColor = isDark ? Colors.white : const Color(0xFF18314F);
        final mutedColor = isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);
        final fieldBg = isDark ? const Color(0xFF1A2B44) : const Color(0xFFF5F8FE);
        final fieldBorder = isDark ? const Color(0xFF2A3E5B) : const Color(0xFFC9D8EC);

        return Transform.translate(
          offset: Offset((1.0 - curvedValue) * drawerWidth, 0.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: drawerWidth,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: drawerBg,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
                      blurRadius: 24,
                      offset: const Offset(-4, 0),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF758C).withValues(alpha: isDark ? 0.15 : 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFFF758C).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.cancel_outlined,
                                color: Color(0xFFFF758C),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reject Stock Request',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: titleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Decline supply request from $raiserName',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: mutedColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded, color: mutedColor, size: 20),
                              splashRadius: 20,
                              onPressed: () => Navigator.of(dialogCtx).pop(false),
                            ),
                          ],
                        ),
                      ),

                      // Body
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rejection Reason *',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ang mensaheng ito ay ipapadala bilang notification sa Hog Raiser upang malaman niya kung bakit hindi na-approve ang kaniyang request.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: mutedColor,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: reasonController,
                                maxLines: 4,
                                textCapitalization: TextCapitalization.sentences,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  color: titleColor,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Hal. Kulang ang stock sa warehouse, o paki-update ang batch info...',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: mutedColor,
                                  ),
                                  filled: true,
                                  fillColor: fieldBg,
                                  contentPadding: const EdgeInsets.all(14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: fieldBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: fieldBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFFF758C), width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Footer Actions
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: drawerBg,
                          border: Border(top: BorderSide(color: borderColor, width: 1)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(dialogCtx).pop(false),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: BorderSide(color: fieldBorder),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: titleColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.of(dialogCtx).pop(true),
                                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                                label: Text(
                                  'Confirm Rejection',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF758C),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (isConfirmed == true) {
      final reasonText = reasonController.text.trim();
      await _processRejectRequest(
        requestId: requestId,
        raiserId: raiserId,
        raiserName: raiserName,
        itemDesc: itemDesc,
        rejectionReason: reasonText,
      );
    }
  }

  Future<void> _processRejectRequest({
    required dynamic requestId,
    required dynamic raiserId,
    required String raiserName,
    required String itemDesc,
    required String rejectionReason,
  }) async {
    setState(() => _isProcessingRequest = true);
    try {
      try {
        await _supabase.from('stock_requests').update({
          'status': 'rejected',
          'decision_date': DateTime.now().toIso8601String().split('T').first,
          'rejection_reason': rejectionReason.isNotEmpty ? rejectionReason : null,
        }).eq('request_id', requestId);
      } catch (_) {
        await _supabase.from('stock_requests').update({
          'status': 'rejected',
          'decision_date': DateTime.now().toIso8601String().split('T').first,
        }).eq('request_id', requestId);
      }

      if (raiserId != null) {
        final notifMsg = rejectionReason.isNotEmpty
            ? 'Your request for $itemDesc has been rejected. Reason: "$rejectionReason"'
            : 'Your request for $itemDesc has been rejected.';
        try {
          await _supabase.from('raiser_notifications').insert({
            'hog_raiser_id': raiserId,
            'title': 'Stock Request Update',
            'message': notifMsg,
            'type': 'request_rejected',
            'is_read': false,
          });
        } catch (notifErr) {
          debugPrint('Error inserting raiser notification: $notifErr');
        }
      }

      widget.onShowSnackBar(
        'Stock request from $raiserName has been rejected.',
        backgroundColor: Colors.orange,
      );

      await _loadStockRequests();
    } catch (e) {
      debugPrint('Error rejecting stock request: $e');
      widget.onShowSnackBar(
        'Failed to reject request: $e',
        backgroundColor: Colors.redAccent,
      );
    } finally {
      setState(() => _isProcessingRequest = false);
    }
  }
}
