import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CashierInventoryLogsModal extends StatefulWidget {
  final String? filterProductId;
  final String? filterProductName;

  const CashierInventoryLogsModal({
    super.key,
    this.filterProductId,
    this.filterProductName,
  });

  @override
  State<CashierInventoryLogsModal> createState() => _CashierInventoryLogsModalState();
}

class _CashierInventoryLogsModalState extends State<CashierInventoryLogsModal> {
  static const Color _brandNavy = Color(0xFF18314F);
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String _selectedActionFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    try {
      var query = Supabase.instance.client
          .from('inventory_logs')
          .select();

      if (widget.filterProductName != null && widget.filterProductName!.isNotEmpty) {
        query = query.ilike('product_name', '%${widget.filterProductName}%');
      }

      final res = await query.order('created_at', ascending: false).limit(100);
      if (mounted) {
        setState(() {
          _logs = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (e) {
      debugPrint('Error fetching inventory logs: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $hour:$min $ampm';
    } catch (_) {
      return dateStr;
    }
  }

  Color _getActionColor(String? action) {
    switch (action?.toUpperCase()) {
      case 'RESTOCK':
      case 'IN':
      case 'ADD':
        return const Color(0xFF10B981); // Green
      case 'SALE':
      case 'OUT':
      case 'DEDUCT':
        return const Color(0xFF3B82F6); // Blue
      case 'DAMAGE':
      case 'LOSS':
      case 'EXPIRED':
        return const Color(0xFFEF4444); // Red
      case 'UPDATE':
      case 'EDIT':
        return const Color(0xFFF59E0B); // Amber
      default:
        return _brandNavy;
    }
  }

  IconData _getActionIcon(String? action) {
    switch (action?.toUpperCase()) {
      case 'RESTOCK':
      case 'IN':
      case 'ADD':
        return Icons.add_circle_outline_rounded;
      case 'SALE':
      case 'OUT':
      case 'DEDUCT':
        return Icons.shopping_bag_outlined;
      case 'DAMAGE':
      case 'LOSS':
      case 'EXPIRED':
        return Icons.warning_amber_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _logs.where((l) {
      if (_selectedActionFilter == 'ALL') return true;
      final action = (l['action'] as String? ?? '').toUpperCase();
      return action.contains(_selectedActionFilter);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inventory Activity Logs',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _brandNavy,
                          ),
                        ),
                        if (widget.filterProductName != null) ...[
                          Text(
                            'Filtered for: ${widget.filterProductName}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: PiggyTrunkTheme.ptMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: PiggyTrunkTheme.ptMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['ALL', 'RESTOCK', 'SALE', 'UPDATE'].map((f) {
                      final isSelected = _selectedActionFilter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedActionFilter = f),
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : _brandNavy,
                          ),
                          selectedColor: _brandNavy,
                          backgroundColor: const Color(0xFFF0F4F9),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Content List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _brandNavy))
                : filteredLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'No inventory activity records found.',
                              style: GoogleFonts.plusJakartaSans(
                                color: PiggyTrunkTheme.ptMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchLogs,
                        color: _brandNavy,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: filteredLogs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final log = filteredLogs[index];
                            final action = (log['action'] as String? ?? 'LOG').toUpperCase();
                            final prodName = log['product_name'] ?? 'Product';
                            final units = log['units'] ?? 0;
                            final price = (log['price'] as num?)?.toDouble() ?? 0.0;
                            final details = log['details'] ?? '';
                            final dateStr = log['created_at'];
                            final actionColor = _getActionColor(action);

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: actionColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(_getActionIcon(action), color: actionColor, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                prodName,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                  color: _brandNavy,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: actionColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                action,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: actionColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              '$units Bags',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: _brandNavy,
                                              ),
                                            ),
                                            if (price > 0) ...[
                                              Text(
                                                ' • ₱${price.toStringAsFixed(2)}',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: PiggyTrunkTheme.ptMuted,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (details.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            details,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: PiggyTrunkTheme.ptMuted,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Text(
                                          _formatDate(dateStr),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            color: Colors.grey[500],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
