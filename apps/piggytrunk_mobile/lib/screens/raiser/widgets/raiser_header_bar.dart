import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import 'raiser_notification_drawer.dart';

class RaiserHeaderBar extends StatelessWidget {
  final String raiserName;
  final List<Map<String, dynamic>> notificationsList;
  final VoidCallback onRefreshNotifications;
  final Function(int notificationId) onMarkNotificationAsRead;
  final VoidCallback onMarkAllRead;
  final Function(int index)? onNavigateToTab;

  static const Color _brandColor = Color(0xFF18314F);

  const RaiserHeaderBar({
    super.key,
    required this.raiserName,
    required this.notificationsList,
    required this.onRefreshNotifications,
    required this.onMarkNotificationAsRead,
    required this.onMarkAllRead,
    this.onNavigateToTab,
  });

  Widget _buildNotificationBell(BuildContext context) {
    final unreadCount = notificationsList.where((n) => n['is_read'] == false).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        showRaiserNotificationDrawer(
          context: context,
          notificationsList: notificationsList,
          onRefreshNotifications: onRefreshNotifications,
          onMarkNotificationAsRead: onMarkNotificationAsRead,
          onMarkAllRead: onMarkAllRead,
          onNavigateToTab: onNavigateToTab,
        );
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2A3F) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? const Color(0xFF28354A) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              color: isDark ? Colors.white : _brandColor,
              size: 24,
            ),
            if (unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : _brandColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello Hog Raiser,',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                raiserName.trim().isNotEmpty ? raiserName : 'Hog Raiser',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _buildNotificationBell(context),
      ],
    );
  }
}
