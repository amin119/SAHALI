import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_shapes.dart';

/// Shows [child] in a rounded, drag-handled modal bottom sheet — the
/// standard pattern for drill-down detail views (report detail, category
/// picking) instead of always pushing a full page.
Future<T?> showSaBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  final p = AppPalette.of(context);
  final surface = p.surface;
  final handleColor = p.border;

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: ShapeDecoration(
        color: surface,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.only(
            topLeft: SmoothRadius(cornerRadius: AppShapes.radiusXl, cornerSmoothing: AppShapes.smoothing),
            topRight: SmoothRadius(cornerRadius: AppShapes.radiusXl, cornerSmoothing: AppShapes.smoothing),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(child: builder(ctx)),
          ],
        ),
      ),
    ),
  );
}
