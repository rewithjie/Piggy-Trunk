import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../providers/admin_profile_provider.dart';

/// Reusable Top Bar Widget with Notification & Admin Profile (No Title)
class ScreenTopBar extends ConsumerWidget {
  final int notificationCount;
  final String? adminName;
  final String? adminRole;
  final bool showDivider;

  const ScreenTopBar({
    Key? key,
    this.notificationCount = 1,
    this.adminName = 'Admin',
    this.adminRole = 'SYSTEM ADMINISTRATOR',
    this.showDivider = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminProfile = ref.watch(adminProfileProvider);
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
          /// NOTIFICATION BELL WITH BADGE
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    size: 24,
                  ),
                  color: textColor,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifications coming soon'),
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                if (notificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: accentDark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          notificationCount.toString(),
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
          ),
          /// ADMIN PROFILE (CLICKABLE)
              GestureDetector(
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
                      color: accentDark.withOpacity(0.2),
                    ),
                    child: adminProfile.profilePictureUrl != null &&
                            adminProfile.profilePictureUrl!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              adminProfile.profilePictureUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 16,
                                  color: textColor,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 16,
                            color: textColor,
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
                              adminProfile.adminName,
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
                              adminProfile.role.toUpperCase(),
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
                ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
