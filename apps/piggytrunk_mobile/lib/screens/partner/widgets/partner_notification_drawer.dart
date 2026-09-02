import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../../../utils/screen_fit_util.dart';
import '../../../utils/app_strings.dart';

void showPartnerNotificationDrawer({
  required BuildContext context,
  required List<Map<String, dynamic>> notifications,
  required Function(int) onMarkAsRead,
  required VoidCallback onMarkAllAsRead,
  Function(int tabIndex)? onNavigateToTab,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PartnerNotificationDrawerContent(
      notifications: notifications,
      onMarkAsRead: onMarkAsRead,
      onMarkAllAsRead: onMarkAllAsRead,
      onNavigateToTab: onNavigateToTab,
    ),
  );
}

class _PartnerNotificationDrawerContent extends StatefulWidget {
  final List<Map<String, dynamic>> notifications;
  final Function(int) onMarkAsRead;
  final VoidCallback onMarkAllAsRead;
  final Function(int tabIndex)? onNavigateToTab;

  const _PartnerNotificationDrawerContent({
    required this.notifications,
    required this.onMarkAsRead,
    required this.onMarkAllAsRead,
    this.onNavigateToTab,
  });

  @override
  State<_PartnerNotificationDrawerContent> createState() => _PartnerNotificationDrawerContentState();
}

class _PartnerNotificationDrawerContentState extends State<_PartnerNotificationDrawerContent> {
  static const Color _brandColor = Color(0xFF18314F);
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _accentBlue = Color(0xFF3B82F6);
  static const Color _accentAmber = Color(0xFFF59E0B);
  static const Color _accentPurple = Color(0xFF8B5CF6);

  String _selectedFilter = 'All'; // 'All', 'Hog Updates', 'Investments', 'Stage Progress'

  String _formatTime(dynamic dateValue) {
    if (dateValue == null) return 'Just now';
    try {
      final dt = DateTime.parse(dateValue.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.month}/${dt.day}/${dt.year}';
    } catch (_) {
      return 'Recent';
    }
  }

