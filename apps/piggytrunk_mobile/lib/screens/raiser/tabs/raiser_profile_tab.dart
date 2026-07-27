import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    final name = raiserData['name'] ?? 'Hog Raiser';
    final email = raiserData['email'] ?? 'N/A';
    final phone = raiserData['phone'] ?? 'N/A';
    final address = raiserData['address'] ?? 'N/A';
    final type = raiserData['pig_type'] ?? 'Fattening';
    final stage = raiserData['lifecycle_stage'] ?? 'Grower';
    final avatarUrl = raiserData['avatar_url'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar & Name Header Card
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
                          border: Border.all(color: _brandColor, width: 2),
                          color: const Color(0xfff7f8fb),
                        ),
                        child: ClipOval(
                          child: avatarUrl != null && avatarUrl.isNotEmpty
                              ? Image.network(
                                  avatarUrl,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Image.asset(
                                    'assets/piggytrunk_logo.png',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, err, st) => Container(
                                      color: _brandColor,
                                      child: const Icon(Icons.person, size: 50, color: Colors.white),
                                    ),
                                  ),
                                )
                              : Image.asset(
                                  'assets/piggytrunk_logo.png',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, err, st) => Container(
                                    color: _brandColor,
                                    child: const Icon(Icons.person, size: 50, color: Colors.white),
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
                    color: _brandColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hog Raiser',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: PiggyTrunkTheme.ptMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detalye ng Account',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _brandColor,
                ),
              ),
              Row(
                children: [
                  if (avatarUrl != null && avatarUrl.isNotEmpty) ...[
                    GestureDetector(
                      onTap: onRestoreDefaultAvatar,
                      child: Row(
                        children: [
                          const Icon(Icons.refresh, size: 16, color: _brandColor),
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
                  ],
                  GestureDetector(
                    onTap: onShowEditProfileDialog,
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 16, color: _brandColor),
                        const SizedBox(width: 4),
                        Text(
                          'I-edit',
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
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PiggyTrunkTheme.ptBorder),
            ),
            child: Column(
              children: [
                _buildProfileRow(Icons.email_outlined, 'Email Address', email),
                const Divider(height: 24, color: PiggyTrunkTheme.ptBorder),
                _buildProfileRow(Icons.phone_iphone, 'Phone Number', phone),
                const Divider(height: 24, color: PiggyTrunkTheme.ptBorder),
                _buildProfileRow(Icons.location_on_outlined, 'Address', address),
                const Divider(height: 24, color: PiggyTrunkTheme.ptBorder),
                _buildProfileRow(Icons.style_outlined, 'Pig Type Assignment', type),
                const Divider(height: 24, color: PiggyTrunkTheme.ptBorder),
                _buildProfileRow(Icons.hourglass_empty_outlined, 'Current Stage', stage),
              ],
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: onHandleSignOut,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _brandColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Mag-Sign Out',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: _brandColor,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SvgPicture.asset(
                    'assets/icons/sidebar/logout.svg',
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(_brandColor, BlendMode.srcIn),
                  ),
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
