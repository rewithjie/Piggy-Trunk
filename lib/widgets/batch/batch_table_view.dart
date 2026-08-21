import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';

class BatchTableView extends StatelessWidget {
  final List<Map<String, dynamic>> batches;
  final String searchQuery;
  final String selectedStatusFilter;
  final String? errorMessage;
  final VoidCallback? onRefresh;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onCreateBatch;
  final void Function(Map<String, dynamic> batch) onViewDetails;
  final void Function(Map<String, dynamic> batch) onEditBatch;
  final void Function(Map<String, dynamic> batch) onArchiveBatch;
  final void Function(Map<String, dynamic> batch) onDeleteBatch;

  const BatchTableView({
    super.key,
    required this.batches,
    required this.searchQuery,
    required this.selectedStatusFilter,
    this.errorMessage,
    this.onRefresh,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onCreateBatch,
    required this.onViewDetails,
    required this.onEditBatch,
    required this.onArchiveBatch,
    required this.onDeleteBatch,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    final cardBg = isDark ? const Color(0xFF132238) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
    final titleColor = isDark ? Colors.white : const Color(0xFF18314F);
    final headerText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF4B6281);
    final fieldBg = isDark ? const Color(0xFF1A2B44) : const Color(0xFFF5F8FE);
    final fieldBorder = isDark ? const Color(0xFF28405D) : const Color(0xFFC9D8EC);
    final fieldFocus = isDark ? const Color(0xFF88A7CE) : const Color(0xFF315C8F);
    final fieldText = isDark ? Colors.white : const Color(0xFF18314F);
    final hintText = isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);

    final totalBatches = batches.length;
    final activeBatches = batches.where((b) => (b['status'] ?? '').toString().toUpperCase() == 'ACTIVE').length;
    final assignedBatches = batches.where((b) => b['raiser_id'] != null && b['raiser_id'].toString() != 'unassigned').length;
    final unassignedBatches = batches.where((b) => b['raiser_id'] == null || b['raiser_id'].toString() == 'unassigned').length;

    final filteredBatches = batches.where((b) {
      final status = (b['status'] ?? 'ACTIVE').toString().toUpperCase();
      if (selectedStatusFilter != 'ALL' && status != selectedStatusFilter) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final name = (b['batch_name'] ?? '').toString().toLowerCase();
        final raiser = (b['raiser_name'] ?? '').toString().toLowerCase();
        if (!name.contains(q) && !raiser.contains(q)) return false;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metric Overview Cards
        _buildMetricsRow(totalBatches, activeBatches, assignedBatches, unassignedBatches, isMobile, isDark),
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
              // Header & Action Row
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Batch Management',
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
                        onPressed: onCreateBatch,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: Text(
                          'Create Batch',
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
                          'Batch Management',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                            letterSpacing: -0.04,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create and assign batches to active authorized raisers',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: headerText),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: onCreateBatch,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text(
                        'Create Batch',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: _primaryButtonStyle(minWidth: 160, isDark: isDark),
                    ),
                  ],
                ),
              const SizedBox(height: 20),

              // Search and Filters
              _buildSearchAndFilters(isMobile, isDark, fieldBg, fieldBorder, fieldFocus, fieldText, hintText),
              const SizedBox(height: 16),

