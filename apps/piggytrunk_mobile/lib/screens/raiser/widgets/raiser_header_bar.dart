import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';

class RaiserHeaderBar extends StatelessWidget {
  final String raiserName;
  final List<Map<String, dynamic>> notificationsList;
  final VoidCallback onRefreshNotifications;
  final Function(int notificationId) onMarkNotificationAsRead;
  final VoidCallback onMarkAllRead;

  static const Color _brandColor = Color(0xFF18314F);

  const RaiserHeaderBar({
    super.key,
    required this.raiserName,
    required this.notificationsList,
    required this.onRefreshNotifications,
    required this.onMarkNotificationAsRead,
    required this.onMarkAllRead,
  });

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildNotificationBell(BuildContext context) {
    final unreadCount = notificationsList.where((n) => n['is_read'] == false).length;
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
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
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
                          onMarkAllRead();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Mark all read',
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
            if (notificationsList.isEmpty)
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
                          'Walang notification sa kasalukuyan',
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
              ...notificationsList.take(5).map((notif) {
                final isRead = notif['is_read'] == true;
                final dateStr = _formatDate(notif['created_at']);
                final notifId = notif['notification_id'] as int;

                IconData iconData = Icons.notifications_none;
                Color iconColor = _brandColor;

                if (notif['type'] == 'request_status') {
                  final status = notif['metadata']?['status']?.toString().toLowerCase() ?? '';
                  if (status == 'approved') {
                    iconData = Icons.check_circle_outline;
                    iconColor = PiggyTrunkTheme.ptSuccess;
                  } else if (status == 'rejected') {
                    iconData = Icons.cancel_outlined;
                    iconColor = Colors.red;
                  } else {
                    iconData = Icons.help_outline;
                    iconColor = PiggyTrunkTheme.ptInProgress;
                  }
                } else if (notif['type'] == 'batch_assigned') {
                  iconData = Icons.assignment_turned_in_outlined;
                  iconColor = PiggyTrunkTheme.ptSuccess;
                }

                return PopupMenuItem<void>(
                  onTap: () {
                    onMarkNotificationAsRead(notifId);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 4, right: 8),
                                decoration: const BoxDecoration(
                                  color: PiggyTrunkTheme.ptSuccess,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Icon(iconData, size: 18, color: iconColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                notif['title'] ?? 'Notification',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: EdgeInsets.only(left: isRead ? 0 : 16),
                          child: Text(
                            notif['message'] ?? '',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                              color: isDark ? Colors.grey[400] : Colors.grey[700],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: EdgeInsets.only(left: isRead ? 0 : 16),
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

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello Hog Raiser,',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: PiggyTrunkTheme.ptMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              raiserName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _brandColor,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.search, color: _brandColor),
              onPressed: () {},
            ),
            _buildNotificationBell(context),
          ],
        ),
      ],
    );
  }
}
