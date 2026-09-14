import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PiggyTrunkTheme {
  // Light Theme Colors
  static const Color ptBg = Color(0xfff4f7fb);
  static const Color ptSurface = Color(0xffffffff);
  static const Color ptSurfaceSoft = Color(0xfff8fafc);
  static const Color ptBorder = Color(0xffe6ebf2);
  static const Color ptText = Color(0xff18314f);
  static const Color ptMuted = Color(0xff6f8096);
  static const Color ptPrimary = Color(0xff243b53);
  static const Color ptAccent = Color(0xffef5b6c);
  static const Color ptSuccess = Color(0xff2fb36f);
  static const Color ptInProgress = Color(0xffffa566);
  static const Color ptPendingBorder = Color(0xffd4dce5);

  // Dark Theme Colors
  static const Color ptBgDark = Color(0xff0f1724);
  static const Color ptSurfaceDark = Color(0xff151f2e);
  static const Color ptSurfaceSoftDark = Color(0xff1b2638);
  static const Color ptBorderDark = Color(0xff28354a);
  static const Color ptTextDark = Color(0xffecf2ff);
  static const Color ptMutedDark = Color(0xff9cb0c9);
  static const Color ptPrimaryDark = Color(0xfff5f8ff);
  static const Color ptAccentDark = Color(0xffff758c);
  static const Color ptSuccessDark = Color(0xff43cb89);
  static const Color ptInProgressDark = Color(0xffff9d7d);

  // Light Theme Builder
  static ThemeData get lightTheme {
    return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: ptBg,
    primaryColor: ptPrimary,
    textTheme: TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.04,
        color: ptPrimary,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.04,
        color: ptPrimary,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.04,
        color: ptPrimary,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.04,
        color: ptPrimary,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: ptPrimary,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: ptText,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: ptText,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ptText,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: ptMuted,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.02,
        color: ptText,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.04,
        color: ptMuted,
      ),
    ),
    colorScheme: ColorScheme.light(
      primary: ptPrimary,
      secondary: ptAccent,
      surface: ptSurface,
      error: ptAccent,
      outline: ptBorder,
    ),
    cardTheme: CardThemeData(
      color: ptSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: const BorderSide(color: ptBorder, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ptSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ptBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ptBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ptPrimary, width: 2),
      ),
      hintStyle: GoogleFonts.plusJakartaSans(
        color: ptMuted,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ptPrimary,
        foregroundColor: ptSurface,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: const Color(0xFF18314F),
      selectionColor: const Color(0xFF18314F).withValues(alpha: 0.25),
      selectionHandleColor: const Color(0xFF18314F),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 2.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.04,
        color: ptPrimary,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: NoAnimationPageTransitionsBuilder(),
        TargetPlatform.iOS: NoAnimationPageTransitionsBuilder(),
        TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
        TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
        TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
        TargetPlatform.fuchsia: NoAnimationPageTransitionsBuilder(),
      },
    ),
  );
  }

  // Dark Theme Builder
  static ThemeData get darkTheme {
    return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: ptBgDark,
    primaryColor: ptPrimaryDark,
    textTheme: TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.04,
        color: ptPrimaryDark,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.04,
        color: ptPrimaryDark,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.04,
        color: ptPrimaryDark,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.04,
        color: ptPrimaryDark,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: ptPrimaryDark,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: ptTextDark,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: ptTextDark,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ptTextDark,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: ptMutedDark,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.02,
        color: ptTextDark,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.04,
        color: ptMutedDark,
      ),
    ),
    colorScheme: ColorScheme.dark(
      primary: ptPrimaryDark,
      secondary: ptAccentDark,
      surface: ptSurfaceDark,
      error: ptAccentDark,
      outline: ptBorderDark,
    ),
    cardTheme: CardThemeData(
      color: ptSurfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: ptBorderDark, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ptSurfaceSoftDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: ptBorderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: ptBorderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: ptPrimaryDark, width: 2),
      ),
      hintStyle: GoogleFonts.plusJakartaSans(
        color: ptMutedDark,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ptPrimaryDark,
        foregroundColor: ptSurfaceDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: const Color(0xFFECF2FF),
      selectionColor: const Color(0xFF38BDF8).withValues(alpha: 0.35),
      selectionHandleColor: const Color(0xFF38BDF8),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 2.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.04,
        color: ptPrimaryDark,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: NoAnimationPageTransitionsBuilder(),
        TargetPlatform.iOS: NoAnimationPageTransitionsBuilder(),
        TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
        TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
        TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
        TargetPlatform.fuchsia: NoAnimationPageTransitionsBuilder(),
      },
    ),
  );
  }

  // Shadow definitions
  static const BoxShadow ptShadow = BoxShadow(
    color: Color.fromRGBO(18, 40, 76, 0.08),
    blurRadius: 40,
    offset: Offset(0, 18),
  );

  static const BoxShadow ptShadowDark = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.28),
    blurRadius: 40,
    offset: Offset(0, 18),
  );
}

class NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

