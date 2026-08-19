import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/models/pos_model.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../widgets/cashier_empty_state.dart';
import '../widgets/cashier_notification_bell.dart';
import '../widgets/cashier_notification_drawer.dart';

class CashierHomeTab extends StatelessWidget {
  final String cashierName;
  final List<POSProduct> allProducts;
  final List<POSProduct> lowStockProducts;
  final List<Map<String, dynamic>> pendingRequests;
  final List<Map<String, dynamic>> salesLogs;
  final Set<String> readNotificationIds;
  final VoidCallback onNavigateToPOS;
  final VoidCallback onNavigateToInventory;
  final VoidCallback onNavigateToRequests;
  final VoidCallback onShowRequestsDialog;
  final VoidCallback onShowSalesHistory;
  final VoidCallback onMarkAllAsRead;
  final Function(String) onMarkAsRead;
  final Function(POSProduct) onAddToCart;
  final Future<void> Function() onRefresh;

  static const Color _brandColor = Color(0xFF18314F);
  static const Color _cardBg = Colors.white;

  const CashierHomeTab({
    super.key,
    required this.cashierName,
    required this.allProducts,
    required this.lowStockProducts,
    required this.pendingRequests,
    required this.salesLogs,
    required this.readNotificationIds,
    required this.onNavigateToPOS,
    required this.onNavigateToInventory,
    required this.onNavigateToRequests,
    required this.onShowRequestsDialog,
    required this.onShowSalesHistory,
    required this.onMarkAllAsRead,
    required this.onMarkAsRead,
    required this.onAddToCart,
    required this.onRefresh,
  });

