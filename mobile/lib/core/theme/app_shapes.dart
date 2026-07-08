import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

/// Continuous-corner ("squircle") shape helpers — the app's core visual
/// identity is fully rounded, curved shapes everywhere, never a hard 90°
/// corner. Use these instead of [BorderRadius.circular]/[BoxDecoration]
/// wherever a card, button, badge, avatar, sheet, or nav bar is drawn.
class AppShapes {
  AppShapes._();

  static const double smoothing = 0.6;
  static const double radiusSm = 14;
  static const double radiusMd = 20;
  static const double radiusLg = 28;
  static const double radiusXl = 36;
  static const double radiusPill = 999;

  static SmoothBorderRadius radius(double r, {double smooth = smoothing}) =>
      SmoothBorderRadius(cornerRadius: r, cornerSmoothing: smooth);

  static SmoothRectangleBorder border({
    double radius = radiusMd,
    double smooth = smoothing,
    Color? borderColor,
    double borderWidth = 1,
  }) =>
      SmoothRectangleBorder(
        borderRadius: SmoothBorderRadius(cornerRadius: radius, cornerSmoothing: smooth),
        side: borderColor != null ? BorderSide(color: borderColor, width: borderWidth) : BorderSide.none,
      );

  static SmoothRectangleBorder pill({Color? borderColor, double borderWidth = 1}) =>
      border(radius: radiusPill, borderColor: borderColor, borderWidth: borderWidth);

  /// Drop-in replacement for `BoxDecoration(color:, borderRadius:, border:)`
  /// that actually paints a continuous-corner outline (BoxDecoration only
  /// supports circular-corner RRects, even when given a [SmoothBorderRadius]).
  static ShapeDecoration card({
    Color? color,
    Gradient? gradient,
    double radius = radiusLg,
    double smooth = smoothing,
    Color? borderColor,
    double borderWidth = 1,
    List<BoxShadow>? shadows,
  }) =>
      ShapeDecoration(
        color: color,
        gradient: gradient,
        shadows: shadows,
        shape: border(radius: radius, smooth: smooth, borderColor: borderColor, borderWidth: borderWidth),
      );
}
