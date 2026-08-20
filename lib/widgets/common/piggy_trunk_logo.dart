import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Reusable PiggyTrunk Logo Widget
class PiggyTrunkLogo extends StatelessWidget {
  final double size;
  final bool withBorder;
  final double? borderRadius;
  final Alignment imageAlignment;

  const PiggyTrunkLogo({
    super.key,
    this.size = 120,
    this.withBorder = false,
    this.borderRadius,
    this.imageAlignment = const Alignment(-0.06, 0.0),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? PiggyTrunkTheme.ptSurfaceDark
        : PiggyTrunkTheme.ptSurface;
    final primaryColor = isDark
        ? PiggyTrunkTheme.ptPrimaryDark
        : PiggyTrunkTheme.ptPrimary;
    final accentColor = isDark
        ? PiggyTrunkTheme.ptAccentDark
        : PiggyTrunkTheme.ptAccent;

    final logo = _buildLogo(context, isDark, accentColor, surfaceColor);

    if (!withBorder) {
      return logo;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? size / 4),
        color: surfaceColor.withValues(alpha: 0.86),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Center(child: logo),
    );
  }

  Widget _buildLogo(
    BuildContext context,
    bool isDark,
    Color accentColor,
    Color surfaceColor,
  ) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Image.asset(
          'assets/piggytrunk_logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          alignment: imageAlignment,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackLogo(accentColor, surfaceColor);
          },
        ),
      ),
    );
  }

  Widget _buildFallbackLogo(Color accentColor, Color surfaceColor) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentColor.withValues(alpha: 0.8), accentColor.withValues(alpha: 0.9)],
        ),
      ),
      child: Center(
        child: Icon(Icons.pets_rounded, size: size * 0.6, color: surfaceColor),
      ),
    );
  }
}

class LogoSize {
  static const double small = 32.0;
  static const double medium = 56.0;
  static const double large = 80.0;
  static const double xlarge = 120.0;
  static const double extraLarge = 120.0;
  static const double display = 180.0;
  static const double hero = 200.0;
}
