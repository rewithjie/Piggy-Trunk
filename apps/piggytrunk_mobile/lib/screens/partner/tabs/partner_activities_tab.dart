import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../../../utils/screen_fit_util.dart';

class PartnerActivitiesTab extends StatelessWidget {
  final List<Map<String, dynamic>> activitiesList;
  final Future<void> Function() onRefresh;

  static const Color _brandColor = Color(0xFF18314F);

  const PartnerActivitiesTab({
    super.key,
    required this.activitiesList,
    required this.onRefresh,
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
    final iconBgColor = isDark ? const Color(0xff1b2638) : const Color(0xfff0f4f8);
    final iconColor = isDark ? const Color(0xff9cb0c9) : const Color(0xff486581);

    final displayActivities = activitiesList;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: _brandColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hog Raiser Activities',
              style: GoogleFonts.plusJakartaSans(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w800,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Real-time activity logs from your assigned hog raisers.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: fit.sp(14.0),
                color: isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted,
              ),
            ),
            SizedBox(height: fit.dp(20.0)),

            if (displayActivities.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: fit.dp(20), vertical: fit.dp(28)),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(fit.dp(22)),
                  border: Border.all(color: cardBorderColor, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: fit.dp(38),
                      color: isDark ? const Color(0xff9cb0c9) : _brandColor,
                    ),
                    SizedBox(height: fit.dp(10)),
                    Text(
                      'No Recent Activities',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: fit.sp(15.0),
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: fit.dp(4)),
                    Text(
                      'Activities and updates from your hog raisers will appear here.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: fit.sp(12.0),
                        fontWeight: FontWeight.w500,
                        color: isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...displayActivities.map((act) {
                final String title = act['title'] ?? 'Activity Update';
                final String description = act['description'] ?? act['message'] ?? '';
                final String date = act['date'] ?? act['created_at'] ?? '';
                final IconData icon = (act['icon'] is IconData)
                    ? act['icon'] as IconData
                    : Icons.assignment_outlined;

                return Container(
                  margin: EdgeInsets.only(bottom: fit.dp(12)),
                  padding: EdgeInsets.all(fit.dp(16.0)),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(fit.dp(20)),
                    border: Border.all(color: cardBorderColor, width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: fit.dp(48.0),
                        height: fit.dp(48.0),
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: fit.dp(24.0),
                        ),
                      ),
                      SizedBox(width: fit.dp(16.0)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: fit.sp(15.0),
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor,
                              ),
                            ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                description,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: fit.sp(13.0),
                                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                                ),
                              ),
                            ],
                            const SizedBox(height: 5),
                            Text(
                              date,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: fit.sp(12.0),
                                fontWeight: FontWeight.w500,
                                color: isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
