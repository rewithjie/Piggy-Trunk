import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
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
    final double paddingH = fit.dp(20.0);
    final double paddingV = fit.dp(20.0);
    final double titleFontSize = fit.sp(22.0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xffecf2ff) : _brandColor;
    final cardBgColor = isDark ? const Color(0xff151f2e) : Colors.white;
    final cardBorderColor = isDark ? const Color(0xff28354a) : const Color(0xffe6ebf2);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Partner Investor Profile',
            style: GoogleFonts.plusJakartaSans(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w800,
              color: primaryTextColor,
              letterSpacing: -0.4,
            ),
          ),
          SizedBox(height: fit.dp(20.0)),

          // 1. Avatar & Profile Header Card (Default PiggyTrunk Logo)
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: onPickAndUploadAvatar,
                  child: Stack(
                    children: [
                      Container(
                        width: fit.dp(96.0),
                        height: fit.dp(96.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _brandColor, width: 2),
                          color: isDark ? const Color(0xff1b2638) : const Color(0xfff7f8fb),
                        ),
                        child: ClipOval(
                          child: partnerAvatarUrl != null && partnerAvatarUrl!.isNotEmpty
                              ? Image.network(
                                  partnerAvatarUrl!,
                                  width: fit.dp(96.0),
                                  height: fit.dp(96.0),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Image.asset(
                                    'assets/piggytrunk_logo.png',
                                    width: fit.dp(96.0),
                                    height: fit.dp(96.0),
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, err, st) => Container(
                                      color: _brandColor,
                                      child: const Icon(Icons.person, size: 48, color: Colors.white),
                                    ),
                                  ),
                                )
                              : Image.asset(
                                  'assets/piggytrunk_logo.png',
                                  width: fit.dp(96.0),
                                  height: fit.dp(96.0),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, err, st) => Container(
                                    color: _brandColor,
                                    child: const Icon(Icons.person, size: 48, color: Colors.white),
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
                  partnerName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: fit.sp(20.0),
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                  ),
                ),
                SizedBox(height: fit.dp(4)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: fit.dp(10), vertical: fit.dp(4)),
                  decoration: BoxDecoration(
                    color: _brandColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(fit.dp(12)),
                  ),
                  child: Text(
                    'Partner Investor',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: fit.sp(12.0),
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xffecf2ff) : _brandColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: fit.dp(24.0)),

          // 2. Account Information Section Header with Edit & Reset Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Account Information',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: fit.sp(15.0),
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor,
                ),
              ),
              Row(
                children: [
                  if (partnerAvatarUrl != null && partnerAvatarUrl!.isNotEmpty) ...[
                    GestureDetector(
                      onTap: onRestoreDefaultAvatar,
                      child: Row(
                        children: [
                          Icon(Icons.refresh_rounded, size: fit.dp(16), color: isDark ? const Color(0xffecf2ff) : _brandColor),
                          SizedBox(width: fit.dp(4)),
                          Text(
                            'Reset Avatar',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: fit.sp(13.0),
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xffecf2ff) : _brandColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: fit.dp(14)),
                  ],
                  GestureDetector(
                    onTap: onShowEditProfileDialog,
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: fit.dp(16), color: isDark ? const Color(0xffecf2ff) : _brandColor),
                        SizedBox(width: fit.dp(4)),
                        Text(
                          'Edit Profile',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: fit.sp(13.0),
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xffecf2ff) : _brandColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: fit.dp(12.0)),

          // 3. Account Details Container
          Container(
            padding: EdgeInsets.all(fit.dp(18.0)),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(fit.dp(22)),
              border: Border.all(color: cardBorderColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(context, fit, Icons.email_outlined, 'Email Address', partnerEmail),
                SizedBox(height: fit.dp(10.0)),
                Divider(color: cardBorderColor, height: 1),
                SizedBox(height: fit.dp(10.0)),
                _buildInfoRow(context, fit, Icons.phone_outlined, 'Phone Number', partnerPhone),
                SizedBox(height: fit.dp(10.0)),
                Divider(color: cardBorderColor, height: 1),
                SizedBox(height: fit.dp(10.0)),
                _buildInfoRow(context, fit, Icons.location_on_outlined, 'Address', partnerAddress),
                SizedBox(height: fit.dp(10.0)),
                Divider(color: cardBorderColor, height: 1),
                SizedBox(height: fit.dp(10.0)),
                _buildInfoRow(context, fit, Icons.security_outlined, 'System Role', 'Partner Investor'),
              ],
            ),
          ),
          SizedBox(height: fit.dp(24.0)),

          // 4. Logout Button
          SizedBox(
            width: double.infinity,
            height: fit.dp(44.0),
            child: ElevatedButton.icon(
              onPressed: onLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(fit.dp(14)),
                ),
              ),
              icon: Icon(Icons.logout_rounded, size: fit.dp(18.0)),
              label: Text(
                'Log Out',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: fit.sp(14.0),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, ScreenFit fit, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xffecf2ff) : _brandColor;
    final mutedTextColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;

    return Row(
      children: [
        Icon(
          icon,
          size: fit.dp(20.0),
          color: mutedTextColor,
        ),
        SizedBox(width: fit.dp(14.0)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: fit.sp(11.0),
                  color: mutedTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : 'N/A',
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
    );
  }
}
