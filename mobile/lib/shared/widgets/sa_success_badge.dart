import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_shapes.dart';

/// Icon-in-squircle badge with a pop-in/bounce entrance, used for
/// confirmation and resolved-status moments. Defaults to the living
/// gradient (reserved for these high-emotion moments only).
class SaSuccessBadge extends StatelessWidget {
  const SaSuccessBadge({
    super.key,
    this.icon = Icons.check_rounded,
    this.size = 72,
    this.gradient,
  });

  final IconData icon;
  final double size;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final effectiveGradient = gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.gradientGreen, p.gradientBlue],
        );

    return Container(
      width: size,
      height: size,
      decoration: AppShapes.card(
        gradient: effectiveGradient,
        radius: size * 0.32,
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    )
        .animate()
        .scale(
          begin: const Offset(0.4, 0.4),
          end: const Offset(1, 1),
          duration: 420.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 180.ms);
  }
}
