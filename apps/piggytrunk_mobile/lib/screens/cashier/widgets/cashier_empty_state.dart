import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';

class CashierEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const CashierEmptyState({
    super.key,
    this.message = 'Walang laman sa kasalukuyan',
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PiggyTrunkTheme.ptBorder, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF4F6F9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: PiggyTrunkTheme.ptMuted),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: PiggyTrunkTheme.ptMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
