import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  const AppTextStyles._();

  static TextStyle jakarta({
    required double size,
    required FontWeight weight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle poppins({
    required double size,
    required FontWeight weight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle pageTitle(Color color) => jakarta(
        size: 30,
        weight: FontWeight.w800,
        color: color,
        letterSpacing: -0.04,
      );

  static TextStyle sectionTitle(Color color) => jakarta(
        size: 30,
        weight: FontWeight.w800,
        color: color,
        letterSpacing: -0.04,
      );

  static TextStyle cardTitle(Color color) => jakarta(
        size: 15,
        weight: FontWeight.w700,
        color: color,
      );

  static TextStyle button(Color color) => jakarta(
        size: 16,
        weight: FontWeight.w700,
        color: color,
      );

  static TextStyle body(Color color) => jakarta(
        size: 14,
        weight: FontWeight.w500,
        color: color,
      );

  static TextStyle bodyStrong(Color color) => jakarta(
        size: 14,
        weight: FontWeight.w700,
        color: color,
      );

  static TextStyle caption(Color color) => jakarta(
        size: 12,
        weight: FontWeight.w500,
        color: color,
      );

  static TextStyle tableHeader(Color color) => jakarta(
        size: 12,
        weight: FontWeight.w700,
        color: color,
        letterSpacing: 0.3,
      );

  static TextStyle sidebarBrand(Color color) => poppins(
        size: 20,
        weight: FontWeight.w700,
        color: color,
        letterSpacing: -0.2,
        height: 1.0,
      );

  static TextStyle sidebarLabel(Color color) => poppins(
        size: 13,
        weight: FontWeight.w500,
        color: color,
        letterSpacing: 0.2,
      );
}
