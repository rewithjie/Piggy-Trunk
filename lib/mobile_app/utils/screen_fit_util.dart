import 'package:flutter/material.dart';

/// Universal Screen Fit & Auto-Scaling Utility for PiggyTrunk Mobile
/// Automatically scales fonts, paddings, and dimensions relative to the device screen
class ScreenFit {
  final BuildContext context;
  late final double screenWidth;
  late final double screenHeight;
  late final double scaleFactor;

  ScreenFit(this.context) {
    final media = MediaQuery.of(context);
    screenWidth = media.size.width;
    screenHeight = media.size.height;

    // Calculate scale factor relative to standard 390px mobile reference width
    // Clamped between 0.88x (small budget phones) and 1.30x (large phones / tablets)
    scaleFactor = (screenWidth / 390.0).clamp(0.88, 1.30);
  }

  /// Automatically scale font size based on device screen size
  double sp(double size) {
    return (size * scaleFactor).roundToDouble();
  }

  /// Automatically scale dimension (padding, margin, height, width, radius)
  double dp(double size) {
    return (size * scaleFactor).roundToDouble();
  }
}
