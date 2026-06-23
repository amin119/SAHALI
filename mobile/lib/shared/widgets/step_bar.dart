import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StepBar extends StatelessWidget {
  const StepBar({super.key, required this.step, required this.total});
  final int step, total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
          height: 4,
          decoration: BoxDecoration(
            color: i < step ? AppColors.primary : AppColors.divider,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      )),
    );
  }
}
