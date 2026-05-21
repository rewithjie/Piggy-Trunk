import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable PiggyTrunk Logo Widget
class PiggyTrunkLogo extends StatelessWidget {
  final double size;
  final bool withBorder;
  final double? borderRadius;
  final Alignment imageAlignment;

  const PiggyTrunkLogo({
    Key? key,
    this.size = 120,
    this.withBorder = false,
    this.borderRadius,
    this.imageAlignment = const Alignment(-0.06, 0.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? PiggyTrunkTheme.ptSurfaceDark : PiggyTrunkTheme.ptSurface;
    final primaryColor = isDark ? PiggyTrunkTheme.ptPrimaryDark : PiggyTrunkTheme.ptPrimary;
    final accentColor = isDark ? PiggyTrunkTheme.ptAccentDark : PiggyTrunkTheme.ptAccent;
    
    final logo = _buildLogo(context, isDark, accentColor, surfaceColor);

    if (!withBorder) {
      return logo;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? size / 4),
        color: surfaceColor.withOpacity(0.86),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Center(child: logo),
    );
  }

  Widget _buildLogo(BuildContext context, bool isDark, Color accentColor, Color surfaceColor) {
    // Try to load image, fallback to icon if not found
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Image.asset(
          'assets/piggytrunkremovebg.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          alignment: imageAlignment,
          errorBuilder: (context, error, stackTrace) {
            // Fallback: Show custom piggy icon
            return _buildFallbackLogo(accentColor, surfaceColor);
          },
        ),
      ),
    );
  }

  Widget _buildFallbackLogo(Color accentColor, Color surfaceColor) {
    // Custom PiggyTrunk logo fallback - Pink circular pig character
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withOpacity(0.8),
            accentColor.withOpacity(0.9),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.pets_rounded,
          size: size * 0.6,
          color: surfaceColor,
        ),
      ),
    );
  }
}

/// Logo Sizes Presets
class LogoSize {
  static const double extraSmall = 24;
  static const double small = 48;
  static const double medium = 68;
  static const double large = 120;
  static const double extraLarge = 164;
}
