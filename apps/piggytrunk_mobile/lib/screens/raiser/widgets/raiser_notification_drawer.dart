import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
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

  String _selectedFilter = 'All'; // 'All', 'Requests', 'Farm'

  String _formatTime(String? dateStr) {
    if (dateStr == null) return 'Recent';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return 'Recent';
    }
  }

  void _handleMarkAllAsRead() {
    widget.onMarkAllRead();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.done_all_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Lahat ng notification ay namarkahan nang nabasa',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF047857),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedFilter == 'All') return widget.notificationsList;
    if (_selectedFilter == 'Requests') {
      return widget.notificationsList.where((n) {
        final t = (n['type'] ?? n['category'] ?? '').toString().toLowerCase();
        final title = (n['title'] ?? '').toString().toLowerCase();
        final msg = (n['message'] ?? n['content'] ?? '').toString().toLowerCase();
        return t.contains('request') || t.contains('stock') || title.contains('request') || msg.contains('request');
      }).toList();
    }
    if (_selectedFilter == 'Approved') {
      return widget.notificationsList.where((n) {
        final t = (n['type'] ?? n['category'] ?? '').toString().toLowerCase();
        final title = (n['title'] ?? '').toString().toLowerCase();
        final msg = (n['message'] ?? n['content'] ?? '').toString().toLowerCase();
        return msg.contains('approved') || title.contains('approved') || t.contains('approved');
      }).toList();
    }
    if (_selectedFilter == 'Rejected') {
      return widget.notificationsList.where((n) {
        final t = (n['type'] ?? n['category'] ?? '').toString().toLowerCase();
        final title = (n['title'] ?? '').toString().toLowerCase();
        final msg = (n['message'] ?? n['content'] ?? '').toString().toLowerCase();
        return msg.contains('rejected') || title.contains('rejected') || t.contains('rejected');
      }).toList();
    }
    return widget.notificationsList;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = widget.notificationsList.where((n) => n['is_read'] == false).length;
    final displayList = _filteredNotifications;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
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
                color: Colors.grey[300],
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
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: _brandBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Mga Notification',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _brandColor,
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
                          'Live updates mula sa farm at requests',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: PiggyTrunkTheme.ptMuted,
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
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.done_all_rounded, color: _brandBlue, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Mark read',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: _brandBlue,
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
                  Expanded(child: _buildFilterTab('All', 'Lahat (${widget.notificationsList.length})')),
                  const SizedBox(width: 6),
                  Expanded(child: _buildFilterTab('Requests', 'Requests')),
                  const SizedBox(width: 6),
                  Expanded(child: _buildFilterTab('Approved', 'Approved')),
                  const SizedBox(width: 6),
                  Expanded(child: _buildFilterTab('Rejected', 'Rejected')),
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
                          message: 'Walang notification sa kasalukuyan.',
                          subtitle: 'Ang mga update tungkol sa mga request, alaga, at anunsyo ay lalabas dito.',
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
                        Color iconColor = _brandBlue;
                        Color iconBg = const Color(0xFFEFF6FF);

                        if (type.contains('stock') || type.contains('request')) {
                          notifIcon = Icons.inventory_2_rounded;
                          iconColor = const Color(0xFFF59E0B);
                          iconBg = const Color(0xFFFFFBEB);
                        } else if (type.contains('health') || type.contains('sick')) {
                          notifIcon = Icons.health_and_safety_rounded;
                          iconColor = const Color(0xFFEF4444);
                          iconBg = const Color(0xFFFEF2F2);
                        } else if (type.contains('batch') || type.contains('stage') || type.contains('hog')) {
                          notifIcon = Icons.pets_rounded;
                          iconColor = const Color(0xFF10B981);
                          iconBg = const Color(0xFFECFDF5);
                        }

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
                              color: isRead ? Colors.white : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isRead ? PiggyTrunkTheme.ptBorder : const Color(0xFFCBD5E1),
                                width: isRead ? 1 : 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
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
                                                color: _brandColor,
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
                                              color: PiggyTrunkTheme.ptMuted,
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
                                            color: isRead ? PiggyTrunkTheme.ptMuted : const Color(0xFF475569),
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
                                    decoration: const BoxDecoration(
                                      color: _brandBlue,
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
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? _brandColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : PiggyTrunkTheme.ptMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
