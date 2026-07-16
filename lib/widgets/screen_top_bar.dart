import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../providers/admin_profile_provider.dart';
import '../providers/admin_notifications_provider.dart';
import '../models/admin_notification_model.dart';

/// Reusable Top Bar Widget with Notification & Admin Profile (No Title)
class ScreenTopBar extends ConsumerWidget {
  final int notificationCount;
  final bool showDivider;

  const ScreenTopBar({
    Key? key,
    this.notificationCount = 1,
    this.showDivider = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminProfile = ref.watch(adminProfileProvider);
    final asyncNotifications = ref.watch(adminNotificationsProvider);
    final notifications = asyncNotifications.value ?? <AdminNotification>[];
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final metadataName = (metadata['admin_name'] ?? '').toString().trim();
    final metadataRole = (metadata['role'] ?? '').toString().trim();
    final metadataPhoto = (metadata['profile_picture_url'] ?? '').toString().trim();
    final resolvedName = adminProfile.adminName.trim().isNotEmpty ? adminProfile.adminName : (metadataName.isNotEmpty ? metadataName : 'Admin');
    final resolvedRole = adminProfile.role.trim().isNotEmpty ? adminProfile.role : (metadataRole.isNotEmpty ? metadataRole : 'System Administrator');
    final resolvedPhoto = (adminProfile.profilePictureUrl != null && adminProfile.profilePictureUrl!.trim().isNotEmpty)
        ? adminProfile.profilePictureUrl!.trim()
        : (metadataPhoto.isNotEmpty ? metadataPhoto : '');

    final shouldHydrateFromMetadata =
        metadataName.isNotEmpty &&
        adminProfile.adminName == 'Admin' &&
        (adminProfile.profilePictureUrl == null || adminProfile.profilePictureUrl!.isEmpty);
    if (shouldHydrateFromMetadata) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(adminProfileProvider.notifier).updateProfile(
              adminName: metadataName,
              role: metadataRole.isNotEmpty ? metadataRole : 'System Administrator',
              profilePictureUrl: metadataPhoto.isNotEmpty ? metadataPhoto : null,
              email: user?.email ?? adminProfile.email,
            );
      });
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xff151f2e) : PiggyTrunkTheme.ptSurface;
    final borderColor = isDark ? const Color(0xff28354a) : PiggyTrunkTheme.ptBorder;
    final textColor = isDark ? const Color(0xffecf2ff) : PiggyTrunkTheme.ptText;
    final mutedColor = isDark ? const Color(0xff9cb0c9) : PiggyTrunkTheme.ptMuted;
    final accentDark = isDark ? PiggyTrunkTheme.ptAccentDark : PiggyTrunkTheme.ptAccent;
    final badgeTextColor = Colors.white;
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: borderColor,
                  width: 1,
                ),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
          /// NOTIFICATION BELL WITH BADGE & REAL-TIME POPUP
          Container(
            width: 50,
            height: 50,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
              ),
              child: PopupMenuButton<void>(
                offset: const Offset(0, 56),
                elevation: 8,
                tooltip: 'Notifications',
                color: surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: borderColor, width: 1),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 50,
                  minHeight: 50,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: 22,
                      color: textColor,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: accentDark,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              unreadCount.toString(),
                              style: AppTextStyles.jakarta(
                                size: 11,
                                weight: FontWeight.w700,
                                color: badgeTextColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                itemBuilder: (context) {
                  return [
                    // Header
                    PopupMenuItem<void>(
                      enabled: false,
                      child: Container(
                        width: 320,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Notifications',
                              style: AppTextStyles.jakarta(
                                size: 15,
                                weight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            if (unreadCount > 0)
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  AdminNotificationService.markAllAsRead();
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Mark all read',
                                  style: AppTextStyles.jakarta(
                                    size: 12,
                                    weight: FontWeight.w600,
                                    color: accentDark,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const PopupMenuDivider(),
                    // Notification Items
                    if (notifications.isEmpty)
                      PopupMenuItem<void>(
                        enabled: false,
                        child: Container(
                          width: 320,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_none, size: 36, color: mutedColor),
                              const SizedBox(height: 8),
                              Text(
                                'No new notifications',
                                style: AppTextStyles.jakarta(
                                  size: 13,
                                  color: mutedColor,
                                  weight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...notifications.take(5).map((notif) {
                        return PopupMenuItem<void>(
                          onTap: () {
                            AdminNotificationService.markAsRead(notif.notificationId);
                            if (notif.type == 'new_raiser') {
                              Navigator.of(context).pushNamed('/raisers');
                            } else if (notif.type == 'stock_request') {
                              Navigator.of(context).pushNamed('/inventory');
                            }
                          },
                          child: Container(
                            width: 320,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!notif.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(top: 4, right: 8),
                                        decoration: const BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    else
                                      const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        notif.title,
                                        style: AppTextStyles.jakarta(
                                          size: 13,
                                          weight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatTimeAgo(notif.createdAt),
                                      style: AppTextStyles.jakarta(
                                        size: 10,
                                        weight: FontWeight.w500,
                                        color: mutedColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Text(
                                    notif.message,
                                    style: AppTextStyles.jakarta(
                                      size: 12,
                                      weight: FontWeight.w500,
                                      color: mutedColor,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    const PopupMenuDivider(),
                    // Footer Actions
                    PopupMenuItem<void>(
                      enabled: false,
                      child: SizedBox(
                        width: 320,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (notifications.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  AdminNotificationService.clearAll();
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Clear all',
                                  style: AppTextStyles.jakarta(
                                    size: 12,
                                    weight: FontWeight.w600,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
              ),
            ),
          ),
          /// ADMIN PROFILE (CLICKABLE)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed('/settings');
                  },
                  child: Container(
                  constraints: const BoxConstraints(maxWidth: 260),
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  /// PROFILE PICTURE OR ICON
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? textColor.withValues(alpha: 0.75) : const Color(0xFF2F4A6A),
                        width: 1.6,
                      ),
                    ),
                    child: resolvedPhoto.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              resolvedPhoto,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return ClipOval(
                                  child: Image.asset(
                                    'assets/piggytrunk_logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                );
                              },
                            ),
                          )
                        : ClipOval(
                            child: Image.asset(
                              'assets/piggytrunk_logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),

                  /// ADMIN INFO
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              resolvedName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.jakarta(
                                size: 13,
                                weight: FontWeight.w700,
                                color: textColor,
                                height: 1.2,
                              ),
                            ),
                            Text(
                              resolvedRole.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.jakarta(
                                size: 11,
                                weight: FontWeight.w600,
                                color: mutedColor,
                                height: 1.2,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),
                ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays >= 7) {
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
}
