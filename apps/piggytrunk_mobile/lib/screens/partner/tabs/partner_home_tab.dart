import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../../../utils/screen_fit_util.dart';

class PartnerHomeTab extends StatelessWidget {
  final String partnerName;
  final double investedAmount;
  final int activeProjectsCount;
  final List<Map<String, dynamic>> activitiesList;
  final List<Map<String, dynamic>> notificationsList;
  final Future<void> Function() onRefresh;
  final VoidCallback onSeeAllActivities;
  final VoidCallback onViewProjects;
  final Function(int notificationId)? onMarkNotificationAsRead;
  final VoidCallback? onMarkAllRead;

  static const Color _brandColor = Color(0xFF18314F);

  const PartnerHomeTab({
    super.key,
    required this.partnerName,
    required this.investedAmount,
    required this.activeProjectsCount,
    required this.activitiesList,
    required this.notificationsList,
    required this.onRefresh,
    required this.onSeeAllActivities,
    required this.onViewProjects,
    this.onMarkNotificationAsRead,
    this.onMarkAllRead,
  });

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Widget _buildNotificationBell(BuildContext context, ScreenFit fit) {
    final unreadCount = notificationsList.where((n) => n['is_read'] == false).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xff151f2e) : Colors.white;
    final borderColor = isDark ? const Color(0xff28354a) : const Color(0xffe2e8f0);
    final textColor = isDark ? const Color(0xffecf2ff) : _brandColor;
    final mutedColor = isDark ? const Color(0xff9cb0c9) : Colors.grey[500];

    final double iconBgSize = fit.dp(40.0);
    final double iconSize = fit.dp(24.0);

    return PopupMenuButton<void>(
      offset: const Offset(-10, 48),
      elevation: 8,
      tooltip: 'Notifications',
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
          Container(
            width: iconBgSize,
            height: iconBgSize,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff1b2638) : const Color(0xfff8fafc),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: isDark ? const Color(0xffecf2ff) : _brandColor,
              size: iconSize,
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF5B6C),
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
                    'Notifications',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  if (unreadCount > 0 && onMarkAllRead != null)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onMarkAllRead!();
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
                        'No notifications available',
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
              final notifId = notif['notification_id'] as int?;

              return PopupMenuItem<void>(
                onTap: () {
                  if (notifId != null && onMarkNotificationAsRead != null) {
                    onMarkNotificationAsRead!(notifId);
                  }
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
                                color: Color(0xFFEF5B6C),
                                shape: BoxShape.circle,
                              ),
                            ),
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
                      Text(
                        notif['message'] ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ];
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Universal ScreenFit Auto-Scaling
    final fit = ScreenFit(context);

    final double paddingH = fit.dp(20.0);
    final double paddingV = fit.dp(20.0);

    final double greetingFontSize = fit.sp(13.0);
    final double nameFontSize = fit.sp(22.0);

    final double cardPaddingH = fit.dp(18.0);
    final double cardPaddingV = fit.dp(16.0);
    final double amountFontSize = fit.sp(26.0);
    final double projectsValueFontSize = fit.sp(18.0);
    final double actionButtonSize = fit.dp(36.0);
    final double actionIconSize = fit.dp(22.0);

    final double sectionTitleFontSize = fit.sp(16.0);
    final double activityIconBoxSize = fit.dp(42.0);
    final double activityIconSize = fit.dp(22.0);
    final double activityTitleFontSize = fit.sp(14.0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xffecf2ff) : _brandColor;
    final cardBgColor = isDark ? const Color(0xff151f2e) : Colors.white;
    final cardBorderColor = isDark ? const Color(0xff28354a) : const Color(0xffe6ebf2);
    final iconBgColor = isDark ? const Color(0xff1b2638) : const Color(0xfff0f4f8);
    final iconColor = isDark ? const Color(0xff9cb0c9) : const Color(0xff486581);

