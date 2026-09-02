import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../../../services/locale_provider.dart';
import '../../../utils/app_strings.dart';
import '../../../utils/screen_fit_util.dart';

class PartnerProfileTab extends StatelessWidget {
  final String partnerName;
  final String partnerEmail;
  final String partnerPhone;
  final String partnerAddress;
  final String? partnerAvatarUrl;
  final VoidCallback onPickAndUploadAvatar;
  final VoidCallback onRestoreDefaultAvatar;
  final VoidCallback onShowEditProfileDialog;
  final VoidCallback onLogout;

  static const Color _brandColor = Color(0xFF18314F);

  const PartnerProfileTab({
    super.key,
    required this.partnerName,
    required this.partnerEmail,
    required this.partnerPhone,
    required this.partnerAddress,
    this.partnerAvatarUrl,
    required this.onPickAndUploadAvatar,
    required this.onRestoreDefaultAvatar,
    required this.onShowEditProfileDialog,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final fit = ScreenFit(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = AppStrings.of(context);
    final settingsProvider = SettingsProvider.of(context);
    final currentLocale = settingsProvider?.currentLocale ?? 'en';
    final currentThemeMode = settingsProvider?.themeMode ?? ThemeMode.system;

    final primaryTextColor = isDark ? Colors.white : _brandColor;
    final titleColor = isDark ? Colors.white : _brandColor;
    final labelColor = isDark ? Colors.white : _brandColor;
    final cardBgColor = isDark ? const Color(0xff151f2e) : Colors.white;
    final cardBorderColor = isDark ? const Color(0xff28354a) : PiggyTrunkTheme.ptBorder;
    final mutedTextColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;
    final subtitleColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;

    final name = (partnerName.trim().isNotEmpty && partnerName.trim().toLowerCase() != 'partner investor')
        ? partnerName.trim()
        : strings.partnerRole;
    final email = partnerEmail.trim().isNotEmpty ? partnerEmail.trim() : strings.notSet;
    final phone = (partnerPhone.trim().isNotEmpty && partnerPhone != 'N/A') ? partnerPhone.trim() : strings.notSet;
    final address = (partnerAddress.trim().isNotEmpty && partnerAddress != 'N/A') ? partnerAddress.trim() : strings.notSet;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: fit.dp(20.0), vertical: fit.dp(24.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== 1. AVATAR & NAME HEADER CARD ====================
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: onPickAndUploadAvatar,
                  child: Stack(
                    children: [
                      Container(
                        width: fit.dp(100.0),
                        height: fit.dp(100.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _brandColor, width: 2.5),
                          color: isDark ? const Color(0xff1b2638) : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: _brandColor.withValues(alpha: 0.12),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: (partnerAvatarUrl != null && partnerAvatarUrl!.isNotEmpty)
                              ? Image.network(
                                  partnerAvatarUrl!,
                                  width: fit.dp(100.0),
                                  height: fit.dp(100.0),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Padding(
                                    padding: EdgeInsets.all(fit.dp(12.0)),
                                    child: Image.asset(
                                      'assets/piggytrunk_logo.png',
                                      width: fit.dp(76.0),
                                      height: fit.dp(76.0),
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, err, st) => Container(
                                        color: Colors.white,
                                        child: const Icon(Icons.person, size: 50, color: _brandColor),
                                      ),
                                    ),
                                  ),
                                )
                              : Padding(
                                  padding: EdgeInsets.all(fit.dp(12.0)),
                                  child: Image.asset(
                                    'assets/piggytrunk_logo.png',
                                    width: fit.dp(76.0),
                                    height: fit.dp(76.0),
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, err, st) => Container(
                                      color: Colors.white,
                                      child: const Icon(Icons.person, size: 50, color: _brandColor),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(fit.dp(6)),
                          decoration: const BoxDecoration(
                            color: _brandColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: fit.dp(16),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: fit.dp(12)),
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: fit.sp(22.0),
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                  ),
                ),
                SizedBox(height: fit.dp(8)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: fit.dp(16), vertical: fit.dp(6)),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(fit.dp(20)),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    strings.partnerRole,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: fit.sp(13.5),
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: fit.dp(32.0)),

          // ==================== 2. ACCOUNT DETAILS SECTION HEADER ====================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.accountDetails,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: fit.sp(16.0),
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: onRestoreDefaultAvatar,
                    child: Row(
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: fit.dp(16),
                          color: primaryTextColor,
                        ),
                        SizedBox(width: fit.dp(4)),
                        Text(
                          strings.reset,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: fit.sp(14.0),
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: fit.dp(16)),
                  GestureDetector(
                    onTap: onShowEditProfileDialog,
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: fit.dp(16),
                          color: primaryTextColor,
                        ),
                        SizedBox(width: fit.dp(4)),
                        Text(
                          strings.edit,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: fit.sp(14.0),
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: fit.dp(16.0)),

          // ==================== 3. DETAILS LIST CARD ====================
          Container(
            padding: EdgeInsets.all(fit.dp(20.0)),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(fit.dp(20.0)),
              border: Border.all(color: cardBorderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildProfileRow(fit, isDark, Icons.email_outlined, strings.emailAddress, email, primaryTextColor, mutedTextColor),
                Divider(height: fit.dp(24.0), color: cardBorderColor),
                _buildProfileRow(fit, isDark, Icons.phone_iphone_rounded, strings.phoneNumber, phone, primaryTextColor, mutedTextColor),
                Divider(height: fit.dp(24.0), color: cardBorderColor),
                _buildProfileRow(fit, isDark, Icons.location_on_outlined, strings.farmAddress, address, primaryTextColor, mutedTextColor),
                Divider(height: fit.dp(24.0), color: cardBorderColor),
                _buildProfileRow(fit, isDark, Icons.security_rounded, strings.systemAccess, strings.partnerRole, primaryTextColor, mutedTextColor),
                Divider(height: fit.dp(24.0), color: cardBorderColor),
                _buildProfileRow(fit, isDark, Icons.verified_user_outlined, strings.accountStatus, strings.activeStatus, primaryTextColor, mutedTextColor),
              ],
            ),
          ),
          SizedBox(height: fit.dp(32.0)),

          // ==================== 4. SETTINGS & PREFERENCES ====================
          Text(
            strings.settings,
            style: GoogleFonts.plusJakartaSans(
              fontSize: fit.sp(16.0),
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          SizedBox(height: fit.dp(14.0)),

          // ---- Language Preference Card ----
          Container(
            padding: EdgeInsets.all(fit.dp(18.0)),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(fit.dp(20.0)),
              border: Border.all(color: cardBorderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(fit.dp(8)),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(fit.dp(10)),
                      ),
                      child: Icon(
                        Icons.language_rounded,
                        color: isDark ? Colors.white : _brandColor,
                        size: fit.dp(20),
                      ),
                    ),
                    SizedBox(width: fit.dp(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.languagePreference,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: fit.sp(14.0),
                              fontWeight: FontWeight.w700,
                              color: labelColor,
                            ),
                          ),
                          SizedBox(height: fit.dp(2)),
                          Text(
                            strings.languageSubtitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: fit.sp(11.5),
                              fontWeight: FontWeight.w500,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: fit.dp(16)),

                // Language Toggle Option Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildToggleOption(
                        context: context,
                        isDark: isDark,
                        title: 'English',
                        emoji: '🇺🇸',
                        isSelected: currentLocale == 'en',
                        onTap: () => settingsProvider?.setLocale('en'),
                      ),
                    ),
                    SizedBox(width: fit.dp(12)),
                    Expanded(
                      child: _buildToggleOption(
                        context: context,
                        isDark: isDark,
                        title: 'Filipino',
                        emoji: '🇵🇭',
                        isSelected: currentLocale == 'fil',
                        onTap: () => settingsProvider?.setLocale('fil'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: fit.dp(14.0)),

          // ---- App Theme Card ----
          Container(
            padding: EdgeInsets.all(fit.dp(18.0)),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(fit.dp(20.0)),
              border: Border.all(color: cardBorderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(fit.dp(8)),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(fit.dp(10)),
                      ),
                      child: Icon(
                        Icons.palette_outlined,
                        color: isDark ? Colors.white : _brandColor,
                        size: fit.dp(20),
                      ),
                    ),
                    SizedBox(width: fit.dp(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.themePreference,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: fit.sp(14.0),
                              fontWeight: FontWeight.w700,
                              color: labelColor,
                            ),
                          ),
                          SizedBox(height: fit.dp(2)),
                          Text(
                            strings.themeSubtitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: fit.sp(11.5),
                              fontWeight: FontWeight.w500,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: fit.dp(16)),

                // Theme Toggle Option Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildToggleOption(
                        context: context,
                        isDark: isDark,
                        title: strings.lightMode,
                        icon: Icons.wb_sunny_rounded,
                        isSelected: currentThemeMode == ThemeMode.light,
                        onTap: () => settingsProvider?.setThemeMode(ThemeMode.light),
                      ),
                    ),
                    SizedBox(width: fit.dp(12)),
                    Expanded(
                      child: _buildToggleOption(
                        context: context,
                        isDark: isDark,
                        title: strings.darkMode,
                        icon: Icons.nights_stay_rounded,
                        isSelected: currentThemeMode == ThemeMode.dark,
                        onTap: () => settingsProvider?.setThemeMode(ThemeMode.dark),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: fit.dp(32.0)),

          // ==================== 5. SIGN OUT BUTTON ====================
          SizedBox(
            width: double.infinity,
            height: fit.dp(54.0),
            child: OutlinedButton(
              onPressed: onLogout,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDark ? Colors.white70 : _brandColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(fit.dp(14)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    strings.signOut,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : _brandColor,
                      fontSize: fit.sp(15.0),
                    ),
                  ),
                  SizedBox(width: fit.dp(8)),
                  Icon(Icons.logout_rounded, color: isDark ? Colors.white : _brandColor, size: fit.dp(20)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Unified toggle option for both Language and Theme cards.
  Widget _buildToggleOption({
    required BuildContext context,
    required bool isDark,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    String? emoji,
    IconData? icon,
  }) {
    final activeColor = isDark ? Colors.white : _brandColor;
    final activeTextColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final inactiveBg = isDark ? const Color(0xFF151F2E) : const Color(0xFFF8FAFC);
    final inactiveBorder = isDark ? const Color(0xFF28354A) : const Color(0xFFE2E8F0);
    final inactiveText = isDark ? PiggyTrunkTheme.ptTextDark : _brandColor;
    final inactiveIconColor = isDark ? PiggyTrunkTheme.ptMutedDark : _brandColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : inactiveBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : inactiveBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark ? Colors.white : _brandColor).withValues(alpha: isDark ? 0.15 : 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (emoji != null) ...[
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
            ],
            if (icon != null) ...[
              Icon(icon, size: 18, color: isSelected ? activeTextColor : inactiveIconColor),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeTextColor : inactiveText,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle_rounded, color: activeTextColor, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(
    ScreenFit fit,
    bool isDark,
    IconData icon,
    String label,
    String value,
    Color primaryColor,
    Color mutedColor,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: fit.dp(20.0),
          color: mutedColor,
        ),
        SizedBox(width: fit.dp(14.0)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: fit.sp(12.0),
                  color: mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: fit.dp(2.0)),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: fit.sp(14.0),
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

