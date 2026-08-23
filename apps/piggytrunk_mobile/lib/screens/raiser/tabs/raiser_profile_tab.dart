import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';

class RaiserProfileTab extends StatelessWidget {
  final Map<String, dynamic> raiserData;
  final VoidCallback onPickAndUploadAvatar;
  final VoidCallback onRestoreDefaultAvatar;
  final VoidCallback onShowEditProfileDialog;
  final VoidCallback onHandleSignOut;

  static const Color _brandColor = Color(0xFF18314F);

  const RaiserProfileTab({
    super.key,
    required this.raiserData,
    required this.onPickAndUploadAvatar,
    required this.onRestoreDefaultAvatar,
    required this.onShowEditProfileDialog,
    required this.onHandleSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : _brandColor;

    final name = (raiserData['name'] ?? '').toString().trim().isNotEmpty
        ? (raiserData['name'] as String)
        : 'Hog Raiser';
    final email = (raiserData['email'] ?? '').toString().trim().isNotEmpty
        ? (raiserData['email'] as String)
        : 'N/A';
    final phone = (raiserData['phone'] != null && raiserData['phone'] != 'N/A' && raiserData['phone'].toString().trim().isNotEmpty)
        ? raiserData['phone'].toString()
        : 'Not set';
    final address = (raiserData['address'] != null && raiserData['address'] != 'N/A' && raiserData['address'].toString().trim().isNotEmpty)
        ? raiserData['address'].toString()
        : 'Not set';
    final type = (raiserData['pig_type'] != null && raiserData['pig_type'] != 'N/A' && raiserData['pig_type'] != 'None')
        ? raiserData['pig_type'].toString()
        : 'Unassigned';
    final stage = (raiserData['lifecycle_stage'] != null && raiserData['lifecycle_stage'] != 'N/A' && raiserData['lifecycle_stage'] != 'None')
        ? raiserData['lifecycle_stage'].toString()
        : 'Not set';
    final avatarUrl = raiserData['avatar_url'] as String?;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== AVATAR & NAME HEADER CARD ====================
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: onPickAndUploadAvatar,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _brandColor, width: 2.5),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: _brandColor.withValues(alpha: 0.12),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? Image.network(
                                  avatarUrl,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Image.asset(
                                      'assets/piggytrunk_logo.png',
                                      width: 76,
                                      height: 76,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, err, st) => Container(
                                        color: Colors.white,
                                        child: const Icon(Icons.person, size: 50, color: _brandColor),
                                      ),
                                    ),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Image.asset(
                                    'assets/piggytrunk_logo.png',
                                    width: 76,
                                    height: 76,
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
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: _brandColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Hog Raiser',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ==================== ACCOUNT DETAILS SECTION HEADER ====================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Account Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: onRestoreDefaultAvatar,
                    child: Row(
                      children: [
                        const Icon(Icons.refresh_rounded, size: 16, color: _brandColor),
                        const SizedBox(width: 4),
                        Text(
                          'I-reset',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _brandColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: onShowEditProfileDialog,
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 16, color: _brandColor),
                        const SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _brandColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ==================== DETAILS LIST CARD ====================
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PiggyTrunkTheme.ptBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildProfileRow(Icons.email_outlined, 'Email Address', email),
                const Divider(height: 24, color: PiggyTrunkTheme.ptBorder),
                _buildProfileRow(Icons.phone_iphone_rounded, 'Phone Number', phone),
                const Divider(height: 24, color: PiggyTrunkTheme.ptBorder),
                _buildProfileRow(Icons.location_on_outlined, 'Farm Address', address),
                const Divider(height: 24, color: PiggyTrunkTheme.ptBorder),
                _buildProfileRow(Icons.pets_outlined, 'Pig Type Assignment', type),
                const Divider(height: 24, color: PiggyTrunkTheme.ptBorder),
                _buildProfileRow(Icons.restaurant_rounded, 'Current Feeds Stage', stage),
                const Divider(height: 24, color: PiggyTrunkTheme.ptBorder),
                _buildProfileRow(Icons.security_rounded, 'System Access', 'Hog Raiser'),
                const Divider(height: 24, color: PiggyTrunkTheme.ptBorder),
                _buildProfileRow(Icons.verified_user_outlined, 'Account Status', 'Active'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ==================== LOGOUT BUTTON ====================
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: onHandleSignOut,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _brandColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign Out',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: _brandColor,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.logout_rounded, color: _brandColor, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: PiggyTrunkTheme.ptMuted, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: PiggyTrunkTheme.ptMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: _brandColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