    final displayActivities = activitiesList;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: _brandColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello Partner Investor,',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: greetingFontSize,
                          fontWeight: FontWeight.w500,
                          color: isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted,
                        ),
                      ),
                      const SizedBox(height: 1),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          partnerName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: nameFontSize,
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildNotificationBell(context, fit),
              ],
            ),
            SizedBox(height: fit.dp(16.0)),

            // 2. Invested Amount Card (Compact Gradient Card)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: cardPaddingH, vertical: cardPaddingV),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(fit.dp(22)),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF18314F),
                    Color(0xFF2B4360),
                    Color(0xFF3B5270),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF18314F).withValues(alpha: 0.18),
                    blurRadius: fit.dp(12),
                    offset: Offset(0, fit.dp(6)),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invested Amount',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: fit.sp(13.0),
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  SizedBox(height: fit.dp(6.0)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      investedAmount <= 0 ? '₱ 0.00' : '₱ ${_formatCurrency(investedAmount)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: amountFontSize,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (investedAmount <= 0) ...[
                    SizedBox(height: fit.dp(4.0)),
                    Text(
                      'Make your first investment',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: fit.sp(12.0),
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: fit.dp(12.0)),

            // 3. Active Raisers Card (Compact Gradient Card)
            InkWell(
              onTap: onViewProjects,
              borderRadius: BorderRadius.circular(fit.dp(22)),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: cardPaddingH, vertical: cardPaddingV - 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(fit.dp(22)),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF18314F),
                      Color(0xFF2B4360),
                      Color(0xFF3B5270),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF18314F).withValues(alpha: 0.18),
                      blurRadius: fit.dp(12),
                      offset: Offset(0, fit.dp(6)),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Raisers',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: fit.sp(12.0),
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              activeProjectsCount <= 0
                                  ? 'No active projects'
                                  : '${activeProjectsCount.toString().padLeft(2, '0')} Projects',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: projectsValueFontSize,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: actionButtonSize,
                      height: actionButtonSize,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: const Color(0xFF18314F),
                        size: actionIconSize,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: fit.dp(24.0)),

            // 4. Section Title: Hog Raiser Activities
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Hog Raiser Activities',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: sectionTitleFontSize,
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                    letterSpacing: -0.3,
                  ),
                ),
                TextButton(
                  onPressed: onSeeAllActivities,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'See all',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: fit.sp(14.0),
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xffecf2ff) : const Color(0xFF18314F),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: fit.dp(14.0)),

            // 5. Activity List Cards
            if (displayActivities.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(fit.dp(24)),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(fit.dp(20)),
                  border: Border.all(color: cardBorderColor, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined, size: fit.dp(36), color: iconColor),
                    SizedBox(height: fit.dp(8)),
                    Text(
                      'No recent activities',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: fit.sp(14.0),
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    SizedBox(height: fit.dp(4)),
                    Text(
                      'Activities from your hog raisers will appear here',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: fit.sp(12.0),
                        fontWeight: FontWeight.w500,
                        color: isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...displayActivities.map((act) {
                final String title = act['title'] ?? 'Activity Update';
                final String date = act['date'] ?? act['created_at'] ?? '';
                final IconData icon = (act['icon'] is IconData)
                    ? act['icon'] as IconData
                    : Icons.assignment_outlined;

                return Container(
                  margin: EdgeInsets.only(bottom: fit.dp(10)),
                  padding: EdgeInsets.symmetric(
                    horizontal: fit.dp(16.0),
                    vertical: fit.dp(16.0),
                  ),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(fit.dp(20)),
                    border: Border.all(color: cardBorderColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: activityIconBoxSize,
                        height: activityIconBoxSize,
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: activityIconSize,
                        ),
                      ),
                      SizedBox(width: fit.dp(16.0)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: activityTitleFontSize,
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              date,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: fit.sp(12.0),
                                fontWeight: FontWeight.w500,
                                color: isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
