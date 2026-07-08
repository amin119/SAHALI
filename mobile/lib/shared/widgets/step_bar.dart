import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';

class StepBar extends StatelessWidget {
  const StepBar({super.key, required this.step, required this.total});
  final int step, total;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final activeColor = p.ink;
    final inactiveColor = p.ink.withValues(alpha: 0.15);

    return Row(
      children: List.generate(total, (i) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
          height: 4,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: i < step ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
      )),
    );
  }
}