  String _formatCurrency(double amount) {
    return '₱${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  double _calculateTodaySales() {
    final now = DateTime.now();
    double total = 0.0;
    for (final sale in salesLogs) {
      final dateStr = sale['sale_date'] ?? sale['created_at'];
      if (dateStr != null) {
        try {
          final dt = DateTime.parse(dateStr.toString()).toLocal();
          if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
            final rawTotal = sale['total_amount'] ?? sale['total'] ?? 0;
            total += (rawTotal is num ? rawTotal.toDouble() : double.tryParse(rawTotal.toString()) ?? 0.0);
          }
        } catch (_) {}
      }
    }
    return total;
  }

  int _calculateTodayTransactions() {
    final now = DateTime.now();
    int count = 0;
    for (final sale in salesLogs) {
      final dateStr = sale['sale_date'] ?? sale['created_at'];
      if (dateStr != null) {
        try {
          final dt = DateTime.parse(dateStr.toString()).toLocal();
          if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
            count++;
          }
        } catch (_) {}
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final double todaySales = _calculateTodaySales();
    final int todayTx = _calculateTodayTransactions();
    final int inStockCount = allProducts.where((p) => p.units > 0 && !p.isArchived).length;
    final int lowStockCount = lowStockProducts.length;
    final int pendingReqCount = pendingRequests.where((r) {
      final st = (r['status'] ?? '').toString().toLowerCase();
      return st == 'pending' || st == 'for_approval';
    }).length;

    // Calculate unread count for bell badge
    int totalUnread = 0;
    for (final req in pendingRequests) {
      final st = (req['status'] ?? '').toString().toLowerCase();
      if (st == 'pending' || st == 'for_approval' || st.isEmpty) {
        final id = 'req_${req['id'] ?? req['request_id']}';
        if (!readNotificationIds.contains(id)) totalUnread++;
      }
    }
    for (final p in lowStockProducts) {
      final id = 'stock_${p.id}';
      if (!readNotificationIds.contains(id)) totalUnread++;
    }
    for (final sale in salesLogs.take(5)) {
      final id = 'sale_${sale['id']}';
      if (!readNotificationIds.contains(id)) totalUnread++;
    }

    final List<POSProduct> fastMoving = allProducts
        .where((p) => !p.isArchived)
        .toList()
      ..sort((a, b) => b.sold.compareTo(a.sold));
    final List<POSProduct> featuredProducts = fastMoving.take(6).toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: _brandColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== TOP GREETING & NOTIFICATION ====================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello Cashier,',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: PiggyTrunkTheme.ptMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cashierName.trim().isNotEmpty ? cashierName : 'Cashier',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: _brandColor,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                CashierNotificationBell(
                  unreadCount: totalUnread,
                  onOpenNotifications: () {
                    showCashierNotificationDrawer(
                      context: context,
                      pendingRequests: pendingRequests,
                      lowStockProducts: lowStockProducts,
                      salesLogs: salesLogs,
                      readNotificationIds: readNotificationIds,
                      onNavigateToRequests: onNavigateToRequests,
                      onNavigateToInventory: onNavigateToInventory,
                      onShowSalesHistory: onShowSalesHistory,
                      onMarkAllAsRead: onMarkAllAsRead,
                      onMarkAsRead: onMarkAsRead,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ==================== 4 METRIC STATS OVERVIEW ====================
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: "Today's Sales",
                    value: _formatCurrency(todaySales),
                    subtitle: '$todayTx receipts issued',
                    icon: Icons.payments_rounded,
                    accentColor: const Color(0xFF10B981),
                    bgColor: const Color(0xFFECFDF5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Active Products',
                    value: '$inStockCount Items',
                    subtitle: '${allProducts.length} total catalog',
                    icon: Icons.inventory_2_rounded,
                    accentColor: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFEFF6FF),
                    onTap: onNavigateToInventory,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Stock Alerts',
                    value: '$lowStockCount Items',
                    subtitle: lowStockCount > 0 ? 'Action required' : 'All well-stocked',
                    icon: Icons.warning_amber_rounded,
                    accentColor: lowStockCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    bgColor: lowStockCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                    onTap: onNavigateToInventory,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Stock Requests',
                    value: '$pendingReqCount Pending',
                    subtitle: 'From Hog Raisers',
                    icon: Icons.assignment_rounded,
                    accentColor: const Color(0xFFF59E0B),
                    bgColor: const Color(0xFFFFFBEB),
                    onTap: onNavigateToRequests,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ==================== QUICK ACTIONS GRID ====================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Actions',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _brandColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                _buildQuickActionTile(
                  icon: Icons.point_of_sale_rounded,
                  label: 'POS Register',
                  color: const Color(0xFF2563EB),
                  onTap: onNavigateToPOS,
                ),
                const SizedBox(width: 10),
                _buildQuickActionTile(
                  icon: Icons.add_box_rounded,
                  label: 'Restock',
                  color: const Color(0xFF10B981),
                  onTap: onNavigateToInventory,
                ),
                const SizedBox(width: 10),
                _buildQuickActionTile(
                  icon: Icons.post_add_rounded,
                  label: 'Request',
                  color: const Color(0xFFF59E0B),
                  onTap: onShowRequestsDialog,
                ),
                const SizedBox(width: 10),
                _buildQuickActionTile(
                  icon: Icons.receipt_long_rounded,
                  label: 'History',
                  color: const Color(0xFF8B5CF6),
                  onTap: onShowSalesHistory,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ==================== REAL-TIME STOCK HEALTH ALERTS ====================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Live Stock Alerts',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _brandColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: lowStockCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$lowStockCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: onNavigateToInventory,
                  child: Text(
                    'Manage Stock →',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _brandColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (lowStockProducts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: PiggyTrunkTheme.ptBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFECFDF5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Healthy Stock Levels',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: _brandColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'All inventory items have sufficient units in stock.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: PiggyTrunkTheme.ptMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: lowStockProducts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final p = lowStockProducts[index];
                  final int currentStock = p.units;
                  final bool isCritical = currentStock <= 5;
                  final double stockProgress = (currentStock / 20.0).clamp(0.05, 1.0);

                  return Container(
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isCritical
                            ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                            : PiggyTrunkTheme.ptBorder,
                        width: isCritical ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          // Product Image / Thumbnail
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: p.image != null && p.image!.isNotEmpty
                                  ? Image.network(
                                      p.image!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, st) => const Icon(
                                        Icons.inventory_2_outlined,
                                        color: Color(0xFF94A3B8),
                                        size: 26,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.inventory_2_outlined,
                                      color: Color(0xFF94A3B8),
                                      size: 26,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Product Info & Real Stock Gauge
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isCritical
                                            ? const Color(0xFFFEE2E2)
                                            : const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isCritical ? 'CRITICAL' : 'LOW STOCK',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: isCritical
                                              ? const Color(0xFFDC2626)
                                              : const Color(0xFFD97706),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatCurrency(p.price),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _brandColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  p.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: _brandColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: stockProgress,
                                          backgroundColor: const Color(0xFFF1F5F9),
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            isCritical ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                                          ),
                                          minHeight: 5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '$currentStock ${currentStock == 1 ? 'unit' : 'units'} left',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isCritical
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFFD97706),
                                      ),
                                    ),
                                  ],
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
            const SizedBox(height: 32),

            // ==================== FEATURED PRODUCTS CAROUSEL ====================
            if (featuredProducts.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Featured Inventory',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _brandColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: onNavigateToPOS,
                    child: Text(
                      'View POS Catalog →',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _brandColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 195,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: featuredProducts.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = featuredProducts[index];
                    return Container(
                      width: 155,
                      padding: const EdgeInsets.all(12),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image container
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: item.image != null && item.image!.isNotEmpty
                                    ? Image.network(
                                        item.image!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, st) => const Icon(
                                          Icons.inventory_2_outlined,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.inventory_2_outlined,
                                        color: Color(0xFF94A3B8),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _brandColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatCurrency(item.price),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _brandColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${item.units} in stock',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  color: PiggyTrunkTheme.ptMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => onAddToCart(item),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: _brandColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],

            // ==================== RECENT SALES TRANSACTIONS ====================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _brandColor,
                  ),
                ),
                GestureDetector(
                  onTap: onShowSalesHistory,
                  child: Text(
                    'All Receipts →',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _brandColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (salesLogs.isEmpty)
              const CashierEmptyState(
                message: 'No transactions recorded yet today',
                icon: Icons.receipt_long_outlined,
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: salesLogs.length.clamp(0, 3),
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final sale = salesLogs[index];
                  final invoice = (sale['invoice_number'] ?? sale['receipt_number'] ?? '#SALE-${sale['id'] ?? index + 1001}').toString();
                  final rawTotal = sale['total_amount'] ?? sale['total'] ?? 0;
                  final double total = rawTotal is num ? rawTotal.toDouble() : double.tryParse(rawTotal.toString()) ?? 0.0;
                  final String paymentMethod = (sale['payment_method'] ?? 'Cash').toString();
                  final dateStr = sale['sale_date'] ?? sale['created_at'];

                  String timeDisplay = 'Today';
                  if (dateStr != null) {
                    try {
                      final dt = DateTime.parse(dateStr.toString()).toLocal();
                      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
                      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
                      final minute = dt.minute.toString().padLeft(2, '0');
                      timeDisplay = '$hour:$minute $ampm';
                    } catch (_) {}
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: PiggyTrunkTheme.ptBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_rounded, color: _brandColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invoice,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _brandColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$paymentMethod • $timeDisplay',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: PiggyTrunkTheme.ptMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatCurrency(total),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 18),
                ),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios_rounded, color: PiggyTrunkTheme.ptMuted.withValues(alpha: 0.6), size: 12),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _brandColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: PiggyTrunkTheme.ptMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PiggyTrunkTheme.ptBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _brandColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

