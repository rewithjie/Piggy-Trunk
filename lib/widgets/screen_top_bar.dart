import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../providers/admin_profile_provider.dart';

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
          /// NOTIFICATION BELL WITH BADGE
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
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    size: 22,
                  ),
                  color: textColor,
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 50,
                    minHeight: 50,
                  ),
                ),
                if (notificationCount > 0)
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
                                return Icon(
                                  Icons.person_outline,
                                  size: 18,
                                  color: isDark ? textColor.withValues(alpha: 0.9) : const Color(0xFF2F4A6A),
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.person_outline,
                            size: 18,
                            color: isDark ? textColor.withValues(alpha: 0.9) : const Color(0xFF2F4A6A),
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
}
