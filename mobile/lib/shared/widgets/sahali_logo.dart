import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The Sahali app logo — a location pin with a checkmark inside,
/// sitting on a deep-blue gradient rounded square.
class SahaliLogo extends StatelessWidget {
  const SahaliLogo({super.key, this.size = 88});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B6CE6), Color(0xFF0038AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0038AF).withValues(alpha: 0.35),
            blurRadius: size * 0.38,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _PinPainter(),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size sz) {
    final w = sz.width;
    final h = sz.height;
    final cx = w / 2;

    // Pin geometry
    final r = w * 0.265; // circle radius
    final cy = h * 0.385; // circle centre Y
    final tipY = h * 0.815; // pin tip Y
    final d = tipY - cy;
    final alpha = math.asin(r / d);

    // Tangent points on the circle
    final rightTx = cx + r * math.cos(alpha);
    final rightTy = cy + r * math.sin(alpha);

    // ── White pin body ──────────────────────────────────────────────────────
    final pinPath = Path()
      ..moveTo(cx, tipY)
      ..lineTo(rightTx, rightTy)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        alpha,
        -(math.pi + 2 * alpha),
        false,
      )
      ..close();

    canvas.drawPath(
      pinPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // ── Inner circle (creates the "hole" in the pin) ─────────────────────────
    final innerR = r * 0.505;
    canvas.drawCircle(
      Offset(cx, cy),
      innerR,
      Paint()
        ..color = const Color(0xFF0B3DB5)
        ..style = PaintingStyle.fill,
    );

    // ── White checkmark ──────────────────────────────────────────────────────
    final ck = innerR * 0.62;
    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerR * 0.23
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      Path()
        ..moveTo(cx - ck * 0.52, cy + ck * 0.06)
        ..lineTo(cx - ck * 0.10, cy + ck * 0.56)
        ..lineTo(cx + ck * 0.62, cy - ck * 0.52),
      checkPaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
