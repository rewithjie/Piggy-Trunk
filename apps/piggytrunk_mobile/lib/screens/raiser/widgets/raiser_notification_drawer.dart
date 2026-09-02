import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../../../utils/app_strings.dart';
import '../../../widgets/piggy_toast.dart';
import 'raiser_empty_state.dart';

void showRaiserNotificationDrawer({
  required BuildContext context,
  required List<Map<String, dynamic>> notificationsList,
  required VoidCallback onRefreshNotifications,
  required Function(int notificationId) onMarkNotificationAsRead,
  required VoidCallback onMarkAllRead,
  Function(int index)? onNavigateToTab,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _RaiserNotificationDrawerContent(
      notificationsList: notificationsList,
      onRefreshNotifications: onRefreshNotifications,
      onMarkNotificationAsRead: onMarkNotificationAsRead,
      onMarkAllRead: onMarkAllRead,
      onNavigateToTab: onNavigateToTab,
    ),
  );
}

class _RaiserNotificationDrawerContent extends StatefulWidget {
  final List<Map<String, dynamic>> notificationsList;
  final VoidCallback onRefreshNotifications;
  final Function(int notificationId) onMarkNotificationAsRead;
  final VoidCallback onMarkAllRead;
  final Function(int index)? onNavigateToTab;

  const _RaiserNotificationDrawerContent({
    required this.notificationsList,
    required this.onRefreshNotifications,
    required this.onMarkNotificationAsRead,
    required this.onMarkAllRead,
    this.onNavigateToTab,
  });

  @override
  State<_RaiserNotificationDrawerContent> createState() => _RaiserNotificationDrawerContentState();
}

class _RaiserNotificationDrawerContentState extends State<_RaiserNotificationDrawerContent> {
  static const Color _brandColor = Color(0xFF18314F);
  static const Color _brandBlue = Color(0xFF2563EB);

