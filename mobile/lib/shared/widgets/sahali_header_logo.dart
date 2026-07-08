import 'package:flutter/material.dart';

/// The Sahali wordmark + Tunisia flag badge lockup (brand asset, distinct
/// from the app icon) — used on the home header, the auth screens, the
/// splash screen, and the profile screen footer.
///
/// Rendered from PNG exports (not the SVG source) because `flutter_svg`
/// doesn't render the flag badge's pattern-fill (an embedded raster image),
/// which made the flag disappear. The dark variant is a recolored copy of
/// the light PNG (wordmark ink lightened; the flag's own colors untouched)
/// generated from the original light-mode export.
class SahaliHeaderLogo extends StatelessWidget {
  const SahaliHeaderLogo({super.key, this.height = 28});
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      isDark
          ? 'assets/images/sahali_header_logo_dark.png'
          : 'assets/images/sahali_header_logo_light.png',
      height: height,
    );
  }
}
