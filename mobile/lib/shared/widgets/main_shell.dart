import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';

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
      backgroundColor: AppColors.background,
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

// ─── Frosted glass nav bar ────────────────────────────────────────────────────

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({
    required this.currentIndex,
    required this.onTap,
  });
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _gradients = [
    [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    [Color(0xFF7C3AED), Color(0xFF6D28D9)],
    [Color(0xFFDC2626), Color(0xFFB91C1C)],
    [Color(0xFF0D9488), Color(0xFF0F766E)],
  ];

  static const _icons = [
    (Icons.home_outlined, Icons.home_rounded),
    (Icons.description_outlined, Icons.description_rounded),
    (Icons.emergency_outlined, Icons.emergency_rounded),
    (Icons.account_circle_outlined, Icons.account_circle_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            border: Border(
              top: BorderSide(
                color: Colors.black.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: List.generate(
                  4,
                  (i) => _NavItem(
                    icon: _icons[i].$1,
                    activeIcon: _icons[i].$2,
                    index: i,
                    current: currentIndex,
                    onTap: onTap,
                    gradientColors: _gradients[i],
                  ),
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
    required this.activeIcon,
    required this.index,
    required this.current,
    required this.onTap,
    required this.gradientColors,
  });
  final IconData icon, activeIcon;
  final int index, current;
  final ValueChanged<int> onTap;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOut,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: active
                  ? LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              shape: BoxShape.circle,
            ),
            child: Icon(
              active ? activeIcon : icon,
              color: active ? Colors.white : AppColors.textHint,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
