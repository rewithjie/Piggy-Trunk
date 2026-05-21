import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginStyles {
  // Colors
  static const Color brandText = Color(0xFF18314f);
  static const Color labelText = Color(0xFF495566);
  static const Color subtitleText = Color(0xFF5D6A7B);
  static const Color hintText = Color(0xFFB0BBCA);
  static const Color fieldBackground = Color(0xFFE8EDF3);
  static const Color fieldBorder = Color(0xFF9AAAC3);
  static const Color fieldIconColor = Color(0xFF5F6D81);
  static const Color fieldIconColorActive = Color(0xFF445571);
  static const Color successBorder = Color(0xFFB8E1C9);
  static const Color successBackground = Color(0xFFECF9F1);
  static const Color successText = Color(0xFF246B45);
  static const Color errorBorder = Color(0xFFEF5350);
  static const Color errorBackground = Color(0xFFFFEBEE);
  static const Color errorText = Color(0xFFD32F2F);
  static const Color dividerColor = Color(0xFFDFE3EB);
  static const Color linkColor = Color(0xFF2366CC);
  static const Color buttonText = Color(0xFFFFFFFF);
  static const Color checkboxColor = Color(0xFF939DAE);

  // Sizes
  static const double fieldBorderRadius = 12;
  static const double alertBorderRadius = 8;
  static const double fieldPaddingHorizontal = 16;
  static const double fieldPaddingVertical = 14;
  static const double fieldIconSize = 20;
  static const double visibilityIconSize = 22;

  // Typography
  static TextStyle titleStyle(BuildContext context) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 48,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.04,
      color: brandText,
    );
  }

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    color: subtitleText,
    height: 1.6,
  );

  static const TextStyle labelStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: labelText,
    letterSpacing: 0.08,
  );

  static const TextStyle alertTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  // Input Decorations
  static InputDecoration emailFieldDecoration({
    required String hintText,
    required Widget prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(
        color: const Color(0xFFAEB8C5),
        fontWeight: FontWeight.w400,
        fontSize: 15,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: prefixIcon,
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: fieldBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        borderSide: const BorderSide(
          color: fieldBorder,
          width: 1,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: fieldPaddingHorizontal,
        vertical: fieldPaddingVertical,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        borderSide: const BorderSide(
          color: errorText,
          width: 1,
        ),
      ),
    );
  }

  static InputDecoration passwordFieldDecoration({
    required String hintText,
    required Widget suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(
        color: const Color(0xFFAEB8C5),
        fontWeight: FontWeight.w400,
        fontSize: 15,
      ),
      filled: true,
      fillColor: fieldBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        borderSide: const BorderSide(
          color: fieldBorder,
          width: 1,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: fieldPaddingHorizontal,
        vertical: fieldPaddingVertical,
      ),
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: suffixIcon,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        borderSide: const BorderSide(
          color: errorText,
          width: 1,
        ),
      ),
    );
  }

  // Alert Decorations
  static BoxDecoration successAlertDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(alertBorderRadius),
      border: Border.all(color: successBorder),
      color: successBackground,
    );
  }

  static BoxDecoration errorAlertDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(alertBorderRadius),
      border: Border.all(color: errorBorder),
      color: errorBackground,
    );
  }

  // Shadow
  static final BoxShadow checkboxShadow = BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );
}
