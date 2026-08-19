import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../slide_over_confirmation_drawer.dart';

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
  Color get _panelBorder => _isDark ? const Color(0xFF2A3E5B) : const Color(0xFFC9D8EC);

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
      final res = await _supabase
          .from('stock_requests')
          .select('*, hog_raisers(name, hog_raiser_id, user_id, app_users!hog_raisers_user_id_fkey(name, email))')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> enriched = [];
      for (var r in (res as List)) {
        final rMap = Map<String, dynamic>.from(r as Map);
        final raiser = rMap['hog_raisers'] as Map<String, dynamic>?;
        final appUsers = raiser?['app_users'] as Map<String, dynamic>?;

        final googleOrAppName = (appUsers?['name'] ?? '').toString().trim();
        final raiserDbName = (raiser?['name'] ?? '').toString().trim();
        final rawUserName = (rMap['user_name'] ?? '').toString().trim();
        final rawRaiserName = (rMap['raiser_name'] ?? '').toString().trim();

        String resolvedName = 'Hog Raiser';
        if (googleOrAppName.isNotEmpty && googleOrAppName.toLowerCase() != 'hog raiser') {
          resolvedName = googleOrAppName;
        } else if (raiserDbName.isNotEmpty && raiserDbName.toLowerCase() != 'hog raiser') {
          resolvedName = raiserDbName;
        } else if (rawUserName.isNotEmpty && rawUserName.toLowerCase() != 'hog raiser') {
          resolvedName = rawUserName;
        } else if (rawRaiserName.isNotEmpty && rawRaiserName.toLowerCase() != 'hog raiser') {
          resolvedName = rawRaiserName;
        }

        rMap['fetched_raiser_name'] = resolvedName;
        enriched.add(rMap);
      }

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
                    ],
                  ),
                ],
              ),
        const SizedBox(height: 18),

        // Requests Table
        if (_isLoadingRequests)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(),
            ),
          )
        else if (filteredRequests.isEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.all(36),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: _mutedColor),
                  const SizedBox(height: 12),
                  Text(
                    'No stock requests found',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Raiser feed and supplies requests will appear here in real-time.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _mutedColor),
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
                  final tableWidth = constraints.maxWidth > 1000 ? constraints.maxWidth : 1000.0;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1.2),
                          1: FlexColumnWidth(1.0),
                          2: FlexColumnWidth(1.0),
                          3: FlexColumnWidth(1.0),
                          4: FlexColumnWidth(0.8),
                          5: FlexColumnWidth(1.0),
                          6: FlexColumnWidth(1.8),
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
                              _tableHeaderCell('CATEGORY'),
                              _tableHeaderCell('FEED TYPE'),
                              _tableHeaderCell('QUANTITY'),
                              _tableHeaderCell('STATUS'),
                              _tableHeaderCell('ACTIONS'),
                            ],
                          ),
                          ...filteredRequests.map((req) => _buildRequestRow(req)),
                        ],
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

  Widget _tableHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: _titleColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0.5,
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
    final category = req['category']?.toString() ?? 'Feeds';
    final feedType = req['feed_type']?.toString() ?? 'N/A';
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
          padding: const EdgeInsets.all(16),
          child: Text(
            raiserName,
            style: GoogleFonts.plusJakartaSans(
              color: _titleColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            requestDate,
            style: GoogleFonts.plusJakartaSans(
              color: _mutedColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            category,
            style: GoogleFonts.plusJakartaSans(
              color: _titleColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            feedType,
            style: GoogleFonts.plusJakartaSans(
              color: _titleColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '$quantity units',
            style: GoogleFonts.plusJakartaSans(
              color: _titleColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
        Padding(
          padding: const EdgeInsets.all(16),
          child: status == 'PENDING'
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: _isProcessingRequest ? null : () => _showApproveDialog(req),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PiggyTrunkTheme.ptSuccess,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Approve',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: _isProcessingRequest ? null : () => _confirmRejectRequest(req),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PiggyTrunkTheme.ptMuted,
                        side: BorderSide(color: _panelBorder),
                        minimumSize: const Size(70, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Reject',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                )
              : Text(
                  'No Actions',
                  style: GoogleFonts.plusJakartaSans(
                    color: _mutedColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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

    List<Product> matchingProducts = widget.products.where((p) {
      return p.category.toLowerCase() == category.toLowerCase();
    }).toList();

    Product? selectedProduct;
    if (matchingProducts.isNotEmpty) {
      if (category.toLowerCase() == 'feeds' && feedType.isNotEmpty) {
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
                                          'Item: $feedType',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _titleColor,
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
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Product to Deduct Stock From
                                  Text(
                                    'SELECT PRODUCT TO DISPATCH FROM *',
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
                                    items: widget.products.map((prod) {
                                      return DropdownMenuItem<Product>(
                                        value: prod,
                                        child: Text(
                                          '[${prod.category}] ${prod.name} (${prod.units} in stock)',
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
                                            : const Color(0xFFEF4444).withValues(alpha: isDark ? 0.15 : 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: hasSufficientStock
                                              ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                              : const Color(0xFFEF4444).withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            hasSufficientStock ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                                            color: hasSufficientStock ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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
                                                    : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B)),
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
    final raiser = req['hog_raisers'] as Map<String, dynamic>?;
    final raiserName = req['fetched_raiser_name'] ?? raiser?['name'] ?? 'Unknown Raiser';
    final requestId = req['request_id'];

    final confirmed = await SlideOverConfirmationDrawer.show(
      context: context,
      title: 'Reject Stock Request',
      message: 'Are you sure you want to reject the stock request from $raiserName?',
      confirmButtonText: 'Reject Request',
      actionType: SlideOverActionType.danger,
      customIcon: Icons.cancel_outlined,
    );

    if (confirmed == true) {
      await _processRejectRequest(requestId);
    }
  }

  Future<void> _processRejectRequest(dynamic requestId) async {
    setState(() => _isProcessingRequest = true);
    try {
      await _supabase.from('stock_requests').update({
        'status': 'rejected',
        'decision_date': DateTime.now().toIso8601String().split('T').first,
      }).eq('request_id', requestId);

      widget.onShowSnackBar(
        'Stock request rejected.',
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
