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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xffecf2ff) : _brandColor;
    final cardBgColor = isDark ? const Color(0xff151f2e) : Colors.white;
    final cardBorderColor = isDark ? const Color(0xff28354a) : PiggyTrunkTheme.ptBorder;
    final mutedTextColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;

    final name = (partnerName.trim().isNotEmpty && partnerName.trim().toLowerCase() != 'partner investor')
        ? partnerName.trim()
        : 'Partner Investor';
    final email = partnerEmail.trim().isNotEmpty ? partnerEmail.trim() : 'N/A';
    final phone = (partnerPhone.trim().isNotEmpty && partnerPhone != 'N/A') ? partnerPhone.trim() : 'Not set';
    final address = (partnerAddress.trim().isNotEmpty && partnerAddress != 'N/A') ? partnerAddress.trim() : 'Not set';

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
                    'Partner Investor',
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
                'Account Details',
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
                          color: isDark ? const Color(0xFF93C5FD) : _brandColor,
                        ),
                        SizedBox(width: fit.dp(4)),
                        Text(
                          'Reset',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: fit.sp(14.0),
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF93C5FD) : _brandColor,
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
                          color: isDark ? const Color(0xFF93C5FD) : _brandColor,
                        ),
                        SizedBox(width: fit.dp(4)),
                        Text(
                          'Edit',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: fit.sp(14.0),
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF93C5FD) : _brandColor,
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
                _buildProfileRow(fit, isDark, Icons.email_outlined, 'Email Address', email, primaryTextColor, mutedTextColor),
                Divider(height: fit.dp(24.0), color: cardBorderColor),
                _buildProfileRow(fit, isDark, Icons.phone_iphone_rounded, 'Phone Number', phone, primaryTextColor, mutedTextColor),
                Divider(height: fit.dp(24.0), color: cardBorderColor),
                _buildProfileRow(fit, isDark, Icons.location_on_outlined, 'Address', address, primaryTextColor, mutedTextColor),
                Divider(height: fit.dp(24.0), color: cardBorderColor),
                _buildProfileRow(fit, isDark, Icons.security_rounded, 'System Access', 'Partner Investor', primaryTextColor, mutedTextColor),
                Divider(height: fit.dp(24.0), color: cardBorderColor),
                _buildProfileRow(fit, isDark, Icons.verified_user_outlined, 'Account Status', 'Active', primaryTextColor, mutedTextColor),
              ],
            ),
          ),
          SizedBox(height: fit.dp(32.0)),

          // ==================== 4. SIGN OUT BUTTON ====================
          SizedBox(
            width: double.infinity,
            height: fit.dp(54.0),
            child: OutlinedButton(
              onPressed: onLogout,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDark ? const Color(0xff93c5fd) : _brandColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(fit.dp(14)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign Out',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xff93c5fd) : _brandColor,
                      fontSize: fit.sp(15.0),
                    ),
                  ),
                  SizedBox(width: fit.dp(8)),
                  Icon(Icons.logout_rounded, color: isDark ? const Color(0xff93c5fd) : _brandColor, size: fit.dp(20)),
                ],
              ),
            ),
          ),
        ],
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
