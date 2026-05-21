import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DashboardStyles {
  // Top bar styling
  static Color get topBarBackground => PiggyTrunkTheme.ptSurfaceDark;
  static Color get topBarText => PiggyTrunkTheme.ptTextDark;
  static const double topBarHeight = 64;

  // Summary card styling
  static Color get summaryCardBackground => PiggyTrunkTheme.ptSurfaceSoftDark;
  static Color get summaryCardBorder => PiggyTrunkTheme.ptBorderDark;
  static Color get summaryCardLabel => PiggyTrunkTheme.ptMutedDark;
  static Color get summaryCardValue => PiggyTrunkTheme.ptTextDark;
  static const double summaryCardBorderRadius = 14;
  static const double summaryCardPadding = 20;

  // Allocation card styling
  static Color get allocationCardBackground => PiggyTrunkTheme.ptSurfaceSoftDark;
  static Color get allocationCardBorder => PiggyTrunkTheme.ptBorderDark;
  static Color get allocationLabel => PiggyTrunkTheme.ptMutedDark;
  static Color get allocationValue => PiggyTrunkTheme.ptTextDark;
  static const double allocationBorderRadius = 14;

  // Colors for allocation types
  static const Color fatteningColor = Color(0xFFFFA566);
  static const Color sowColor = Color(0xFFFF9D7D);

  // Text styles
  static TextStyle get dashboardTitleStyle => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: PiggyTrunkTheme.ptTextDark,
        letterSpacing: -0.04,
      );

  static TextStyle get sectionTitleStyle => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: summaryCardLabel,
        letterSpacing: 0.08,
      );

  static TextStyle get summaryValueStyle => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: summaryCardValue,
      );

  static TextStyle get allocationValueStyle => TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: summaryCardValue,
      );

  static TextStyle get allocationAmountStyle => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: summaryCardLabel,
      );

  // Table styling
  static Color get tableHeaderBackground => PiggyTrunkTheme.ptBgDark;
  static Color get tableHeaderText => PiggyTrunkTheme.ptMutedDark;
  static Color get tableRowHoverBackground => PiggyTrunkTheme.ptSurfaceSoftDark;
  static Color get tableRowBorder => PiggyTrunkTheme.ptBorderDark;
  static Color get tableText => PiggyTrunkTheme.ptTextDark;

  // Status colors
  static const Color statusActive = Color(0xFF43CB89);
  static const Color statusPending = Color(0xFFFFA566);
  static const Color statusInactive = Color(0xFF9CB0C9);
  static const Color statusWarning = Color(0xFFEF5B6C);

  // Box decorations
  static BoxDecoration summaryCardDecoration() {
    return BoxDecoration(
      color: summaryCardBackground,
      border: Border.all(color: summaryCardBorder, width: 1),
      borderRadius: BorderRadius.circular(summaryCardBorderRadius),
    );
  }

  static BoxDecoration allocationCardDecoration() {
    return BoxDecoration(
      color: allocationCardBackground,
      border: Border.all(color: allocationCardBorder, width: 1),
      borderRadius: BorderRadius.circular(allocationBorderRadius),
    );
  }

  static BoxDecoration tableDecoration() {
    return BoxDecoration(
      color: PiggyTrunkTheme.ptSurfaceDark,
      border: Border.all(color: tableRowBorder, width: 1),
      borderRadius: BorderRadius.circular(12),
    );
  }

  static BoxDecoration tableRowHoverDecoration() {
    return BoxDecoration(
      color: tableRowHoverBackground,
      borderRadius: BorderRadius.circular(8),
    );
  }

  // Section divider
  static const SizedBox sectionSpacing = SizedBox(height: 32);
  
  // Table text styles
  static TextStyle get tableHeaderStyle => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: tableHeaderText,
        letterSpacing: 0.08,
      );

  static TextStyle get tableDataStyle => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: tableText,
      );

  static const TextStyle tableActionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Color(0xFF7C3AED),
  );
}
