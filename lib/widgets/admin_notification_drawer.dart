import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../models/admin_notification_model.dart';
import '../providers/admin_notifications_provider.dart';
import 'slide_over_confirmation_drawer.dart';

/// Modern & Clean Slide-Over Right Drawer for Admin Web Notifications
class AdminNotificationDrawer extends ConsumerStatefulWidget {
  const AdminNotificationDrawer({super.key});

  /// Static helper to open the Slide-Over Drawer with smooth slide animation
  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications Drawer',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim1, anim2) {
        return const Align(
          alignment: Alignment.centerRight,
          child: AdminNotificationDrawer(),
        );
      },
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curvedAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnim),
          child: child,
        );
      },
    );
  }

  @override
  ConsumerState<AdminNotificationDrawer> createState() => _AdminNotificationDrawerState();
}

class _AdminNotificationDrawerState extends ConsumerState<AdminNotificationDrawer> {
  String _selectedFilter = 'all'; // 'all', 'registrations', 'unread'
  final Set<int> _approvingUserIds = <int>{};

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

  Future<void> _handleQuickApprove(AdminNotification notif, int userId, String role) async {
    setState(() {
      _approvingUserIds.add(userId);
    });

    final success = await AdminNotificationService.quickApproveUser(
      userId: userId,
      role: role,
    );

    if (!mounted) return;

    setState(() {
      _approvingUserIds.remove(userId);
    });

    if (success) {
      await AdminNotificationService.markAsRead(notif.notificationId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'User approved and activated successfully!',
                  style: AppTextStyles.jakarta(size: 13, weight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to approve user. Please try again.'),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncNotifications = ref.watch(adminNotificationsProvider);
    final allNotifications = asyncNotifications.value ?? <AdminNotification>[];
    final unreadCount = allNotifications.where((n) => !n.isRead).length;

    final filteredNotifications = allNotifications.where((n) {
      if (_selectedFilter == 'unread') return !n.isRead;
      if (_selectedFilter == 'registrations') return n.type == 'user_registration';
      return true;
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xff151f2e) : Colors.white;
    final bgColor = isDark ? const Color(0xff0d1522) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xff28354a) : const Color(0xFFE2E8F0);
    final textColor = isDark ? const Color(0xffecf2ff) : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xff9cb0c9) : const Color(0xFF64748B);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final drawerWidth = isMobile ? screenWidth : 400.0;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: drawerWidth,
        height: double.infinity,
        decoration: BoxDecoration(
          color: surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              spreadRadius: 2,
              offset: const Offset(-4, 0),
            ),
          ],
          border: Border(
            left: BorderSide(color: borderColor, width: 1),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================== CLEAN DRAWER HEADER ====================
              Container(
                padding: EdgeInsets.fromLTRB(isMobile ? 16 : 20, 16, isMobile ? 12 : 16, 14),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Close Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notifications_outlined,
                              color: textColor,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Notifications',
                              style: AppTextStyles.jakarta(
                                size: 17,
                                weight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            if (unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: AppTextStyles.jakarta(
                                    size: 11,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: mutedColor, size: 20),
                          tooltip: 'Close',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Filter Pills & Mark All Read
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterPill('all', 'All (${allNotifications.length})', isDark: isDark),
                                const SizedBox(width: 6),
                                _buildFilterPill(
                                  'registrations',
                                  'Users (${allNotifications.where((n) => n.type == 'user_registration').length})',
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 6),
                                _buildFilterPill('unread', 'Unread ($unreadCount)', isDark: isDark),
                              ],
                            ),
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => AdminNotificationService.markAllAsRead(),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.done_all_rounded,
                                    size: 14,
                                    color: Color(0xFF2563EB),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Mark all read',
                                    style: AppTextStyles.jakarta(
                                      size: 11.5,
                                      weight: FontWeight.w700,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ==================== NOTIFICATIONS LIST ====================
              Expanded(
                child: filteredNotifications.isEmpty
                    ? _buildEmptyState(mutedColor, textColor)
                    : ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: 12,
                        ),
                        itemCount: filteredNotifications.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final notif = filteredNotifications[index];
                          return _buildSimpleNotificationItem(
                            notif: notif,
                            isDark: isDark,
                            surfaceColor: surfaceColor,
                            bgColor: bgColor,
                            borderColor: borderColor,
                            textColor: textColor,
                            mutedColor: mutedColor,
                          );
                        },
                      ),
              ),

              // ==================== CLEAN DRAWER FOOTER ====================
              if (allNotifications.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border(top: BorderSide(color: borderColor, width: 1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ${allNotifications.length}',
                        style: AppTextStyles.jakarta(
                          size: 12,
                          weight: FontWeight.w500,
                          color: mutedColor,
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          final confirm = await SlideOverConfirmationDrawer.show(
                            context: context,
                            title: 'Clear All Notifications',
                            message: 'Are you sure you want to clear all ${allNotifications.length} notifications? This will permanently delete all notification logs.',
                            actionType: SlideOverActionType.danger,
                            confirmButtonText: 'Yes, Clear All',
                            cancelButtonText: 'Cancel',
                            customIcon: Icons.delete_sweep_outlined,
                          );

                          if (confirm == true) {
                            await AdminNotificationService.clearAll();
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFE53935).withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.delete_sweep_outlined, size: 15, color: Color(0xFFE53935)),
                              const SizedBox(width: 5),
                              Text(
                                'Clear all',
                                style: AppTextStyles.jakarta(
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFFE53935),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String filterKey, String label, {required bool isDark}) {
    final isSelected = _selectedFilter == filterKey;
    final bg = isSelected
        ? (isDark ? Colors.white : PiggyTrunkTheme.ptPrimary)
        : (isDark ? const Color(0xFF1E2F47) : const Color(0xFFEEF4FD));
    final fg = isSelected
        ? (isDark ? PiggyTrunkTheme.ptPrimary : Colors.white)
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF5D7391));
    final border = isSelected
        ? Colors.transparent
        : (isDark ? const Color(0xFF28405D) : const Color(0xFFB4C9E6));

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filterKey;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: AppTextStyles.jakarta(
            size: 11.5,
            weight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }

  String _resolveTargetRoute(AdminNotification notif) {
    final type = notif.type.toLowerCase();
    final meta = notif.metadata ?? <String, dynamic>{};
    final role = (meta['role'] ?? '').toString().toLowerCase();
    final message = notif.message.toLowerCase();
    final title = notif.title.toLowerCase();

    // 1. Hog Raiser Registrations & Hog Reports -> /raisers (Hog Raiser Screen)
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

  /// Simple, Clean Text Notification Item
  Widget _buildSimpleNotificationItem({
    required AdminNotification notif,
    required bool isDark,
    required Color surfaceColor,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required Color mutedColor,
  }) {
    final isUserRegistration = notif.type == 'user_registration';
    final meta = notif.metadata ?? <String, dynamic>{};
    final int? rawUserId = meta['user_id'] is int ? meta['user_id'] as int : int.tryParse(meta['user_id']?.toString() ?? '');
    final String rawRole = (meta['role'] ?? 'hog_raiser').toString();
    final bool isApproving = rawUserId != null && _approvingUserIds.contains(rawUserId);
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
                        : () => _handleQuickApprove(notif, rawUserId, rawRole),
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

  /// Clean & Simple Empty State
  Widget _buildEmptyState(Color mutedColor, Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 40,
              color: mutedColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No notifications',
              style: AppTextStyles.jakarta(
                size: 14,
                weight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No new registrations or farm alerts right now.',
              textAlign: TextAlign.center,
              style: AppTextStyles.jakarta(
                size: 12,
                weight: FontWeight.w400,
                color: mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
