import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_shapes.dart';

class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.currentIndex,
    required this.child,
  });
  final int currentIndex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: _GlassNavBar(
        currentIndex: currentIndex,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go(AppRoutes.home);
            case 1:
              context.go(AppRoutes.myReports);
            case 2:
              context.go(AppRoutes.emergency);
            case 3:
              context.go(AppRoutes.profile);
          }
        },
      ),
    );
  }
}

// ─── Frosted floating nav bar ─────────────────────────────────────────────────

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({
    required this.currentIndex,
    required this.onTap,
  });
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _icons = [
    PhosphorIconsDuotone.house,
    PhosphorIconsDuotone.files,
    PhosphorIconsDuotone.siren,
    PhosphorIconsDuotone.userCircle,
  ];

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 12 + MediaQuery.of(context).padding.bottom),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: AppShapes.pill()),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64,
            decoration: AppShapes.card(
              color: p.surface.withValues(alpha: 0.92),
              radius: AppShapes.radiusPill,
              borderColor: p.divider,
            ),
            child: Row(
              children: List.generate(
                4,
                (i) => _NavItem(
                  icon: _icons[i],
                  index: i,
                  current: currentIndex,
                  onTap: onTap,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.index,
    required this.current,
    required this.onTap,
  });
  final IconData icon;
  final int index, current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final active = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: active ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutBack,
            builder: (context, t, child) => SizedBox(
              width: 46,
              height: 46,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: t,
                    child: Transform.scale(
                      scale: 0.7 + (0.3 * t),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: AppShapes.card(color: p.ink, radius: AppShapes.radiusPill),
                      ),
                    ),
                  ),
                  PhosphorIcon(
                    icon,
                    color: Color.lerp(p.textHint, p.background, t),
                    duotoneSecondaryColor: Color.lerp(p.textHint.withValues(alpha: 0.5), p.background.withValues(alpha: 0.6), t),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
