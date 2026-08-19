import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';

class ActiveRaisersTab extends StatelessWidget {
  final List<Map<String, dynamic>> raisers;
  final int currentTab;
  final TextEditingController searchCtrl;
  final void Function(String value) onSearch;
  final void Function(Map<String, dynamic> row) onShowDetails;
  final void Function(Map<String, dynamic> row) onEditRaiser;
  final void Function(Map<String, dynamic> row) onArchiveRaiser;
  final void Function(Map<String, dynamic> row) onRestoreRaiser;
  final void Function(Map<String, dynamic> row) onDeleteRaiser;
  final void Function(Map<String, dynamic> row) onApproveRaiser;

  const ActiveRaisersTab({
    super.key,
    required this.raisers,
    required this.currentTab,
    required this.searchCtrl,
    required this.onSearch,
    required this.onShowDetails,
    required this.onEditRaiser,
    required this.onArchiveRaiser,
    required this.onRestoreRaiser,
    required this.onDeleteRaiser,
    required this.onApproveRaiser,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    final cardBg = isDark ? const Color(0xFF132238) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF27405F) : const Color(0xFFC6D8EF);
    final titleColor = isDark ? Colors.white : const Color(0xFF18314F);
    final fieldBg = isDark ? const Color(0xFF1A2B44) : const Color(0xFFEEF4FD);
    final fieldBorder = isDark ? const Color(0xFF28405D) : const Color(0xFFB4C9E6);
    final fieldFocus = isDark ? const Color(0xFF88A7CE) : const Color(0xFF315C8F);
    final fieldText = isDark ? const Color(0xFFE6F1FF) : const Color(0xFF18314F);
    final hintText = isDark ? const Color(0xFF8FA7C4) : const Color(0xFF5D7391);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
        border: Border.all(color: cardBorder),
      ),
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchCtrl,
                  style: AppTextStyles.body(fieldText),
                  decoration: InputDecoration(
                    hintText: 'Search raisers...',
                    hintStyle: AppTextStyles.body(hintText),
                    prefixIcon: Icon(Icons.search, color: hintText),
                    filled: true,
                    fillColor: fieldBg,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: fieldBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: fieldFocus),
                    ),
                  ),
                  onSubmitted: onSearch,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => onSearch(searchCtrl.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? PiggyTrunkTheme.ptSurface : PiggyTrunkTheme.ptPrimary,
                  foregroundColor: isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                  minimumSize: Size(isMobile ? 76 : 90, isMobile ? 44 : 48),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Search',
                  style: AppTextStyles.button(isDark ? PiggyTrunkTheme.ptPrimary : Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = constraints.maxWidth > 800 ? constraints.maxWidth : 800.0;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _tableHeader(isDark, cardBorder, hintText),
                      const SizedBox(height: 4),
                      if (raisers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 50),
                          child: Center(
                            child: Text(
                              currentTab == 0
                                  ? 'No active raisers found'
                                  : (currentTab == 1 ? 'No pending approvals' : 'No archived raisers found'),
                              style: AppTextStyles.jakarta(size: 20, weight: FontWeight.w700, color: titleColor),
                            ),
                          ),
                        )
                      else
                        ...raisers.map((r) => _tableRow(r, isDark, cardBorder, titleColor)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(bool isDark, Color cardBorder, Color hintText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2E48) : const Color(0xFFEDF4FC),
        border: Border(bottom: BorderSide(color: cardBorder, width: 1.2)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('NAME', style: AppTextStyles.tableHeader(hintText)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('ADDRESS', style: AppTextStyles.tableHeader(hintText)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('PHONE NUMBER', style: AppTextStyles.tableHeader(hintText)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('STATUS', style: AppTextStyles.tableHeader(hintText)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text('ACTIONS', style: AppTextStyles.tableHeader(hintText)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableRow(Map<String, dynamic> row, bool isDark, Color cardBorder, Color titleColor) {
    final statusVal = (row['status'] ?? '').toString().toLowerCase();
    final accStatusVal = (row['account_status'] ?? '').toString().toLowerCase();
    final isArchived = statusVal == 'archived' || accStatusVal == 'archived';
    final isPending = !isArchived && (statusVal == 'pending' || accStatusVal == 'pending');

    final String statusText = isArchived ? 'ARCHIVED' : (isPending ? 'PENDING' : 'ACTIVE');
    final Color statusColor = isArchived
        ? const Color(0xFF94A3B8)
        : (isPending ? const Color(0xFFFFAA00) : PiggyTrunkTheme.ptSuccess);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cardBorder.withValues(alpha: 0.5))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                (row['name'] ?? '').toString(),
                style: AppTextStyles.body(titleColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                (row['address'] ?? '').toString(),
                style: AppTextStyles.body(titleColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                (row['phone'] ?? '').toString(),
                style: AppTextStyles.body(titleColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: AppTextStyles.jakarta(
                      color: statusColor,
                      size: 11,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: isPending
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => onShowDetails(row),
                          icon: Icon(Icons.visibility_outlined, size: 20, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF4B6281)),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'View Details',
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => onApproveRaiser(row),
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 21, color: PiggyTrunkTheme.ptSuccess),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Approve Raiser',
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => onDeleteRaiser(row),
                          icon: const Icon(Icons.cancel_outlined, size: 21, color: Color(0xFFFF758C)),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Reject Registration',
                        ),
                      ],
                    )
                  : (isArchived
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => onShowDetails(row),
                              icon: Icon(Icons.visibility_outlined, size: 20, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF4B6281)),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'View Details',
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => onRestoreRaiser(row),
                              icon: const Icon(Icons.unarchive_outlined, size: 20, color: PiggyTrunkTheme.ptSuccess),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Restore Raiser',
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => onDeleteRaiser(row),
                              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFFF758C)),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Delete Permanently',
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => onShowDetails(row),
                              icon: Icon(Icons.visibility_outlined, size: 20, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF4B6281)),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'View Details',
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => onEditRaiser(row),
                              icon: Icon(Icons.edit_outlined, size: 20, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF4B6281)),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Edit Raiser',
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => onArchiveRaiser(row),
                              icon: const Icon(Icons.archive_outlined, size: 20, color: Color(0xFFFF758C)),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Archive Raiser',
                            ),
                          ],
                        )),
            ),
          ),
        ],
      ),
    );
  }
}
