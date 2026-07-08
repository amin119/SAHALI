import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';

/// The app's living background — a slow, breathing pastel gradient behind
/// every screen. Mounted once at the [MaterialApp] root (see app.dart) so
/// the animation keeps flowing continuously across navigation instead of
/// restarting per screen. Individual screens just need a transparent
/// [Scaffold] background for it to show through.
class SaAnimatedBackground extends StatefulWidget {
  const SaAnimatedBackground({super.key, required this.child});
  final Widget child;

  @override
  State<SaAnimatedBackground> createState() => _SaAnimatedBackgroundState();
}

class _SaAnimatedBackgroundState extends State<SaAnimatedBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Alignment> _begin;
  late final Animation<Alignment> _end;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 22))..repeat(reverse: true);
    final curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine);
    _begin = AlignmentTween(begin: Alignment.topLeft, end: Alignment.bottomLeft).animate(curve);
    _end = AlignmentTween(begin: Alignment.bottomRight, end: Alignment.topRight).animate(curve);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context).livingGradientColors;
    return AnimatedBuilder(
      animation: _ctrl,
      child: widget.child,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: _begin.value, end: _end.value, colors: colors),
        ),
        child: child,
      ),
    );
  }
}
