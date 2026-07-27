import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/models/pos_model.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../widgets/cashier_empty_state.dart';
import '../widgets/cashier_notification_bell.dart';

class CashierHomeTab extends StatelessWidget {
  final String cashierName;
  final List<POSProduct> lowStockProducts;
  final List<Map<String, dynamic>> pendingRequests;
  final VoidCallback onNavigateToInventory;
  final VoidCallback onShowRequestsDialog;

  const CashierHomeTab({
    super.key,
    required this.cashierName,
    required this.lowStockProducts,
    required this.pendingRequests,
    required this.onNavigateToInventory,
    required this.onShowRequestsDialog,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20.0, 48.0, 20.0, 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Header Row with Notification Bell
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
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
                    cashierName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF18314F),
                    ),
                  ),
                ],
              ),
              CashierNotificationBell(
                pendingRequests: pendingRequests,
                onOpenRequestsModal: onShowRequestsDialog,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick Actions Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Actions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF18314F),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'View all',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF18314F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Actions Grid (Restock / Request)
          Row(
            children: [
              // Restock Button Card
              Expanded(
                child: GestureDetector(
                  onTap: onNavigateToInventory,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: PiggyTrunkTheme.ptBorder, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE6EDF6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Color(0xFF18314F), size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Restock',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF18314F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Request Button Card
              Expanded(
                child: GestureDetector(
                  onTap: onShowRequestsDialog,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: PiggyTrunkTheme.ptBorder, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE6EDF6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.assignment_outlined, color: Color(0xFF18314F), size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Request',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF18314F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Recent Stock Alerts Title
          Text(
            'Recent Stock Alerts',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF18314F),
            ),
          ),
          const SizedBox(height: 16),

          // Recent Stock Alerts List
          lowStockProducts.isEmpty
              ? const CashierEmptyState(
                  message: 'Walang laman sa kasalukuyan',
                  icon: Icons.check_circle_outline,
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lowStockProducts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = lowStockProducts[index];
                    final int percentage = (p.units <= 0) ? 0 : (p.units < 10 ? 12 : 45);
                    final isCritical = p.units < 10;

                    return Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: PiggyTrunkTheme.ptBorder, width: 1),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            Container(
                              width: 5,
                              color: isCritical ? Colors.red[700] : Colors.orange[400],
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 60,
                              height: 60,
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: PiggyTrunkTheme.ptBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: p.image != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(p.image!, fit: BoxFit.cover),
                                    )
                                  : Icon(Icons.image_not_supported_outlined, color: Colors.grey[400]),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          isCritical ? 'CRITICAL STOCK' : 'LOW STOCK',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isCritical ? Colors.red[700] : Colors.orange[600],
                                          ),
                                        ),
                                        Text(
                                          isCritical ? '2h ago' : '5h ago',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: PiggyTrunkTheme.ptMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      p.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF18314F),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: percentage / 100,
                                              backgroundColor: Colors.blueGrey[50],
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                isCritical ? Colors.red[700]! : Colors.orange[400]!,
                                              ),
                                              minHeight: 6,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '$percentage% left',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF18314F),
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            )
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
}
