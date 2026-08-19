import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/investment_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';

class InvestmentTableView extends StatefulWidget {
  final List<Investment> investments;
  final VoidCallback onAddInvestment;
  final void Function(Investment item) onEditInvestment;
  final void Function(Investment item) onArchiveInvestment;
  final void Function(Investment item) onDeleteInvestment;

  const InvestmentTableView({
    super.key,
    required this.investments,
    required this.onAddInvestment,
    required this.onEditInvestment,
    required this.onArchiveInvestment,
    required this.onDeleteInvestment,
  });

  @override
  State<InvestmentTableView> createState() => _InvestmentTableViewState();
}

class _InvestmentTableViewState extends State<InvestmentTableView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedStageFilter = 'ALL';
  final String _selectedTypeFilter = 'ALL';

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
    final totalHogs = widget.investments.fold<int>(0, (sum, i) => sum + i.totalHog);
    final activeCount = widget.investments.where((i) => i.stage.toLowerCase() != 'archived' && i.stage.toLowerCase() != 'completed').length;

    final filtered = widget.investments.where((inv) {
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final name = inv.raiserName.toLowerCase();
        final type = inv.hogType.toLowerCase();
        if (!name.contains(q) && !type.contains(q)) return false;
      }
      if (_selectedStageFilter != 'ALL') {
        if (inv.stage.toUpperCase() != _selectedStageFilter) return false;
      }
      if (_selectedTypeFilter != 'ALL') {
        if (!inv.hogType.toLowerCase().contains(_selectedTypeFilter.toLowerCase())) return false;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Metric Cards
        _buildMetricsRow(totalCapital, totalHogs, activeCount, isMobile, isDark),
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
                          'Track capital investments, raiser allocation, and lifecycle performance',
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

              // Search & Filters
              _buildSearchAndFilters(isMobile, isDark, fieldBg, fieldBorder, fieldFocus, fieldText, hintText),
              const SizedBox(height: 16),

              // Table
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
                          _buildTableHeader(isDark, cardBorder, hintText),
                          if (filtered.isEmpty)
                            Container(
                              width: tableWidth,
                              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: cardBorder.withValues(alpha: 0.7))),
                              ),
                              child: Center(
                                child: Text(
                                  'No investments found matching criteria.',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: titleColor),
                                ),
                              ),
                            )
                          else
                            ...List.generate(
                              filtered.length,
                              (index) => _buildTableRow(filtered[index], index, isDark, cardBorder, titleColor, hintText),
                            ),
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

  Widget _buildMetricsRow(double capital, int totalHogs, int activeCount, bool isMobile, bool isDark) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricCard('Total Capital', _formatCurrency(capital), Icons.monetization_on_rounded, isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary, isDark)),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricCard('Total Heads', '$totalHogs heads', Icons.pets_rounded, const Color(0xFFFFAA00), isDark)),
            ],
          ),
          const SizedBox(height: 10),
          _buildMetricCard('Active Allocations', '$activeCount active', Icons.check_circle_rounded, PiggyTrunkTheme.ptSuccess, isDark),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: _buildMetricCard('Total Capital', _formatCurrency(capital), Icons.monetization_on_rounded, isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary, isDark)),
        const SizedBox(width: 14),
        Expanded(child: _buildMetricCard('Total Heads', '$totalHogs heads', Icons.pets_rounded, const Color(0xFFFFAA00), isDark)),
        const SizedBox(width: 14),
        Expanded(child: _buildMetricCard('Active Allocations', '$activeCount active', Icons.check_circle_rounded, PiggyTrunkTheme.ptSuccess, isDark)),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, bool isDark) {
    final cardBg = isDark ? const Color(0xFF132238) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
    final titleColor = isDark ? Colors.white : const Color(0xFF18314F);
    final hintText = isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: cardBorder, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hintText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
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
      style: GoogleFonts.plusJakartaSans(color: fieldText, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search by raiser name or hog type...',
        hintStyle: GoogleFonts.plusJakartaSans(color: hintText, fontSize: 14),
        prefixIcon: Icon(Icons.search_rounded, color: hintText, size: 20),
        filled: true,
        fillColor: fieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: fieldFocus, width: 1.5),
        ),
      ),
    );

    final filterButtons = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('ALL', 'All Stages', isDark),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Expanded(flex: 2, child: Text('CAPITAL', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: hintText))),
          Expanded(flex: 2, child: Text('HOG TYPE', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: hintText))),
          Expanded(flex: 2, child: Text('HEADS', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: hintText))),
          Expanded(flex: 2, child: Text('DATE', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: hintText))),
          Expanded(flex: 2, child: Text('ACTIONS', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: hintText))),
        ],
      ),
    );
  }

  Widget _buildTableRow(Investment inv, int index, bool isDark, Color cardBorder, Color titleColor, Color hintText) {
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
            flex: 2,
            child: Text(_formatCurrency(inv.initialCapital), style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF43CB89))),
          ),
          Expanded(
            flex: 2,
            child: Text(inv.hogType, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: titleColor)),
          ),
          Expanded(
            flex: 2,
            child: Text('${inv.totalHog} heads', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: titleColor)),
          ),
          Expanded(
            flex: 2,
            child: Text(_formatDate(inv.investmentDate), style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w500, color: hintText)),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 18, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF4B6281)),
                  tooltip: 'Edit investment',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => widget.onEditInvestment(inv),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.archive_outlined, size: 18, color: const Color(0xFFFF758C)),
                  tooltip: 'Archive investment',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => widget.onArchiveInvestment(inv),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, size: 18, color: const Color(0xFFFF758C)),
                  tooltip: 'Delete investment',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => widget.onDeleteInvestment(inv),
                ),
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
