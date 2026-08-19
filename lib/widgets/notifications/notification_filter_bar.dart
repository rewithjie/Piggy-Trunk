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
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF5D7391));
    final border = isSelected
        ? Colors.transparent
        : (isDark ? const Color(0xFF28405D) : const Color(0xFFB4C9E6));

    return InkWell(
      onTap: () => onFilterChanged(filterKey),
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

  @override
  Widget build(BuildContext context) {
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
    );
  }
}