  IconData _getIconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('invest') || t.contains('fund')) {
      return Icons.account_balance_wallet_rounded;
    } else if (t.contains('stage') || t.contains('progress') || t.contains('lifecycle')) {
      return Icons.trending_up_rounded;
    } else if (t.contains('health') || t.contains('sick') || t.contains('medical')) {
      return Icons.medical_services_rounded;
    } else if (t.contains('feed') || t.contains('weight') || t.contains('routine')) {
      return Icons.scale_rounded;
    } else {
      return Icons.notifications_active_rounded;
    }
  }

  Color _getColorForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('invest') || t.contains('fund')) {
      return _accentGreen;
    } else if (t.contains('stage') || t.contains('progress')) {
      return _accentBlue;
    } else if (t.contains('health') || t.contains('sick') || t.contains('medical')) {
      return Colors.redAccent;
    } else if (t.contains('feed') || t.contains('weight') || t.contains('routine')) {
      return _accentAmber;
    } else {
      return _accentPurple;
    }
  }

  List<Map<String, dynamic>> _getFilteredNotifications() {
    if (_selectedFilter == 'All') return widget.notifications;

    return widget.notifications.where((n) {
      final type = (n['type'] as String?)?.toLowerCase() ?? '';
      final title = (n['title'] as String?)?.toLowerCase() ?? '';
      final msg = (n['message'] as String?)?.toLowerCase() ?? '';

      if (_selectedFilter == 'Hog Updates') {
        return type.contains('report') ||
            type.contains('health') ||
            title.contains('raiser') ||
            title.contains('update') ||
            msg.contains('logged');
      } else if (_selectedFilter == 'Investments') {
        return type.contains('invest') || title.contains('investment') || msg.contains('invest');
      } else if (_selectedFilter == 'Stage Progress') {
        return type.contains('stage') || title.contains('stage') || msg.contains('progress');
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final fit = ScreenFit(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final primaryTextColor = isDark ? const Color(0xFFECF2FF) : _brandColor;
    final cardBorder = isDark ? const Color(0xFF28354A) : const Color(0xFFE2E8F0);

    final filteredList = _getFilteredNotifications();
    final unreadCount = widget.notifications.where((n) => n['is_read'] != true).length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle Pill
          Container(
            margin: EdgeInsets.only(top: fit.dp(10), bottom: fit.dp(6)),
            width: fit.dp(42),
            height: fit.dp(4.5),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Drawer Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: fit.dp(20), vertical: fit.dp(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(fit.dp(8)),
                      decoration: BoxDecoration(
                        color: _brandColor.withValues(alpha: isDark ? 0.3 : 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_rounded,
                        size: fit.dp(20),
                        color: isDark ? const Color(0xFF93C5FD) : _brandColor,
                      ),
                    ),
                    SizedBox(width: fit.dp(10)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Partner Notifications',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: fit.sp(17),
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor,
                          ),
                        ),
                        if (unreadCount > 0)
                          Text(
                            '$unreadCount new update${unreadCount > 1 ? 's' : ''}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: fit.sp(12),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          )
                        else
                          Text(
                            'All caught up',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: fit.sp(12),
                              fontWeight: FontWeight.w500,
                              color: isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (unreadCount > 0)
                      TextButton(
                        onPressed: () {
                          widget.onMarkAllAsRead();
                          setState(() {});
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: fit.dp(10), vertical: fit.dp(4)),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Mark all read',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: fit.sp(12.5),
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF93C5FD) : _brandColor,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: fit.dp(20), color: isDark ? Colors.white70 : Colors.grey[700]),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: fit.dp(16), vertical: fit.dp(6)),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip(fit, 'All', isDark),
                SizedBox(width: fit.dp(8)),
                _buildFilterChip(fit, 'Hog Updates', isDark),
                SizedBox(width: fit.dp(8)),
                _buildFilterChip(fit, 'Investments', isDark),
                SizedBox(width: fit.dp(8)),
                _buildFilterChip(fit, 'Stage Progress', isDark),
              ],
            ),
          ),

          const Divider(height: 12, thickness: 1),

          // Notifications List / Empty State
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState(fit, isDark)
                : ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: fit.dp(16), vertical: fit.dp(12)),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredList.length,
                    separatorBuilder: (context, index) => SizedBox(height: fit.dp(10)),
                    itemBuilder: (ctx, index) {
                      final notif = filteredList[index];
                      final notifId = (notif['notification_id'] as num?)?.toInt() ?? index;
                      final title = notif['title']?.toString() ?? 'Batch Update';
                      final message = notif['message']?.toString() ?? 'No description provided.';
                      final type = notif['type']?.toString() ?? 'general';
                      final isRead = notif['is_read'] == true;
                      final createdAt = notif['created_at'];

                      final icon = _getIconForType(type);
                      final color = _getColorForType(type);

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (!isRead) {
                              widget.onMarkAsRead(notifId);
                              setState(() {});
                            }
                            if (type.contains('invest') && widget.onNavigateToTab != null) {
                              Navigator.pop(context);
                              widget.onNavigateToTab!(1); // Go to Investment
                            } else if (type.contains('report') && widget.onNavigateToTab != null) {
                              Navigator.pop(context);
                              widget.onNavigateToTab!(2); // Go to Activities
                            }
                          },
                          borderRadius: BorderRadius.circular(fit.dp(16)),
                          child: Container(
                            padding: EdgeInsets.all(fit.dp(14)),
                            decoration: BoxDecoration(
                              color: isRead
                                  ? (isDark ? const Color(0xFF131F33) : const Color(0xFFF8FAFC))
                                  : (isDark ? const Color(0xFF1B2B45) : const Color(0xFFEFF6FF)),
                              borderRadius: BorderRadius.circular(fit.dp(16)),
                              border: Border.all(
                                color: isRead ? cardBorder : color.withValues(alpha: 0.4),
                                width: isRead ? 1 : 1.4,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(fit.dp(9)),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: isDark ? 0.25 : 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icon, size: fit.dp(20), color: color),
                                ),
                                SizedBox(width: fit.dp(12)),
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
                                                fontSize: fit.sp(13.5),
                                                fontWeight: isRead ? FontWeight.w700 : FontWeight.w800,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _formatTime(createdAt),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: fit.sp(11),
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: fit.dp(4)),
                                      Text(
                                        message,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: fit.sp(12),
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isRead) ...[
                                  SizedBox(width: fit.dp(8)),
                                  Container(
                                    width: fit.dp(8),
                                    height: fit.dp(8),
                                    margin: EdgeInsets.only(top: fit.dp(4)),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ScreenFit fit, String label, bool isDark) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: fit.dp(14), vertical: fit.dp(7)),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF3B82F6) : _brandColor)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(fit.dp(20)),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: fit.sp(12),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ScreenFit fit, bool isDark) {
    final strings = AppStrings.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: fit.dp(30)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(fit.dp(16)),
              decoration: BoxDecoration(
                color: _brandColor.withValues(alpha: isDark ? 0.25 : 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: fit.dp(36),
                color: isDark ? const Color(0xFF93C5FD) : _brandColor,
              ),
            ),
            SizedBox(height: fit.dp(12)),
            Text(
              strings.noNotifications,
              style: GoogleFonts.plusJakartaSans(
                fontSize: fit.sp(15),
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : _brandColor,
              ),
            ),
            SizedBox(height: fit.dp(4)),
            Text(
              strings.noNotificationsSubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: fit.sp(12.0),
                fontWeight: FontWeight.w500,
                color: isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
