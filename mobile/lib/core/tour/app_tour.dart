import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../theme/app_palette.dart';
import '../theme/app_shapes.dart';

export 'package:tutorial_coach_mark/tutorial_coach_mark.dart' show ContentAlign, ShapeLightFocus;

/// One spotlight step of a screen's guided tour — a widget to highlight plus
/// the title/description shown next to it.
class TourStep {
  const TourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.align = ContentAlign.bottom,
    this.shape = ShapeLightFocus.RRect,
    this.radius = 16,
  });

  final GlobalKey targetKey;
  final String title;
  final String description;
  final ContentAlign align;
  final ShapeLightFocus shape;
  final double radius;
}

/// Starts a guided tour of the current screen — one spotlight + rounded
/// info card per [TourStep], in order, with Next/Previous/Done controls.
void showScreenTour(BuildContext context, List<TourStep> steps, {String? skipLabel, String? doneLabel}) {
  final targets = <TargetFocus>[];
  for (var i = 0; i < steps.length; i++) {
    final step = steps[i];
    final isLast = i == steps.length - 1;
    targets.add(
      TargetFocus(
        identify: 'tour_step_$i',
        keyTarget: step.targetKey,
        shape: step.shape,
        radius: step.radius,
        paddingFocus: 6,
        contents: [
          TargetContent(
            align: step.align,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            builder: (ctx, controller) => _TourCard(
              title: step.title,
              description: step.description,
              stepIndex: i,
              stepCount: steps.length,
              isLast: isLast,
              doneLabel: doneLabel,
              onNext: () => isLast ? controller.skip() : controller.next(),
            ),
          ),
        ],
      ),
    );
  }

  TutorialCoachMark(
    targets: targets,
    colorShadow: Colors.black,
    opacityShadow: 0.72,
    hideSkip: true,
    pulseEnable: true,
  ).show(context: context);
}

class _TourCard extends StatelessWidget {
  const _TourCard({
    required this.title,
    required this.description,
    required this.stepIndex,
    required this.stepCount,
    required this.isLast,
    required this.onNext,
    this.doneLabel,
  });

  final String title;
  final String description;
  final int stepIndex;
  final int stepCount;
  final bool isLast;
  final VoidCallback onNext;
  final String? doneLabel;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.all(18),
      decoration: AppShapes.card(color: p.surface, radius: 18, shadows: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 10)),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.textPrimary)),
          const SizedBox(height: 6),
          Text(description, style: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.5)),
          const SizedBox(height: 14),
          Row(
            children: [
              Row(
                children: List.generate(stepCount, (i) {
                  final active = i == stepIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 5),
                    width: active ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? p.primary : p.divider,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  );
                }),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onNext,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(color: p.primary, borderRadius: BorderRadius.circular(100)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLast ? (doneLabel ?? 'OK') : '',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      if (!isLast)
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
