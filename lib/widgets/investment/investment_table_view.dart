import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/investment_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import 'investment_detail_modal.dart';

class InvestmentTableView extends StatefulWidget {
  final List<Investment> investments;
  final List<Map<String, dynamic>> partnerInvestments;
  final String? initialViewMode;
  final VoidCallback onAddInvestment;
  final void Function(Investment item) onEditInvestment;
  final void Function(Investment item) onArchiveInvestment;
  final void Function(Investment item) onDeleteInvestment;
  final void Function(int investmentId)? onApprovePartnerInvestment;
  final void Function(int investmentId)? onRejectPartnerInvestment;

  const InvestmentTableView({
    super.key,
    required this.investments,
    this.partnerInvestments = const [],
    this.initialViewMode,
    required this.onAddInvestment,
    required this.onEditInvestment,
    required this.onArchiveInvestment,
    required this.onDeleteInvestment,
    this.onApprovePartnerInvestment,
    this.onRejectPartnerInvestment,
  });

  @override
  State<InvestmentTableView> createState() => _InvestmentTableViewState();
}

class _InvestmentTableViewState extends State<InvestmentTableView> {
  final TextEditingController _searchCtrl = TextEditingController();
  late String _viewMode;
  String _selectedStageFilter = 'ALL';
  final String _selectedTypeFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _viewMode = widget.initialViewMode ??
        (widget.partnerInvestments.any((p) => (p['status'] ?? '').toString().toLowerCase() == 'pending')
            ? 'PARTNER'
            : 'DIRECT');
  }

  @override
  void didUpdateWidget(covariant InvestmentTableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialViewMode != null && widget.initialViewMode != oldWidget.initialViewMode) {
      _viewMode = widget.initialViewMode!;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(0);
    final formatted = parts.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '₱$formatted';
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthName = months[date.month - 1];
    return '$monthName ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    final cardBg = isDark ? const Color(0xFF132238) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
    final titleColor = isDark ? Colors.white : const Color(0xFF18314F);
    final headerText = isDark ? const Color(0xFF9EC0E8) : const Color(0xFF4B6281);
    final fieldBg = isDark ? const Color(0xFF1A2B44) : const Color(0xFFF5F8FE);
    final fieldBorder = isDark ? const Color(0xFF28405D) : const Color(0xFFC9D8EC);
    final fieldFocus = isDark ? const Color(0xFF88A7CE) : const Color(0xFF315C8F);
    final fieldText = isDark ? Colors.white : const Color(0xFF18314F);
    final hintText = isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);

    final totalCapital = widget.investments.fold<double>(0.0, (sum, i) => sum + i.initialCapital);
    final totalStocksSpend = widget.investments.fold<double>(0.0, (sum, i) => sum + i.stocksValue);
    final totalHogs = widget.investments.fold<int>(0, (sum, i) => sum + i.totalHog);
    final activeCount = widget.investments.where((i) => i.stage.toLowerCase() != 'archived' && i.stage.toLowerCase() != 'completed').length;
    final pendingPartnerCount = widget.partnerInvestments.where((p) => (p['status'] ?? '').toString().toLowerCase() == 'pending').length;

    // Filter Direct Investments
    final filteredDirect = widget.investments.where((inv) {
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final name = inv.raiserName.toLowerCase();
        final type = inv.hogType.toLowerCase();
        final batch = (inv.batchName ?? '').toLowerCase();
        if (!name.contains(q) && !type.contains(q) && !batch.contains(q)) return false;
      }
      if (_selectedStageFilter != 'ALL') {
        if (inv.stage.toUpperCase() != _selectedStageFilter) return false;
      }
      if (_selectedTypeFilter != 'ALL') {
        if (!inv.hogType.toLowerCase().contains(_selectedTypeFilter.toLowerCase())) return false;
      }
      return true;
    }).toList();

    // Filter Partner Investments
    final filteredPartner = widget.partnerInvestments.where((p) {
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final pName = (p['partner_name'] ?? '').toString().toLowerCase();
        final bName = (p['batch_name'] ?? '').toString().toLowerCase();
        if (!pName.contains(q) && !bName.contains(q)) return false;
      }
      if (_selectedStageFilter != 'ALL') {
        final st = (p['status'] ?? 'pending').toString().toUpperCase();
        if (st != _selectedStageFilter) return false;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Metric Cards
        _buildMetricsRow(totalCapital, totalStocksSpend, totalHogs, activeCount, pendingPartnerCount, isMobile, isDark),
        const SizedBox(height: 24),

        // Main Table Card
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            border: Border.all(color: cardBorder, width: 1),
            borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
          ),
          padding: EdgeInsets.all(isMobile ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Investment Management',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        letterSpacing: -0.04,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.onAddInvestment,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: Text(
                          'Add Investment',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        style: _primaryButtonStyle(minWidth: 0, isDark: isDark),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Investment Management',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                            letterSpacing: -0.04,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Track capital investments, partner approvals, and lifecycle performance',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: headerText),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: widget.onAddInvestment,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text(
                        'Add Investment',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: _primaryButtonStyle(minWidth: 160, isDark: isDark),
                    ),
                  ],
                ),
              const SizedBox(height: 20),

              // View Mode Selector (Direct Allocations vs Partner Requests)
              _buildViewModeToggle(pendingPartnerCount, isDark, isMobile),
              const SizedBox(height: 16),

              // Search & Filters
              _buildSearchAndFilters(isMobile, isDark, fieldBg, fieldBorder, fieldFocus, fieldText, hintText),
              const SizedBox(height: 16),

              // Table Content
              LayoutBuilder(
                builder: (context, constraints) {
                  final tableWidth = constraints.maxWidth > 950 ? constraints.maxWidth : 950.0;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_viewMode == 'DIRECT') ...[
                            _buildTableHeader(isDark, cardBorder, hintText),
                            if (filteredDirect.isEmpty)
                              _buildEmptyPlaceholder(tableWidth, cardBorder, titleColor, _getDirectEmptyMessage())
                            else
                              ...List.generate(
                                filteredDirect.length,
                                (index) => _buildTableRow(filteredDirect[index], index, isDark, cardBorder, titleColor, hintText),
                              ),
                          ] else ...[
                            _buildPartnerTableHeader(isDark, cardBorder, hintText),
                            if (filteredPartner.isEmpty)
                              _buildEmptyPlaceholder(tableWidth, cardBorder, titleColor, _getPartnerEmptyMessage())
                            else
                              ...List.generate(
                                filteredPartner.length,
                                (index) => _buildPartnerTableRow(filteredPartner[index], index, isDark, cardBorder, titleColor, hintText),
                              ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDirectEmptyMessage() {
    final query = _searchCtrl.text.trim();
    if (query.isNotEmpty) {
      return 'No investments matching "$query" found.';
    }
    switch (_selectedStageFilter) {
      case 'PENDING':
        return 'No pending investments found.';
      case 'ACTIVE':
        return 'No active investments found.';
      case 'COMPLETED':
        return 'No completed investments found.';
      case 'ARCHIVED':
        return 'No archived investments found.';
      default:
        return 'No direct investments found.';
    }
  }

  String _getPartnerEmptyMessage() {
    final query = _searchCtrl.text.trim();
    if (query.isNotEmpty) {
      return 'No partner investments matching "$query" found.';
    }
    switch (_selectedStageFilter) {
      case 'PENDING':
        return 'No pending partner investments found.';
      case 'ACTIVE':
        return 'No active partner investments found.';
      case 'COMPLETED':
        return 'No completed partner investments found.';
      case 'ARCHIVED':
        return 'No archived partner investments found.';
      default:
        return 'No partner investments found.';
    }
  }

  Widget _buildEmptyPlaceholder(double tableWidth, Color cardBorder, Color titleColor, String message) {
    return Container(
      width: tableWidth,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cardBorder.withValues(alpha: 0.7))),
      ),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: titleColor),
        ),
      ),
    );
  }

  Widget _buildViewModeToggle(int pendingCount, bool isDark, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : null,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16253B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF28405D) : const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
        children: [
          isMobile
              ? Expanded(
                  child: _buildToggleTab(
                    label: 'Direct Allocations',
                    count: widget.investments.length,
                    isSelected: _viewMode == 'DIRECT',
                    onTap: () => setState(() => _viewMode = 'DIRECT'),
                    isDark: isDark,
                    isMobile: isMobile,
                  ),
                )
              : _buildToggleTab(
                  label: 'Direct Allocations',
                  count: widget.investments.length,
                  isSelected: _viewMode == 'DIRECT',
                  onTap: () => setState(() => _viewMode = 'DIRECT'),
                  isDark: isDark,
                  isMobile: isMobile,
                ),
          const SizedBox(width: 4),
          isMobile
              ? Expanded(
                  child: _buildToggleTab(
                    label: 'Partner Investments',
                    count: widget.partnerInvestments.length,
                    isSelected: _viewMode == 'PARTNER',
                    onTap: () => setState(() => _viewMode = 'PARTNER'),
                    isDark: isDark,
                    isMobile: isMobile,
                  ),
                )
              : _buildToggleTab(
                  label: 'Partner Investments',
                  count: widget.partnerInvestments.length,
                  isSelected: _viewMode == 'PARTNER',
                  onTap: () => setState(() => _viewMode = 'PARTNER'),
                  isDark: isDark,
                  isMobile: isMobile,
                ),
        ],
      ),
    );
  }

  Widget _buildToggleTab({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required bool isMobile,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 18,
          vertical: isMobile ? 9 : 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF243B5B) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF18314F))
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? const Color(0xFF60A5FA).withValues(alpha: 0.2)
                        : PiggyTrunkTheme.ptPrimary.withValues(alpha: 0.1))
                    : (isDark
                        ? const Color(0xFF28405D).withValues(alpha: 0.5)
                        : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 10.5 : 11.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? (isDark ? const Color(0xFF93C5FD) : PiggyTrunkTheme.ptPrimary)
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow(double capital, double stocksSpend, int totalHogs, int activeCount, int pendingCount, bool isMobile, bool isDark) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricCard('Total Capital', _formatCurrency(capital), Icons.monetization_on_rounded, isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary, isDark, isMobile)),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricCard('Stocks Spend', _formatCurrency(stocksSpend), Icons.inventory_2_rounded, const Color(0xFF38BDF8), isDark, isMobile)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildMetricCard('Total Heads', '$totalHogs heads', Icons.pets_rounded, const Color(0xFFFFAA00), isDark, isMobile)),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricCard('Active Allocations', '$activeCount active', Icons.check_circle_rounded, PiggyTrunkTheme.ptSuccess, isDark, isMobile)),
            ],
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: _buildMetricCard('Total Capital', _formatCurrency(capital), Icons.monetization_on_rounded, isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary, isDark, isMobile)),
        const SizedBox(width: 14),
        Expanded(child: _buildMetricCard('Stocks Spend', _formatCurrency(stocksSpend), Icons.inventory_2_rounded, const Color(0xFF38BDF8), isDark, isMobile)),
        const SizedBox(width: 14),
        Expanded(child: _buildMetricCard('Total Heads', '$totalHogs heads', Icons.pets_rounded, const Color(0xFFFFAA00), isDark, isMobile)),
        const SizedBox(width: 14),
        Expanded(child: _buildMetricCard('Active Allocations', '$activeCount active', Icons.check_circle_rounded, PiggyTrunkTheme.ptSuccess, isDark, isMobile)),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, bool isDark, bool isMobile) {
    final cardBg = isDark ? const Color(0xFF132238) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
    final titleColor = isDark ? Colors.white : const Color(0xFF18314F);
    final hintText = isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: cardBorder, width: 1),
        borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
      ),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 12 : 14),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: isMobile ? 18 : 22),
          ),
          SizedBox(width: isMobile ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: hintText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 15 : 18,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isMobile, bool isDark, Color fieldBg, Color fieldBorder, Color fieldFocus, Color fieldText, Color hintText) {
    final searchField = TextField(
      controller: _searchCtrl,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: fieldText, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: 'Search by raiser, batch, or hog type...',
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: hintText),
        prefixIcon: Icon(Icons.search_rounded, size: 20, color: hintText),
        filled: true,
        fillColor: fieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: fieldBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: fieldBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: fieldFocus, width: 1.5)),
      ),
    );

    final filterButtons = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('ALL', 'All Stages', isDark),
          const SizedBox(width: 8),
          _buildFilterChip('PENDING', 'Pending', isDark),
          const SizedBox(width: 8),
          _buildFilterChip('ACTIVE', 'Active', isDark),
          const SizedBox(width: 8),
          _buildFilterChip('COMPLETED', 'Completed', isDark),
          const SizedBox(width: 8),
          _buildFilterChip('ARCHIVED', 'Archived', isDark),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 12),
          filterButtons,
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: searchField),
        const SizedBox(width: 14),
        filterButtons,
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, bool isDark) {
    final isSelected = _selectedStageFilter == value;
    final activeBg = isDark ? Colors.white : PiggyTrunkTheme.ptPrimary;
    final unselectedBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final unselectedBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final unselectedTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return InkWell(
      onTap: () => setState(() => _selectedStageFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : unselectedBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? activeBg : unselectedBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected ? (isDark ? PiggyTrunkTheme.ptPrimary : Colors.white) : unselectedTextColor,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  // DIRECT ALLOCATIONS TABLE
  Widget _buildTableHeader(bool isDark, Color cardBorder, Color hintText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2E48) : const Color(0xFFEDF4FC),
        border: Border(bottom: BorderSide(color: cardBorder, width: 1.2)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('HOG RAISER', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: hintText))),
          Expanded(flex: 3, child: Text('BATCH ASSIGN', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: hintText))),
          Expanded(flex: 2, child: Text('CAPITAL', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: hintText))),
          Expanded(flex: 2, child: Text('STOCKS SPEND', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: hintText))),
          Expanded(flex: 2, child: Text('HOG TYPE', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: hintText))),
          Expanded(flex: 2, child: Center(child: Text('HEADS', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: hintText)))),
          Expanded(flex: 2, child: Center(child: Text('DATE', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: hintText)))),
          Expanded(flex: 2, child: Center(child: Text('ACTIONS', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: hintText)))),
        ],
      ),
    );
  }

  Widget _buildTableRow(Investment inv, int index, bool isDark, Color cardBorder, Color titleColor, Color hintText) {
    final batchName = (inv.batchName != null && inv.batchName!.isNotEmpty) ? inv.batchName! : 'Unassigned';
    final hasBatch = batchName != 'Unassigned' && batchName != 'No Batch';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cardBorder.withValues(alpha: 0.5))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(inv.raiserName, style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: titleColor)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              batchName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hasBatch
                    ? (isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary)
                    : hintText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(_formatCurrency(inv.initialCapital), style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF43CB89))),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatCurrency(inv.stocksValue),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: inv.stocksValue > 0
                    ? (isDark ? const Color(0xFF38BDF8) : PiggyTrunkTheme.ptPrimary)
                    : hintText,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(inv.hogType, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: titleColor)),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text('${inv.totalHog} heads', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: titleColor)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(_formatDate(inv.investmentDate), style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w500, color: hintText)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: InkWell(
                onTap: () => InvestmentDetailModal.show(context: context, investment: inv),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : PiggyTrunkTheme.ptPrimary).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (isDark ? Colors.white : PiggyTrunkTheme.ptPrimary).withValues(alpha: 0.22),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Details',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // PARTNER INVESTMENTS TABLE
  Widget _buildPartnerTableHeader(bool isDark, Color cardBorder, Color hintText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2E48) : const Color(0xFFEDF4FC),
        border: Border(bottom: BorderSide(color: cardBorder, width: 1.2)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('PARTNER INVESTOR', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: hintText))),
          Expanded(flex: 3, child: Text('BATCH NAME', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: hintText))),
          Expanded(flex: 2, child: Text('AMOUNT', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: hintText))),
          Expanded(flex: 2, child: Text('DATE', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: hintText))),
          Expanded(flex: 2, child: Text('STATUS', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: hintText))),
        ],
      ),
    );
  }

  Widget _buildPartnerTableRow(Map<String, dynamic> p, int index, bool isDark, Color cardBorder, Color titleColor, Color hintText) {
    final status = (p['status'] ?? 'active').toString().toLowerCase();
    final isActive = status == 'active' || status == 'approved';
    final isPending = status == 'pending';

    final double amt = (p['amount'] as num?)?.toDouble() ?? 0.0;
    final dateStr = p['date_invested']?.toString() ?? '';
    final dt = DateTime.tryParse(dateStr) ?? DateTime.now();
    final rawInvId = p['investment_id'] ?? p['id'];
    final investmentId = rawInvId is int ? rawInvId : int.tryParse(rawInvId?.toString() ?? '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cardBorder.withValues(alpha: 0.5))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              p['partner_name'] ?? 'Partner Investor',
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: titleColor),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              p['batch_name'] ?? 'Batch #${p['batch_id']}',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: titleColor),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatCurrency(amt),
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF43CB89)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(dt),
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w500, color: hintText),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : isPending
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                            : const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF10B981).withValues(alpha: 0.4)
                          : isPending
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                              : const Color(0xFFEF4444).withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive
                            ? Icons.check_circle_rounded
                            : isPending
                                ? Icons.hourglass_top_rounded
                                : Icons.cancel_rounded,
                        size: 13,
                        color: isActive
                            ? const Color(0xFF10B981)
                            : isPending
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isActive ? 'ACTIVE' : status.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: isActive
                              ? const Color(0xFF10B981)
                              : isPending
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPending && investmentId != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => widget.onApprovePartnerInvestment?.call(investmentId),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 13, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          Text(
                            'Approve',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => widget.onRejectPartnerInvestment?.call(investmentId),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF758C).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFFF758C).withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cancel_outlined, size: 13, color: Color(0xFFFF758C)),
                          const SizedBox(width: 4),
                          Text(
                            'Decline',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFF758C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _primaryButtonStyle({double minWidth = 140, required bool isDark}) {
    return ElevatedButton.styleFrom(
      backgroundColor: isDark ? PiggyTrunkTheme.ptSurface : PiggyTrunkTheme.ptPrimary,
      foregroundColor: isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 0,
      minimumSize: Size(minWidth, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