              // Responsive Table / Card Layout
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
                          if (filteredBatches.isEmpty)
                            Container(
                              width: tableWidth,
                              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: cardBorder.withValues(alpha: 0.7))),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'No batches found matching criteria.',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: titleColor),
                                    ),
                                    if (errorMessage != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        errorMessage!,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.red),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                          else
                            ...List.generate(
                              filteredBatches.length,
                              (index) => _buildTableRow(filteredBatches[index], index, isDark, cardBorder, titleColor, hintText),
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

  Widget _buildMetricsRow(int total, int active, int assigned, int unassigned, bool isMobile, bool isDark) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricCard('Total Batches', '$total', Icons.layers_rounded, isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary, isDark)),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricCard('Active Batches', '$active', Icons.check_circle_rounded, PiggyTrunkTheme.ptSuccess, isDark)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildMetricCard('Assigned Batches', '$assigned', Icons.people_outline_rounded, const Color(0xFFFFAA00), isDark)),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricCard('Unassigned', '$unassigned', Icons.pending_outlined, const Color(0xFFF43F5E), isDark)),
            ],
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: _buildMetricCard('Total Batches', '$total', Icons.layers_rounded, isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary, isDark)),
        const SizedBox(width: 14),
        Expanded(child: _buildMetricCard('Active Batches', '$active', Icons.check_circle_rounded, PiggyTrunkTheme.ptSuccess, isDark)),
        const SizedBox(width: 14),
        Expanded(child: _buildMetricCard('Assigned Batches', '$assigned', Icons.people_outline_rounded, const Color(0xFFFFAA00), isDark)),
        const SizedBox(width: 14),
        Expanded(child: _buildMetricCard('Unassigned', '$unassigned', Icons.pending_outlined, const Color(0xFFF43F5E), isDark)),
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
      onChanged: onSearchChanged,
      style: GoogleFonts.plusJakartaSans(color: fieldText, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search by batch name, code, or raiser...',
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

    final filterPills = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterPill('ALL', 'All Batches', isDark),
          const SizedBox(width: 8),
          _buildFilterPill('ACTIVE', 'Active', isDark),
          const SizedBox(width: 8),
          _buildFilterPill('COMPLETED', 'Completed', isDark),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          searchField,
          const SizedBox(height: 12),
          filterPills,
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: searchField),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: filterPills),
        if (onRefresh != null) ...[
          const SizedBox(width: 10),
          IconButton(
            onPressed: onRefresh,
            icon: Icon(Icons.refresh_rounded, color: fieldFocus),
            tooltip: 'Refresh Batches',
          ),
        ],
      ],
    );
  }

  Widget _buildFilterPill(String value, String label, bool isDark) {
    final isSelected = selectedStatusFilter == value;
    final activeBg = isDark ? Colors.white : PiggyTrunkTheme.ptPrimary;
    final unselectedBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final unselectedBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final unselectedTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return InkWell(
      onTap: () => onFilterChanged(value),
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
          Expanded(flex: 3, child: Text('BATCH NAME / CODE', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: hintText))),
          Expanded(flex: 3, child: Text('ASSIGNED RAISER', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: hintText))),
          Expanded(flex: 2, child: Text('DATE CREATED', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: hintText))),
          Expanded(flex: 2, child: Text('STATUS', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: hintText))),
          Expanded(flex: 2, child: Text('ACTIONS', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: hintText))),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> batch, int index, bool isDark, Color cardBorder, Color titleColor, Color hintText) {
    final batchName = batch['batch_name']?.toString() ?? 'Batch';
    final raiserName = batch['raiser_name']?.toString() ?? 'Unassigned';
    final dateCreated = batch['date_created']?.toString() ?? 'N/A';
    final status = batch['status']?.toString().toUpperCase() ?? 'ACTIVE';

    Color statusBg;
    Color statusFg;
    if (status == 'ACTIVE') {
      statusBg = const Color(0x3343CB89);
      statusFg = const Color(0xFF43CB89);
    } else if (status == 'COMPLETED' || status == 'HARVESTED') {
      statusBg = const Color(0x333B82F6);
      statusFg = const Color(0xFF3B82F6);
    } else {
      statusBg = const Color(0x3394A3B8);
      statusFg = const Color(0xFF94A3B8);
    }

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
            child: Text(batchName, style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: titleColor)),
          ),
          Expanded(
            flex: 3,
            child: Text(raiserName, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: titleColor)),
          ),
          Expanded(
            flex: 2,
            child: Text(dateCreated, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w500, color: hintText)),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                child: Text(status, style: GoogleFonts.plusJakartaSans(color: statusFg, fontSize: 10.5, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.visibility_outlined,
                    size: 18,
                    color: isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary,
                  ),
                  tooltip: 'View Details',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => onViewDetails(batch),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: isDark ? const Color(0xFF9AB1CB) : const Color(0xFF4B6281),
                  ),
                  tooltip: 'Edit Batch',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => onEditBatch(batch),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Color(0xFFFF758C),
                  ),
                  tooltip: 'Delete Batch',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => onDeleteBatch(batch),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _primaryButtonStyle({required double minWidth, required bool isDark}) {
    return ElevatedButton.styleFrom(
      backgroundColor: isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
      foregroundColor: isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      minimumSize: Size(minWidth, 44),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
