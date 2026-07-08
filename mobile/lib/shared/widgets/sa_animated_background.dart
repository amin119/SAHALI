import 'package:flutter/material.dart';
import 'package:flutter_moving_background/flutter_moving_background.dart';
import '../../core/theme/app_palette.dart';

/// The onboarding/splash "living" background — slow-drifting, softly
/// blurred glows in the app's own palette. Uses `flutter_moving_background`'s
/// circle technique (the same one behind its "cyberpunk" preset) but with
/// Sahali's warm pastel colors instead of neon magenta/cyan, so it still
/// reads as calm rather than electric. Mounted locally by [SplashScreen] and
/// [OnboardingScreen] only — the rest of the app uses a plain background.
class SaAnimatedBackground extends StatelessWidget {
  const SaAnimatedBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return MovingBackground(
      backgroundColor: p.background,
      animationType: AnimationType.moveAndFade,
      duration: const Duration(seconds: 16),
      circles: [
        MovingCircle(color: p.gradientOrange.withValues(alpha: 0.6), radius: 320, blurSigma: 80),
        MovingCircle(color: p.gradientYellow.withValues(alpha: 0.55), radius: 280, blurSigma: 75),
        MovingCircle(color: p.gradientGreen.withValues(alpha: 0.55), radius: 300, blurSigma: 80),
        MovingCircle(color: p.gradientBlue.withValues(alpha: 0.55), radius: 280, blurSigma: 75),
      ],
      child: child,
    );
  }
}
