import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_shapes.dart';

/// The small "?" button every screen with a guided tour shows in its AppBar —
/// tap it to replay that screen's walkthrough on demand.
class TourButton extends StatelessWidget {
  const TourButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(right: 4),
      decoration: AppShapes.card(color: p.surfaceVariant, radius: AppShapes.radiusMd),
      child: IconButton(
        icon: PhosphorIcon(PhosphorIconsRegular.question, color: p.textSecondary, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}