  String _selectedFilter = 'All'; // 'All', 'Requests', 'Approved', 'Rejected'

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedFilter == 'All') return widget.notificationsList;
    return widget.notificationsList.where((n) {
      final type = (n['type'] ?? n['category'] ?? '').toString().toLowerCase();
      final title = (n['title'] ?? '').toString().toLowerCase();
      final message = (n['message'] ?? n['content'] ?? '').toString().toLowerCase();

      if (_selectedFilter == 'Requests') {
        return type.contains('request') ||
            type.contains('stock') ||
            title.contains('request') ||
            title.contains('kahilingan') ||
            message.contains('request');
      } else if (_selectedFilter == 'Approved') {
        return type.contains('approved') ||
            title.contains('approved') ||
            title.contains('naaprubahan') ||
            message.contains('approved');
      } else if (_selectedFilter == 'Rejected') {
        return type.contains('rejected') ||
            title.contains('rejected') ||
            title.contains('tinanggihan') ||
            message.contains('rejected');
      }
      return true;
    }).toList();
  }

  void _handleMarkAllAsRead() {
    widget.onMarkAllRead();
    final strings = AppStrings.of(context);
    PiggyToast.showSuccess(
      context,
      strings.isFilipino
          ? 'Lahat ng notification ay minarkahan nang nabasa.'
          : 'All notifications marked as read.',
    );
  }

  String _formatTime(dynamic dateValue) {
    if (dateValue == null) return '';
    try {
      final DateTime dt = dateValue is DateTime ? dateValue : DateTime.parse(dateValue.toString());
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Kani-kanina lang';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ang nakalipas';
      if (diff.inHours < 24) return '${diff.inHours}h ang nakalipas';
      if (diff.inDays < 7) return '${diff.inDays}d ang nakalipas';
      return '${dt.month}/${dt.day}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
    final sheetBorder = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
    final textColor = isDark ? PiggyTrunkTheme.ptTextDark : _brandColor;
    final mutedColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;

    final unreadCount = widget.notificationsList.where((n) => n['is_read'] == false).length;
    final displayList = _filteredNotifications;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 6),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // Drawer Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.notifications_active_rounded, color: isDark ? const Color(0xFF38BDF8) : _brandBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              strings.notificationsTitle,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          strings.notificationsSubtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: mutedColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unreadCount > 0)
                    GestureDetector(
                      onTap: _handleMarkAllAsRead,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFDBEAFE)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.done_all_rounded, color: isDark ? const Color(0xFF38BDF8) : _brandBlue, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              strings.markAllRead,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF38BDF8) : _brandBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Filter Tabs Bar (Lahat, Requests, Approved, Rejected)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  Expanded(child: _buildFilterTab('All', '${strings.filterAll} (${widget.notificationsList.length})')),
                  const SizedBox(width: 6),
                  Expanded(child: _buildFilterTab('Requests', strings.request)),
                  const SizedBox(width: 6),
                  Expanded(child: _buildFilterTab('Approved', strings.filterApproved)),
                  const SizedBox(width: 6),
                  Expanded(child: _buildFilterTab('Rejected', strings.filterRejected)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Notifications List
            Expanded(
              child: displayList.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: RaiserEmptyState(
                          icon: Icons.notifications_none_rounded,
                          message: strings.noNotifications,
                          subtitle: strings.noNotificationsSubtitle,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        final notif = displayList[index];
                        final isRead = notif['is_read'] == true;
                        final notifId = (notif['notification_id'] ?? notif['id']) as int?;
                        final title = (notif['title'] ?? 'Notification').toString();
                        final message = (notif['message'] ?? notif['content'] ?? '').toString();
                        final timeStr = _formatTime(notif['created_at']);
                        final type = (notif['type'] ?? notif['category'] ?? '').toString().toLowerCase();

                        IconData notifIcon = Icons.notifications_rounded;
                        Color iconColor = isDark ? const Color(0xFF38BDF8) : _brandBlue;
                        Color iconBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF);

                        if (type.contains('stock') || type.contains('request')) {
                          notifIcon = Icons.inventory_2_rounded;
                          iconColor = const Color(0xFFF59E0B);
                          iconBg = isDark ? const Color(0xFF78350F) : const Color(0xFFFFFBEB);
                        } else if (type.contains('health') || type.contains('sick')) {
                          notifIcon = Icons.health_and_safety_rounded;
                          iconColor = const Color(0xFFEF4444);
                          iconBg = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2);
                        } else if (type.contains('batch') || type.contains('stage') || type.contains('hog')) {
                          notifIcon = Icons.pets_rounded;
                          iconColor = const Color(0xFF10B981);
                          iconBg = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
                        }

                        final itemBg = isRead
                            ? (isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white)
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC));
                        final itemBorder = isRead
                            ? sheetBorder
                            : (isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.4) : const Color(0xFFCBD5E1));

                        return GestureDetector(
                          onTap: () {
                            if (!isRead && notifId != null) {
                              widget.onMarkNotificationAsRead(notifId);
                            }
                            // Auto close the notification bottom sheet
                            Navigator.of(context).pop();

                            // Redirect to matching screen
                            if (widget.onNavigateToTab != null) {
                              final lowerType = type.toLowerCase();
                              final lowerTitle = title.toLowerCase();
                              final lowerMsg = message.toLowerCase();

                              if (lowerType.contains('stock') ||
                                  lowerType.contains('request') ||
                                  lowerTitle.contains('request') ||
                                  lowerMsg.contains('request') ||
                                  lowerTitle.contains('stock') ||
                                  lowerMsg.contains('stock')) {
                                widget.onNavigateToTab!(1); // Request Screen
                              } else if (lowerType.contains('health') ||
                                  lowerType.contains('sick') ||
                                  lowerType.contains('hog') ||
                                  lowerType.contains('batch') ||
                                  lowerType.contains('stage') ||
                                  lowerTitle.contains('hog')) {
                                widget.onNavigateToTab!(2); // Hogs Screen
                              } else {
                                widget.onNavigateToTab!(1); // Default to Request screen
                              }
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: itemBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: itemBorder,
                                width: isRead ? 1 : 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: iconBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(notifIcon, color: iconColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13.5,
                                                fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                                color: textColor,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            timeStr,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: mutedColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (message.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          message,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: isRead ? mutedColor : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                            fontWeight: isRead ? FontWeight.w400 : FontWeight.w500,
                                          ),
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (!isRead) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(top: 6),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF38BDF8) : _brandBlue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String key, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedFilter == key;
    final selectedBg = isDark ? Colors.white : _brandColor;
    final selectedText = isDark ? const Color(0xFF0F172A) : Colors.white;
    final inactiveBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final inactiveText = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : inactiveBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? selectedText : inactiveText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
