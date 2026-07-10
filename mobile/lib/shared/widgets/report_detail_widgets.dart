import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_palette.dart';
import 'status_badge.dart';

/// Shared read-only report-detail display pieces, used by both the citizen
/// report detail screen and the field-agent mission detail screen.

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppPalette.of(context).textHint, letterSpacing: 0.8),
  );
}

class TimelineRow extends StatelessWidget {
  const TimelineRow({
    super.key,
    required this.status,
    required this.date,
    required this.note,
    required this.isLast,
    required this.isActive,
  });
  final ReportStatus status;
  final String date, note;
  final bool isLast, isActive;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final color = isActive ? status.color(p) : p.divider;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    color: isActive ? color : p.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: p.divider, margin: const EdgeInsets.symmetric(vertical: 4)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusBadge(status: status),
                  const SizedBox(height: 4),
                  Text(note, style: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.4)),
                  const SizedBox(height: 2),
                  Text(date, style: TextStyle(fontSize: 11, color: p.textHint)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Photo hero: swipeable when multiple photos ────────────────────────────────

class PhotoHero extends StatefulWidget {
  const PhotoHero({super.key, required this.urls});
  final List<String> urls;
  @override
  State<PhotoHero> createState() => _PhotoHeroState();
}

class _PhotoHeroState extends State<PhotoHero> {
  int _current = 0;
  late final PageController _ctrl = PageController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _ctrl,
          itemCount: widget.urls.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (_, i) => Image.network(
            widget.urls[i],
            fit: BoxFit.cover,
            headers: const {'ngrok-skip-browser-warning': '1'},
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: Color(0xFFe8edf2),
              child: Icon(PhosphorIconsRegular.imageBroken, size: 40, color: Color(0xFF94A3B8)),
            ),
          ),
        ),
        if (widget.urls.length > 1)
          Positioned(
            bottom: 10, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.urls.length, (i) => Container(
                width: _current == i ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _current == i ? Colors.white : Colors.white54,
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
          ),
      ],
    );
  }
}
