import 'package:flutter/material.dart';
import '../../models/admin_notification_model.dart';
import '../../providers/admin_notifications_provider.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

class NotificationFilterBar extends StatelessWidget {
  final String selectedFilter;
  final List<AdminNotification> allNotifications;
  final int unreadCount;
  final bool isDark;
  final ValueChanged<String> onFilterChanged;

  const NotificationFilterBar({
    super.key,
    required this.selectedFilter,
    required this.allNotifications,
    required this.unreadCount,
    required this.isDark,
    required this.onFilterChanged,
  });

  Widget _buildFilterPill(String filterKey, String label) {
    final isSelected = selectedFilter == filterKey;
    final bg = isSelected
        ? (isDark ? Colors.white : PiggyTrunkTheme.ptPrimary)
        : (isDark ? const Color(0xFF1E2F47) : const Color(0xFFEEF4FD));
    final fg = isSelected
        ? (isDark ? PiggyTrunkTheme.ptPrimary : Colors.white)
        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569));
    final border = isSelected
        ? Colors.transparent
        : (isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3));

    return InkWell(
      onTap: () => onFilterChanged(filterKey),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark ? Colors.white : PiggyTrunkTheme.ptPrimary).withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
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

  @override
  Widget build(BuildContext context) {
    final brandColor = isDark ? Colors.white : PiggyTrunkTheme.ptPrimary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterPill('all', 'All (${allNotifications.length})'),
                const SizedBox(width: 6),
                _buildFilterPill(
                  'registrations',
                  'Users (${allNotifications.where((n) => n.type == 'user_registration').length})',
                ),
                const SizedBox(width: 6),
                _buildFilterPill('unread', 'Unread ($unreadCount)'),
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
                color: brandColor.withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: brandColor.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.done_all_rounded,
                    size: 14,
                    color: brandColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Mark all read',
                    style: AppTextStyles.jakarta(
                      size: 11.5,
                      weight: FontWeight.w700,
                      color: brandColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
