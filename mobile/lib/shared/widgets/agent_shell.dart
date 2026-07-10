import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_shapes.dart';

/// Bottom-nav shell for field_agent accounts — same visual chrome as
/// [MainShell] (citizens), but a distinct 3-tab set: Missions, Notifications,
/// Profile. Kept as a separate widget rather than a parameterized MainShell
/// since MainShell's nav bar is a private, hardcoded-to-4-tabs widget.
class AgentShell extends StatelessWidget {
  const AgentShell({
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
      bottomNavigationBar: _AgentGlassNavBar(
        currentIndex: currentIndex,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go(AppRoutes.agentMissions);
            case 1:
              context.go(AppRoutes.agentNotifications);
            case 2:
              context.go(AppRoutes.agentProfile);
          }
        },
      ),
    );
  }
}

// ─── Frosted floating nav bar (agent variant, 3 tabs) ─────────────────────────

class _AgentGlassNavBar extends StatelessWidget {
  const _AgentGlassNavBar({
    required this.currentIndex,
    required this.onTap,
  });
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _icons = [
    PhosphorIconsDuotone.clipboardText,
    PhosphorIconsDuotone.bell,
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
                3,
                (i) => _AgentNavItem(
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

class _AgentNavItem extends StatelessWidget {
  const _AgentNavItem({
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
