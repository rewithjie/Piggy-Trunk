import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_toast.dart';
import '../../models/admin_notification_model.dart';
import '../../providers/admin_notifications_provider.dart';
import '../slide_over_confirmation_drawer.dart';
import 'notification_item_card.dart';
import 'notification_filter_bar.dart';

/// Modern & Clean Slide-Over Right Drawer for Admin Web Notifications
class AdminNotificationDrawer extends ConsumerStatefulWidget {
  const AdminNotificationDrawer({super.key});

  /// Static helper to open the Slide-Over Drawer with smooth slide animation
  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications Drawer',
      barrierColor: Colors.black.withValues(alpha: 0.45),
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

      AppToast.success(context, 'User approved and activated successfully!');
    } else {
      AppToast.error(context, 'Failed to approve user. Please try again.');
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
    final surfaceColor = isDark ? const Color(0xFF132238) : Colors.white;
    final bgColor = isDark ? const Color(0xFF0F1A2A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
    final textColor = isDark ? Colors.white : const Color(0xFF18314F);
    final mutedColor = isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);
    final brandPrimary = isDark ? Colors.white : PiggyTrunkTheme.ptPrimary;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final drawerWidth = isMobile ? screenWidth : 420.0;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: drawerWidth,
        height: double.infinity,
        decoration: BoxDecoration(
          color: surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
              blurRadius: 28,
              spreadRadius: 2,
              offset: const Offset(-4, 0),
            ),
          ],
          border: Border(
            left: BorderSide(color: borderColor, width: 1.2),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Branded Header
              Container(
                padding: EdgeInsets.fromLTRB(isMobile ? 16 : 20, 16, isMobile ? 12 : 16, 14),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E2F47) : const Color(0xFFEEF4FD),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF28405D) : const Color(0xFFBFDBFE),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.notifications_active_outlined,
                                color: brandPrimary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Notifications',
                              style: AppTextStyles.jakarta(
                                size: 17,
                                weight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            if (unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: brandPrimary.withValues(alpha: isDark ? 0.18 : 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: brandPrimary.withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '$unreadCount new',
                                  style: AppTextStyles.jakarta(
                                    size: 11,
                                    weight: FontWeight.w700,
                                    color: brandPrimary,
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
                    const SizedBox(height: 14),
                    NotificationFilterBar(
                      selectedFilter: _selectedFilter,
                      allNotifications: allNotifications,
                      unreadCount: unreadCount,
                      isDark: isDark,
                      onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
                    ),
                  ],
                ),
              ),

              // Notifications List / Empty State
              Expanded(
                child: filteredNotifications.isEmpty
                    ? _buildEmptyState(isDark, mutedColor, textColor, borderColor)
                    : ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: 12,
                        ),
                        itemCount: filteredNotifications.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final notif = filteredNotifications[index];
                          final meta = notif.metadata ?? <String, dynamic>{};
                          final int? rawUserId = meta['user_id'] is int ? meta['user_id'] as int : int.tryParse(meta['user_id']?.toString() ?? '');
                          final isApproving = rawUserId != null && _approvingUserIds.contains(rawUserId);

                          return NotificationItemCard(
                            notif: notif,
                            isDark: isDark,
                            surfaceColor: surfaceColor,
                            bgColor: bgColor,
                            borderColor: borderColor,
                            textColor: textColor,
                            mutedColor: mutedColor,
                            isApproving: isApproving,
                            onQuickApprove: _handleQuickApprove,
                          );
                        },
                      ),
              ),

              // Drawer Footer
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A2B44) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          'Total: ${allNotifications.length} items',
                          style: AppTextStyles.jakarta(
                            size: 11.5,
                            weight: FontWeight.w600,
                            color: mutedColor,
                          ),
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

  Widget _buildEmptyState(bool isDark, Color mutedColor, Color textColor, Color borderColor) {
    final brandPrimary = isDark ? Colors.white : PiggyTrunkTheme.ptPrimary;
    final ringOuter = isDark ? const Color(0xFF1E2F47).withValues(alpha: 0.6) : const Color(0xFFEEF4FD);
    final ringInner = isDark ? const Color(0xFF1A2B44) : const Color(0xFFF1F5F9);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Layered concentric glowing badge
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ringOuter,
                border: Border.all(
                  color: isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: brandPrimary.withValues(alpha: isDark ? 0.12 : 0.08),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ringInner,
                    border: Border.all(
                      color: isDark ? const Color(0xFF334E6F) : const Color(0xFFCBD5E1),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 30,
                      color: brandPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'All Caught Up!',
              style: AppTextStyles.jakarta(
                size: 16,
                weight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No new registrations, farm alerts, or stock requests at the moment.',
              textAlign: TextAlign.center,
              style: AppTextStyles.jakarta(
                size: 12.5,
                weight: FontWeight.w400,
                color: mutedColor,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
