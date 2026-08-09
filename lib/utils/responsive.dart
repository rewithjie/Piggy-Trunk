import 'package:flutter/material.dart';

/// Responsive helper class for breakpoint detection and conditional rendering.
class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  /// Mobile breakpoint: screen width < 600px
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  /// Tablet breakpoint: 600px <= screen width < 1024px
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;

  /// Desktop breakpoint: screen width >= 1024px
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  /// Small screen helper: screen width < 1024px (Mobile or Tablet)
  static bool isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 1024;

  /// Screen width helper
  static double widthOf(BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// Responsive value selector
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return desktop;
    if (width >= 600 && tablet != null) return tablet;
    return mobile;
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    if (width >= 1024) {
      return desktop;
    } else if (width >= 600 && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}
