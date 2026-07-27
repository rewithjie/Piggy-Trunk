import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';

class CashierProfileTab extends StatelessWidget {
  final String cashierName;
  final String cashierEmail;
  final String cashierPhone;
  final String cashierAddress;
  final String? cashierAvatarUrl;
  final VoidCallback onPickAndUploadAvatar;
  final VoidCallback onRestoreDefaultAvatar;
  final VoidCallback onShowEditProfileDialog;
  final VoidCallback onHandleLogout;

  static const Color _brandColor = Color(0xFF18314F);

  const CashierProfileTab({
    super.key,
    required this.cashierName,
    required this.cashierEmail,
    required this.cashierPhone,
    required this.cashierAddress,
    required this.cashierAvatarUrl,
    required this.onPickAndUploadAvatar,
    required this.onRestoreDefaultAvatar,
    required this.onShowEditProfileDialog,
    required this.onHandleLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar & Name Card Header
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
                          color: const Color(0xFFF7F8FB),
                        ),
                        child: ClipOval(
                          child: cashierAvatarUrl != null && cashierAvatarUrl!.isNotEmpty
                              ? Image.network(
                                  cashierAvatarUrl!,
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
                  cashierName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _brandColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cashier Terminal Staff',
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

          // Account Details Section Header
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
                  if (cashierAvatarUrl != null && cashierAvatarUrl!.isNotEmpty) ...[
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

          // Details List Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PiggyTrunkTheme.ptBorder),
            ),
            child: Column(
              children: [
                _buildProfileRow(Icons.email_outlined, 'Email Address', cashierEmail),
                const Divider(height: 24, color: PiggyTrunkTheme.ptBorder),
                _buildProfileRow(Icons.phone_iphone, 'Phone Number', cashierPhone),
                const Divider(height: 24, color: PiggyTrunkTheme.ptBorder),
                _buildProfileRow(Icons.location_on_outlined, 'Address / Branch', cashierAddress),
                const Divider(height: 24, color: PiggyTrunkTheme.ptBorder),
                _buildProfileRow(Icons.security, 'System Access', 'Cashier Terminal'),
                const Divider(height: 24, color: PiggyTrunkTheme.ptBorder),
                _buildProfileRow(Icons.verified_user_outlined, 'Account Status', 'Active'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: onHandleLogout,
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
                  const Icon(Icons.logout, color: _brandColor, size: 20),
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
