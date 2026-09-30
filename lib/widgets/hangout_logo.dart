import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The Hangout mark from the design system (`assets/logo-mark.svg`): two
/// overlapping circles — friends meeting, a shared plate. Paprika on the left,
/// avocado multiplied over it on the right.
class HangoutMark extends StatelessWidget {
  final double size;

  const HangoutMark({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Hangout',
      image: true,
      child: CustomPaint(
        size: Size(size, size),
        painter: const _MarkPainter(),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Geometry from the 64×64 source SVG: circles at x=26 and x=42, r=18.
    final s = size.width / 64;
    final r = 18 * s;
    final cy = 32 * s;

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawCircle(
      Offset(26 * s, cy),
      r,
      Paint()..color = AppColors.paprika500,
    );
    canvas.drawCircle(
      Offset(42 * s, cy),
      r,
      Paint()
        ..color = AppColors.avocado500.withValues(alpha: 0.9)
        ..blendMode = BlendMode.multiply,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MarkPainter oldDelegate) => false;
}

/// Mark + "Hangout" wordmark, as in `assets/logo.svg`.
class HangoutWordmark extends StatelessWidget {
  final double height;

  const HangoutWordmark({super.key, this.height = 28});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HangoutMark(size: height),
        SizedBox(width: height * 0.18),
        Text(
          'Hangout',
          style: AppTextStyles.statNumber(height * 0.78),
        ),
      ],
    );
  }
}
