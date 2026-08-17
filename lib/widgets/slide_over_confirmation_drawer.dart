import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

enum SlideOverActionType {
  danger,   // For Rejection, Delete, Suspend, Clear All (Red)
  success,  // For Approval, Activation (Green)
  warning,  // For Status Change, Archive, Reset (Amber)
  info,     // For Confirmation (Blue)
}

/// Universal Slide-Over Right Drawer for Action Confirmations
class SlideOverConfirmationDrawer extends StatelessWidget {
  final String title;
  final String message;
  final SlideOverActionType actionType;
  final String? userName;
  final String? userEmail;
  final String? userRole;
  final String? avatarUrl;
  final String confirmButtonText;
  final String cancelButtonText;
  final IconData? customIcon;

  const SlideOverConfirmationDrawer({
    super.key,
    required this.title,
    required this.message,
    this.actionType = SlideOverActionType.danger,
    this.userName,
    this.userEmail,
    this.userRole,
    this.avatarUrl,
    this.confirmButtonText = 'Confirm',
    this.cancelButtonText = 'Cancel',
    this.customIcon,
  });

  /// Static helper to trigger the Slide-Over Drawer with smooth slide transition
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    SlideOverActionType actionType = SlideOverActionType.danger,
    String? userName,
    String? userEmail,
    String? userRole,
    String? avatarUrl,
    String confirmButtonText = 'Confirm',
    String cancelButtonText = 'Cancel',
    IconData? customIcon,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Action Confirmation',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: SlideOverConfirmationDrawer(
            title: title,
            message: message,
            actionType: actionType,
            userName: userName,
            userEmail: userEmail,
            userRole: userRole,
            avatarUrl: avatarUrl,
            confirmButtonText: confirmButtonText,
            cancelButtonText: cancelButtonText,
            customIcon: customIcon,
          ),
        );
      },
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curvedAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnim),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Core Layout Colors
    final surfaceColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final titleTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final drawerWidth = isMobile ? screenWidth : 420.0;

    // Rich Dark/Light Mode Theme Tokens per Action Type
    Color accentColor;
    Color iconBadgeBg;
    Color iconBadgeBorder;
    Color alertBg;
    Color alertBorder;
    Color alertTextColor;
    IconData defaultIcon;

    switch (actionType) {
      case SlideOverActionType.danger:
        accentColor = isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626);
        iconBadgeBg = isDark ? const Color(0xFF3B1215) : const Color(0xFFFEE2E2);
        iconBadgeBorder = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA);
        alertBg = isDark ? const Color(0xFF241014) : const Color(0xFFFEF2F2);
        alertBorder = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA);
        alertTextColor = isDark ? const Color(0xFFFEE2E2) : const Color(0xFF991B1B);
        defaultIcon = Icons.cancel_outlined;
        break;

      case SlideOverActionType.success:
        accentColor = isDark ? const Color(0xFF22C55E) : const Color(0xFF16A34A);
        iconBadgeBg = isDark ? const Color(0xFF0B2917) : const Color(0xFFDCFCE7);
        iconBadgeBorder = isDark ? const Color(0xFF14532D) : const Color(0xFFBBF7D0);
        alertBg = isDark ? const Color(0xFF081C10) : const Color(0xFFF0FDF4);
        alertBorder = isDark ? const Color(0xFF14532D) : const Color(0xFFBBF7D0);
        alertTextColor = isDark ? const Color(0xFFDCFCE7) : const Color(0xFF166534);
        defaultIcon = Icons.check_circle_outline_rounded;
        break;

      case SlideOverActionType.warning:
        accentColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706);
        iconBadgeBg = isDark ? const Color(0xFF332008) : const Color(0xFFFEF3C7);
        iconBadgeBorder = isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A);
        alertBg = isDark ? const Color(0xFF221505) : const Color(0xFFFFFBEB);
        alertBorder = isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A);
        alertTextColor = isDark ? const Color(0xFFFEF3C7) : const Color(0xFF92400E);
        defaultIcon = Icons.warning_amber_rounded;
        break;

      case SlideOverActionType.info:
        accentColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);
        iconBadgeBg = isDark ? const Color(0xFF112240) : const Color(0xFFDBEAFE);
        iconBadgeBorder = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBFDBFE);
        alertBg = isDark ? const Color(0xFF0C1628) : const Color(0xFFEFF6FF);
        alertBorder = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBFDBFE);
        alertTextColor = isDark ? const Color(0xFFDBEAFE) : const Color(0xFF1E40AF);
        defaultIcon = Icons.info_outline_rounded;
        break;
    }

    final actionIcon = customIcon ?? defaultIcon;

    final initials = (userName != null && userName!.trim().isNotEmpty)
        ? userName!.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join('').toUpperCase()
        : 'US';

    return Material(
      color: Colors.transparent,
      child: Container(
        width: drawerWidth,
        height: double.infinity,
        decoration: BoxDecoration(
          color: surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
              blurRadius: 32,
              spreadRadius: 2,
              offset: const Offset(-6, 0),
            ),
          ],
          border: Border(
            left: BorderSide(color: borderColor, width: 1.2),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================== DRAWER HEADER ====================
              Container(
                padding: EdgeInsets.fromLTRB(isMobile ? 16 : 20, 18, isMobile ? 12 : 16, 16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: iconBadgeBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: iconBadgeBorder, width: 1),
                            ),
                            child: Icon(
                              actionIcon,
                              color: accentColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: AppTextStyles.jakarta(
                                size: 17,
                                weight: FontWeight.w800,
                                color: titleTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: mutedTextColor, size: 20),
                      tooltip: 'Close',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ],
                ),
              ),

              // ==================== DRAWER BODY ====================
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Profile Context Card (if provided)
                      if (userName != null || userEmail != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF131F33) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF223552) : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isDark ? Colors.white : PiggyTrunkTheme.ptPrimary).withValues(alpha: isDark ? 0.25 : 0.15),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: AppTextStyles.jakarta(
                                      size: 16,
                                      weight: FontWeight.w800,
                                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (userName != null)
                                      Text(
                                        userName!,
                                        style: AppTextStyles.jakarta(
                                          size: 15,
                                          weight: FontWeight.w700,
                                          color: titleTextColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    if (userEmail != null && userEmail!.isNotEmpty)
                                      Text(
                                        userEmail!,
                                        style: AppTextStyles.jakarta(
                                          size: 12.5,
                                          weight: FontWeight.w500,
                                          color: mutedTextColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    if (userRole != null && userRole!.isNotEmpty) ...[
                                      const SizedBox(height: 5),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF172844) : const Color(0xFFEEF4FF),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF2563EB).withValues(alpha: 0.4) : const Color(0xFFBFDBFE),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          userRole!.toUpperCase(),
                                          style: AppTextStyles.jakarta(
                                            size: 10,
                                            weight: FontWeight.w700,
                                            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Message Container (Crisp, High-Contrast & Beautiful in both Dark & Light)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: alertBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: alertBorder,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              actionIcon,
                              color: accentColor,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                message,
                                style: AppTextStyles.jakarta(
                                  size: 13.5,
                                  weight: FontWeight.w500,
                                  color: alertTextColor,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ==================== DRAWER FOOTER ACTIONS ====================
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(top: BorderSide(color: borderColor, width: 1)),
                ),
                child: Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          foregroundColor: isDark ? Colors.white : const Color(0xFF334155),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          cancelButtonText,
                          style: AppTextStyles.jakarta(
                            size: 13.5,
                            weight: FontWeight.w700,
                            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Confirm Action Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(actionIcon, size: 16, color: Colors.white),
                        label: Text(
                          confirmButtonText,
                          style: AppTextStyles.jakarta(
                            size: 13.5,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
