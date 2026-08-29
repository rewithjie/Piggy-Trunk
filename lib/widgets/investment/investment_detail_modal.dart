import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/investment_model.dart';
import '../../theme/app_theme.dart';

class InvestmentDetailModal {
  static void show({
    required BuildContext context,
    required Investment investment,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 720;
    if (isMobile) {
      _showBottomSheet(context, investment);
    } else {
      _showSideDrawer(context, investment);
    }
  }

  static String _formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(0);
    final formatted = parts.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '₱$formatted';
  }

  static String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthName = months[date.month - 1];
    return '$monthName ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  static void _showBottomSheet(BuildContext context, Investment inv) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF132238) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
    final titleColor = isDark ? Colors.white : const Color(0xFF18314F);
    final hintText = isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);

    final batchName = (inv.batchName != null && inv.batchName!.isNotEmpty) ? inv.batchName! : 'Unassigned';
    final stage = inv.stage.toUpperCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: cardBorder, width: 1.2)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: hintText.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Investment Details',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: Icon(Icons.close_rounded, color: hintText, size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Divider(color: cardBorder.withValues(alpha: 0.5), height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1B2E48) : const Color(0xFFF6F9FD),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: cardBorder.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          children: [
                            _detailRow('Hog Raiser', inv.raiserName, hintText, titleColor),
                            Divider(color: cardBorder.withValues(alpha: 0.35), height: 1),
                            _detailRow('Batch Assigned', batchName, hintText, isDark ? Colors.white : PiggyTrunkTheme.ptPrimary),
                            Divider(color: cardBorder.withValues(alpha: 0.35), height: 1),
                            _detailRow('Capital Amount', _formatCurrency(inv.initialCapital), hintText, const Color(0xFF43CB89)),
                            Divider(color: cardBorder.withValues(alpha: 0.35), height: 1),
                            _detailRow('Hog Type', inv.hogType, hintText, titleColor),
                            Divider(color: cardBorder.withValues(alpha: 0.35), height: 1),
                            _detailRow('Total Hogs', '${inv.totalHog} heads', hintText, titleColor),
                            Divider(color: cardBorder.withValues(alpha: 0.35), height: 1),
                            _detailRow('Investment Date', _formatDate(inv.investmentDate), hintText, titleColor),
                            Divider(color: cardBorder.withValues(alpha: 0.35), height: 1),
                            _detailRow('Status / Stage', stage, hintText, titleColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(color: cardBorder.withValues(alpha: 0.5), height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                      foregroundColor: isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showSideDrawer(BuildContext context, Investment inv) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF132238) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
    final titleColor = isDark ? Colors.white : const Color(0xFF18314F);
    final hintText = isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);

    final batchName = (inv.batchName != null && inv.batchName!.isNotEmpty) ? inv.batchName! : 'Unassigned';
    final stage = inv.stage.toUpperCase();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Investment Details',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (dialogContext, anim, secondaryAnim, child) {
        final curvedAnimation = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 440,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border(left: BorderSide(color: cardBorder, width: 1.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(-4, 0),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : PiggyTrunkTheme.ptPrimary).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (isDark ? Colors.white : PiggyTrunkTheme.ptPrimary).withValues(alpha: 0.22),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.monetization_on_outlined,
                                size: 18,
                                color: isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Investment Details',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: titleColor,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: Icon(Icons.close_rounded, color: hintText, size: 22),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Close panel',
                            ),
                          ],
                        ),
                      ),
                      Divider(color: cardBorder.withValues(alpha: 0.5), height: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1B2E48) : const Color(0xFFF6F9FD),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: cardBorder.withValues(alpha: 0.5)),
                                ),
                                child: Column(
                                  children: [
                                    _detailRow('Hog Raiser', inv.raiserName, hintText, titleColor),
                                    Divider(color: cardBorder.withValues(alpha: 0.35), height: 1),
                                    _detailRow('Batch Assigned', batchName, hintText, isDark ? Colors.white : PiggyTrunkTheme.ptPrimary),
                                    Divider(color: cardBorder.withValues(alpha: 0.35), height: 1),
                                    _detailRow('Capital Amount', _formatCurrency(inv.initialCapital), hintText, const Color(0xFF43CB89)),
                                    Divider(color: cardBorder.withValues(alpha: 0.35), height: 1),
                                    _detailRow('Hog Type', inv.hogType, hintText, titleColor),
                                    Divider(color: cardBorder.withValues(alpha: 0.35), height: 1),
                                    _detailRow('Total Hogs', '${inv.totalHog} heads', hintText, titleColor),
                                    Divider(color: cardBorder.withValues(alpha: 0.35), height: 1),
                                    _detailRow('Investment Date', _formatDate(inv.investmentDate), hintText, titleColor),
                                    Divider(color: cardBorder.withValues(alpha: 0.35), height: 1),
                                    _detailRow('Status / Stage', stage, hintText, titleColor),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(color: cardBorder.withValues(alpha: 0.5), height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                              foregroundColor: isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: Text(
                              'Close',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _detailRow(String label, String value, Color labelColor, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
