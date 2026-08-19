import 'package:flutter/material.dart';
import '../../models/admin_notification_model.dart';
import '../../providers/admin_notifications_provider.dart';
import '../../theme/app_text_styles.dart';

class NotificationItemCard extends StatelessWidget {
  final AdminNotification notif;
  final bool isDark;
  final Color surfaceColor;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedColor;
  final bool isApproving;
  final Future<void> Function(AdminNotification notif, int userId, String role) onQuickApprove;

  const NotificationItemCard({
    super.key,
    required this.notif,
    required this.isDark,
    required this.surfaceColor,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedColor,
    required this.isApproving,
    required this.onQuickApprove,
  });

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 7) {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _resolveTargetRoute(AdminNotification notif) {
    final type = notif.type.toLowerCase();
    final meta = notif.metadata ?? <String, dynamic>{};
    final role = (meta['role'] ?? '').toString().toLowerCase();
    final message = notif.message.toLowerCase();
    final title = notif.title.toLowerCase();

    // 1. Hog Raiser Registrations & Hog Reports -> /raisers
    if (role == 'hog_raiser' ||
        role == 'raiser' ||
        message.contains('hog raiser') ||
        title.contains('hog raiser') ||
        type == 'hog_report' ||
        type.contains('hog')) {
      return '/raisers';
    }

    // 2. Partner Investor Registrations -> /users
    if (role == 'partner' ||
        role == 'investor' ||
        message.contains('partner') ||
        title.contains('partner')) {
      return '/users';
    }

    // 3. Cashier Registrations -> /users
    if (role == 'cashier' || message.contains('cashier') || title.contains('cashier')) {
      return '/users';
    }

    // 4. Feeds & Supplies Inventory -> /inventory
    if (type == 'feed_restock' ||
        type.contains('stock') ||
        type.contains('feed') ||
        type.contains('inventory') ||
        message.contains('feed') ||
        message.contains('stock')) {
      return '/inventory';
    }

    // 5. General User Approvals
    if (type == 'user_registration' || type.contains('user') || type.contains('approval')) {
      return '/users';
    }

    // 6. Investments & Financial Transactions
    if (type == 'transaction' || type.contains('investment') || type.contains('sales') || type.contains('pos')) {
      return '/investments';
    }

    return '/dashboard';
  }

  @override
  Widget build(BuildContext context) {
    final isUserRegistration = notif.type == 'user_registration';
    final meta = notif.metadata ?? <String, dynamic>{};
    final int? rawUserId = meta['user_id'] is int ? meta['user_id'] as int : int.tryParse(meta['user_id']?.toString() ?? '');
    final String rawRole = (meta['role'] ?? 'hog_raiser').toString();
    final targetRoute = _resolveTargetRoute(notif);
    final String? routeArg = (notif.type == 'user_registration' || notif.message.toLowerCase().contains('pending'))
        ? 'pending'
        : null;

    return InkWell(
      onTap: () {
        if (!notif.isRead) {
          AdminNotificationService.markAsRead(notif.notificationId);
        }
        Navigator.of(context).pop(); // Close drawer
        Navigator.of(context).pushNamed(targetRoute, arguments: routeArg); // Navigate directly to screen
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notif.isRead ? surfaceColor : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notif.isRead ? borderColor : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Unread Dot + Title + Time + Arrow Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (!notif.isRead)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      notif.title,
                      style: AppTextStyles.jakarta(
                        size: 13,
                        weight: notif.isRead ? FontWeight.w600 : FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      _formatTimeAgo(notif.createdAt),
                      style: AppTextStyles.jakarta(
                        size: 11,
                        weight: FontWeight.w400,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: mutedColor.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Simple Clean Message Text
            Text(
              notif.message,
              style: AppTextStyles.jakarta(
                size: 12.5,
                weight: FontWeight.w400,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                height: 1.35,
              ),
            ),

            // Compact Quick Approve Button (if pending registration)
            if (isUserRegistration && rawUserId != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: isApproving
                        ? null
                        : () => onQuickApprove(notif, rawUserId, rawRole),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: isApproving
                        ? const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Approve',
                            style: AppTextStyles.jakarta(size: 11, weight: FontWeight.w600),
                          ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
