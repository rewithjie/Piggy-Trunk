import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/models/pos_model.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../widgets/cashier_empty_state.dart';

class CashierRequestsTab extends StatefulWidget {
  final List<Map<String, dynamic>> pendingRequests;
  final List<POSProduct> allProducts;
  final Future<void> Function(int requestId, String status, {int? allocatedSacks, int? productId}) onProcessRequest;

  const CashierRequestsTab({
    super.key,
    required this.pendingRequests,
    required this.allProducts,
    required this.onProcessRequest,
  });

  @override
  State<CashierRequestsTab> createState() => _CashierRequestsTabState();
}

class _CashierRequestsTabState extends State<CashierRequestsTab> {
  int _selectedTab = 0; // 0 = ALL REQUESTS, 1 = HISTORICAL
  Map<String, dynamic>? _selectedRequest; // Selected request for allocation view
  int _allocatedSacks = 15; // Default stepper count
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
  }

  void _openAllocationView(Map<String, dynamic> request) {
    final qty = request['quantity'] as int? ?? 1;
    setState(() {
      _selectedRequest = request;
      _allocatedSacks = qty > 0 ? qty : 1;
    });
  }

  void _closeAllocationView() {
    setState(() {
      _selectedRequest = null;
    });
  }

  String _getTimeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Requested recently';
    try {
      final dt = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) {
        return 'Requested ${diff.inMinutes <= 0 ? 1 : diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return 'Requested ${diff.inHours}h ago';
      } else {
        return 'Requested ${diff.inDays}d ago';
      }
    } catch (_) {
      return 'Requested recently';
    }
  }

  bool _matchesDateFilter(Map<String, dynamic> req) {
    if (_startDate == null || _endDate == null) return true;
    final dateStr = (req['created_at'] as String?) ?? (req['request_date'] as String?);
    if (dateStr == null || dateStr.isEmpty) return true;

    try {
      final reqDt = DateTime.parse(dateStr);
      final reqDateOnly = DateTime(reqDt.year, reqDt.month, reqDt.day);
      final sDate = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      final eDate = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);

      if (reqDateOnly.isBefore(sDate)) return false;
      if (reqDt.isAfter(eDate)) return false;
      return true;
    } catch (_) {}
    return true;
  }

  Future<void> _showFilterModal() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      helpText: 'PUMILI NG PETSA SA KALENDARYO',
      cancelText: 'I-RESET',
      confirmText: 'I-APPLY',
      saveText: 'I-APPLY',
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 7)),
              end: DateTime.now(),
            ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF18314F),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF18314F),
              secondary: Color(0xFF34D399),
            ),
            scaffoldBackgroundColor: Colors.white,
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
            textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme).apply(
              bodyColor: const Color(0xFF18314F),
              displayColor: const Color(0xFF18314F),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: const Color(0xFF18314F),
              headerForegroundColor: Colors.white,
              weekdayStyle: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF18314F),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              dayStyle: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF18314F),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return const Color(0xFF18314F);
              }),
              todayForegroundColor: WidgetStateProperty.all(const Color(0xFF10B981)),
              todayBorder: const BorderSide(color: Color(0xFF10B981), width: 1.5),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    } else {
      setState(() {
        _startDate = null;
        _endDate = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedRequest != null) {
      return _buildAllocationView(_selectedRequest!);
    }

    List<Map<String, dynamic>> requestsToDisplay = [];
    if (_selectedTab == 0) {
      // ALL REQUESTS (Pending only)
      requestsToDisplay = widget.pendingRequests.where((req) {
        final st = (req['status'] as String? ?? 'Pending').toLowerCase();
        if (st != 'pending') return false;
        return _matchesDateFilter(req);
      }).toList();
    } else {
      // HISTORICAL (Approved / Rejected / Completed)
      requestsToDisplay = widget.pendingRequests.where((req) {
        final st = (req['status'] as String? ?? '').toLowerCase();
        if (st == 'pending' || st.isEmpty) return false;
        return _matchesDateFilter(req);
      }).toList();
    }

    return Column(
      children: [
        // Header Tab Navigation Bar
        Container(
          height: 48,
          color: Colors.white,
          child: Row(
            children: [
              // ALL REQUESTS tab
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedTab = 0),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedTab == 0 ? const Color(0xFF34D399) : Colors.transparent,
                          width: 3.5,
                        ),
                      ),
                    ),
                    child: Text(
                      'ALL REQUESTS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: _selectedTab == 0 ? const Color(0xFF18314F) : const Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                ),
              ),
              // HISTORICAL tab
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedTab = 1),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedTab == 1 ? const Color(0xFF34D399) : Colors.transparent,
                          width: 3.5,
                        ),
                      ),
                    ),
                    child: Text(
                      'HISTORICAL',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: _selectedTab == 1 ? const Color(0xFF18314F) : const Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                ),
              ),
              // FILTER button
              InkWell(
                onTap: _showFilterModal,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: double.infinity,
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 16,
                        color: (_startDate != null && _endDate != null) ? const Color(0xFF059669) : const Color(0xFF8E8E93),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (_startDate != null && _endDate != null)
                            ? 'FILTER (${_startDate!.month.toString().padLeft(2, '0')}/${_startDate!.day.toString().padLeft(2, '0')} - ${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.day.toString().padLeft(2, '0')})'
                            : 'FILTER',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: (_startDate != null && _endDate != null) ? const Color(0xFF059669) : const Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // List of Request Cards
        Expanded(
          child: requestsToDisplay.isEmpty
              ? CashierEmptyState(
                  message: _selectedTab == 0
                      ? 'Walang nakabinbing feed requests sa kasalukuyan'
                      : 'Walang historical requests sa kasalukuyan',
                  icon: Icons.assignment_outlined,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: requestsToDisplay.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final req = requestsToDisplay[index];
                    return _selectedTab == 0 ? _buildRequestCard(req) : _buildHistoricalCard(req);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final raiserName = (request['raiser'] as Map?)?['name'] as String? ??
        (request['hog_raisers'] as Map?)?['name'] as String? ??
        request['raiser_name'] as String? ??
        'Hog Raiser';

    final itemsList = request['items'] as List<dynamic>?;

    List<Map<String, dynamic>> items = [];
    if (itemsList != null && itemsList.isNotEmpty) {
      items = itemsList.map((i) => Map<String, dynamic>.from(i as Map)).toList();
    } else {
      final pName = (request['product'] as Map?)?['name'] as String? ??
          (request['products'] as Map?)?['name'] as String? ??
          request['feed_type'] as String? ??
          request['category'] as String? ??
          'Feed Supply';
      final qty = request['quantity'] as int? ?? 1;
      items = [{'name': pName, 'quantity': qty}];
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Raiser Name Header
          Text(
            raiserName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF18314F),
            ),
          ),
          const SizedBox(height: 12),

          // Requested Feed Items Breakdown
          ...items.map((item) {
            final pName = item['name'] as String? ?? 'Feeds';
            final int pQty = item['quantity'] as int? ?? 1;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    pName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFFF6565),
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$pQty ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF18314F),
                          ),
                        ),
                        TextSpan(
                          text: 'Sacks',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),

          // Allocate Feeds Action Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _openAllocationView(request),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A80F6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'ALLOCATE FEEDS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalCard(Map<String, dynamic> request) {
    final raiserName = (request['raiser'] as Map?)?['name'] as String? ??
        (request['hog_raisers'] as Map?)?['name'] as String? ??
        request['raiser_name'] as String? ??
        'Hog Raiser';
    final status = (request['status'] as String? ?? 'Approved');
    final isApproved = status.toLowerCase() == 'approved';
    final decisionDate = request['decision_date'] as String? ?? _getTimeAgo(request['created_at'] as String?);

    final itemsList = request['items'] as List<dynamic>?;
    List<Map<String, dynamic>> items = [];
    if (itemsList != null && itemsList.isNotEmpty) {
      items = itemsList.map((i) => Map<String, dynamic>.from(i as Map)).toList();
    } else {
      final pName = (request['product'] as Map?)?['name'] as String? ??
          (request['products'] as Map?)?['name'] as String? ??
          request['feed_type'] as String? ??
          request['category'] as String? ??
          'Feed Supply';
      final qty = request['quantity'] as int? ?? 1;
      items = [{'name': pName, 'quantity': qty}];
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF18314F),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isApproved ? const Color(0xFFE6F4EA) : const Color(0xFFFCE8E6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isApproved ? const Color(0xFF137333) : const Color(0xFFC5221F),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            final pName = item['name'] as String? ?? 'Feeds';
            final int pQty = item['quantity'] as int? ?? 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    pName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4C6FFF),
                    ),
                  ),
                  Text(
                    '$pQty Sacks',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF18314F),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.history, size: 14, color: Color(0xFF8E8E93)),
              const SizedBox(width: 4),
              Text(
                decisionDate,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationView(Map<String, dynamic> request) {
    final requestId = request['request_id'] as int;
    final raiserName = request['raiser']?['name'] as String? ?? 'John Dela Cruz';
    final productName = request['product']?['name'] as String? ?? 'Booster';
    final int requestedQty = request['quantity'] as int? ?? 1;
    final String timeAgo = _getTimeAgo(request['created_at'] as String?);

    // Calculate live inventory stock
    int totalAvailableStock = 420;
    if (widget.allProducts.isNotEmpty) {
      totalAvailableStock = widget.allProducts.fold(0, (sum, p) => sum + p.units);
    }
    final int warehouseA = (totalAvailableStock * 0.67).round();
    final int warehouseB = totalAvailableStock - warehouseA;

    final double equivalentKg = _allocatedSacks * 25.0; // 25kg per sack

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Subheader row with back arrow
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF18314F)),
                onPressed: _closeAllocationView,
              ),
              Text(
                'Feed Allocation',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF18314F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Raiser Request Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PiggyTrunkTheme.ptBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Raiser Request',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: PiggyTrunkTheme.ptMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        raiserName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF18314F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            productName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$requestedQty ',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF18314F),
                                  ),
                                ),
                                TextSpan(
                                  text: 'Sacks',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: PiggyTrunkTheme.ptMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: PiggyTrunkTheme.ptMuted),
                      const SizedBox(width: 6),
                      Text(
                        timeAgo,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: PiggyTrunkTheme.ptMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Current Stock Availability Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PiggyTrunkTheme.ptBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CURRENT STOCK AVAILABILITY',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: PiggyTrunkTheme.ptMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '$totalAvailableStock Sacks',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: totalAvailableStock > 0 ? (totalAvailableStock / 500).clamp(0.0, 1.0) : 0.0,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: const Color(0xFF059669),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Warehouse A: $warehouseA Sacks',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PiggyTrunkTheme.ptMuted,
                      ),
                    ),
                    Text(
                      'Warehouse B: $warehouseB Sacks',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PiggyTrunkTheme.ptMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Stepper & KG Calculator Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PiggyTrunkTheme.ptBorder, width: 1),
            ),
            child: Row(
              children: [
                // Amount (Sacks) Stepper
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount (Sacks)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: PiggyTrunkTheme.ptMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18, color: Color(0xFF991B1B)),
                              onPressed: () {
                                if (_allocatedSacks > 1) {
                                  setState(() => _allocatedSacks--);
                                }
                              },
                            ),
                            Text(
                              '$_allocatedSacks',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF18314F),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18, color: Color(0xFF991B1B)),
                              onPressed: () {
                                setState(() => _allocatedSacks++);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Equivalent (KG) Box
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Equivalent (KG)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: PiggyTrunkTheme.ptMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.scale_outlined, size: 18, color: Color(0xFF18314F)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${equivalentKg.toStringAsFixed(2)} kg',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF18314F),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Action Buttons: Confirm Allocation & Cancel
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                final prodId = request['product']?['id'] as int?;
                _closeAllocationView();
                await widget.onProcessRequest(
                  requestId,
                  'Approved',
                  allocatedSacks: _allocatedSacks,
                  productId: prodId,
                );
              },
              icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              label: Text(
                'Confirm Allocation',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38A169),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: _closeAllocationView,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFC04F5E), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFC04F5E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
