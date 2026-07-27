import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';

class CashierNotificationBell extends StatelessWidget {
  final List<Map<String, dynamic>> pendingRequests;
  final VoidCallback onOpenRequestsModal;

  static const Color _brandColor = Color(0xFF18314F);

  const CashierNotificationBell({
    super.key,
    required this.pendingRequests,
    required this.onOpenRequestsModal,
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Today';
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = pendingRequests.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xff151f2e) : Colors.white;
    final borderColor = isDark ? const Color(0xff28354a) : const Color(0xffe2e8f0);
    final textColor = isDark ? const Color(0xffecf2ff) : _brandColor;
    final mutedColor = isDark ? const Color(0xff9cb0c9) : Colors.grey[500];

    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: PopupMenuButton<void>(
        offset: const Offset(-10, 48),
        elevation: 8,
        tooltip: 'Mga Notification',
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: 1),
        ),
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: 280,
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            const IconButton(
              icon: Icon(Icons.notifications_none_outlined, color: _brandColor),
              onPressed: null,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        itemBuilder: (context) {
          return [
            PopupMenuItem<void>(
              enabled: false,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mga Notification',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    if (unreadCount > 0)
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onOpenRequestsModal();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'View all',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: PiggyTrunkTheme.ptSuccess,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const PopupMenuDivider(),
            if (pendingRequests.isEmpty)
              PopupMenuItem<void>(
                enabled: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none, size: 36, color: mutedColor),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Walang bagong notification',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: mutedColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...pendingRequests.take(5).map((req) {
                final raiser = req['raiser'] as Map<String, dynamic>?;
                final product = req['product'] as Map<String, dynamic>?;
                final raiserName = raiser?['name'] ?? 'Hog Raiser';
                final productName = product?['name'] ?? 'Stock Feed';
                final quantity = req['quantity'] ?? 1;
                final dateStr = _formatDate(req['created_at']);

                return PopupMenuItem<void>(
                  onTap: () {
                    onOpenRequestsModal();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 4, right: 8),
                              decoration: const BoxDecoration(
                                color: PiggyTrunkTheme.ptSuccess,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Icon(Icons.assignment_outlined, size: 18, color: _brandColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bagong Stock Request',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            '$raiserName humihingi ng $quantity Sacks ng $productName',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey[400] : Colors.grey[700],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            dateStr,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: mutedColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ];
        },
      ),
    );
  }
}
