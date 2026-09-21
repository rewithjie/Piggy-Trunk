import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';

class RoleSelectionModal extends StatefulWidget {
  final String userName;
  final Function(String selectedRole) onRoleSelected;

  const RoleSelectionModal({
    super.key,
    required this.userName,
    required this.onRoleSelected,
  });

  static Future<String?> show(BuildContext context, {required String userName}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RoleSelectionModal(
        userName: userName,
        onRoleSelected: (role) => Navigator.pop(ctx, role),
      ),
    );
  }

  @override
  State<RoleSelectionModal> createState() => _RoleSelectionModalState();
}

class _RoleSelectionModalState extends State<RoleSelectionModal> {
  String _selectedRole = 'hog_raiser'; // 'hog_raiser', 'partner', or 'cashier'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF18314F);
    final subtitleColor = isDark ? PiggyTrunkTheme.ptMutedDark : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2D42) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.how_to_reg_rounded,
                  color: isDark ? Colors.white : const Color(0xFF18314F),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Piggy Trunk!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose how you would like to use your account:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Card 1: Hog Raiser
          _buildRoleCard(
            roleKey: 'hog_raiser',
            title: 'Hog Raiser',
            description: 'Raise pigs, request feeds and supplies, and monitor daily health logs.',
            icon: Icons.pets_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          // Card 2: Partner Investor
          _buildRoleCard(
            roleKey: 'partner',
            title: 'Partner Investor',
            description: 'Invest in hog production batches and track your harvest profit returns.',
            icon: Icons.trending_up_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          // Card 3: Cashier
          _buildRoleCard(
            roleKey: 'cashier',
            title: 'Cashier & POS',
            description: 'Manage store inventory, dispense supplies, and process point-of-sale transactions.',
            icon: Icons.point_of_sale_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 22),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onRoleSelected(_selectedRole);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : const Color(0xFF18314F),
                foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _selectedRole == 'hog_raiser'
                        ? 'Continue as Hog Raiser'
                        : _selectedRole == 'partner'
                            ? 'Continue as Partner Investor'
                            : 'Continue as Cashier',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String roleKey,
    required String title,
    required String description,
    required IconData icon,
    required bool isDark,
  }) {
    final bool isSelected = _selectedRole == roleKey;

    final cardBg = isSelected
        ? (isDark ? const Color(0xFF1E2D42) : const Color(0xFFF8FAFC))
        : (isDark ? const Color(0xFF131E2D) : Colors.white);

    final borderColor = isSelected
        ? (isDark ? Colors.white : const Color(0xFF18314F))
        : (isDark ? const Color(0xFF283A57) : const Color(0xFFE2E8F0));

    final titleColor = isDark ? Colors.white : const Color(0xFF18314F);
    final descColor = isDark ? PiggyTrunkTheme.ptMutedDark : const Color(0xFF64748B);

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = roleKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Badge (Monochromatic)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? const Color(0xFF283A57) : const Color(0xFFE2E8F0))
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF18314F))
                    : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: descColor,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Selection Indicator
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF18314F))
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF18314F))
                      : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
