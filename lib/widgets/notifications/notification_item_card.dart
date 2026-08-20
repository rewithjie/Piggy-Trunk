import 'package:flutter/material.dart';
import '../../models/admin_notification_model.dart';
import '../../providers/admin_notifications_provider.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

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

  IconData _getCategoryIcon(String type, String message) {
    final lowerType = type.toLowerCase();
    final lowerMsg = message.toLowerCase();
    if (lowerType.contains('user') || lowerMsg.contains('register') || lowerMsg.contains('account')) {
      return Icons.person_add_rounded;
    }
    if (lowerType.contains('hog') || lowerMsg.contains('batch') || lowerMsg.contains('pig')) {
      return Icons.pets_rounded;
    }
    if (lowerType.contains('feed') || lowerType.contains('stock') || lowerType.contains('inventory')) {
      return Icons.inventory_2_rounded;
    }
    if (lowerType.contains('invest') || lowerType.contains('fund') || lowerType.contains('pay')) {
      return Icons.payments_rounded;
    }
    return Icons.notifications_active_rounded;
  }

  Color _getCategoryColor(String type, String message, bool isDark) {
    final lowerType = type.toLowerCase();
    final lowerMsg = message.toLowerCase();
    if (lowerType.contains('user') || lowerMsg.contains('register')) {
      return isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    }
    if (lowerType.contains('hog') || lowerMsg.contains('batch')) {
      return isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
    }
    if (lowerType.contains('feed') || lowerType.contains('stock')) {
      return isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
    }
    if (lowerType.contains('invest') || lowerType.contains('fund')) {
      return isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED);
    }
    return isDark ? Colors.white : PiggyTrunkTheme.ptPrimary;
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

    final brandPrimary = isDark ? Colors.white : PiggyTrunkTheme.ptPrimary;
    final catColor = _getCategoryColor(notif.type, notif.message, isDark);
    final catIcon = _getCategoryIcon(notif.type, notif.message);

    final cardBg = notif.isRead
        ? surfaceColor
        : (isDark ? const Color(0xFF172436) : const Color(0xFFF3F7FD));
    final cardBorder = notif.isRead
        ? borderColor
        : (isDark ? const Color(0xFF334E6F) : const Color(0xFFBFDBFE));

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
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cardBorder,
            width: 1,
          ),
          boxShadow: !notif.isRead
              ? [
                  BoxShadow(
                    color: brandPrimary.withValues(alpha: isDark ? 0.1 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent strip for unread notifications
                if (!notif.isRead)
                  Container(
                    width: 3.5,
                    color: brandPrimary,
                  ),

                // Card Main Body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Icon Badge
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: isDark ? 0.18 : 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: catColor.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            catIcon,
                            size: 16,
                            color: catColor,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Notification Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Title + Time
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: AppTextStyles.jakarta(
                                        size: 13,
                                        weight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                                        color: textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatTimeAgo(notif.createdAt),
                                    style: AppTextStyles.jakarta(
                                      size: 11,
                                      weight: FontWeight.w500,
                                      color: mutedColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // Message Text
                              Text(
                                notif.message,
                                style: AppTextStyles.jakarta(
                                  size: 12,
                                  weight: FontWeight.w400,
                                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                  height: 1.35,
                                ),
                              ),

                              // Quick Approve Action (for user registrations)
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
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Approve',
                                                  style: AppTextStyles.jakarta(size: 11, weight: FontWeight.w700),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
