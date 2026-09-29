import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import 'hangout_motion.dart';

// ─── Avatar data ──────────────────────────────────────────────────────────────

class DinoData {
  final int id;
  final String name;

  /// Solid fill behind the white line drawing, from the design system's
  /// palette. Every step is dark enough to carry white strokes.
  final Color color;

  const DinoData({required this.id, required this.name, required this.color});
}

/// Ten picker avatars. The colours rotate paprika → avocado → warm ink so a
/// grid of them reads as one family, not a rainbow.
const List<DinoData> kDinoAvatars = [
  DinoData(id: 0, name: 'Diplo', color: AppColors.paprika500),
  DinoData(id: 1, name: 'Rex', color: AppColors.avocado600),
  DinoData(id: 2, name: 'Stella', color: AppColors.honey600),
  DinoData(id: 3, name: 'Blaze', color: AppColors.paprika700),
  DinoData(id: 4, name: 'Nova', color: AppColors.sand700),
  DinoData(id: 5, name: 'Coco', color: AppColors.avocado500),
  DinoData(id: 6, name: 'Thunder', color: AppColors.paprika400),
  DinoData(id: 7, name: 'Pixel', color: AppColors.sand800),
  DinoData(id: 8, name: 'Luna', color: AppColors.avocado700),
  DinoData(id: 9, name: 'Sunny', color: AppColors.paprika600),
];

// ─── Avatar circle with line-art sketch ───────────────────────────────────────

class DinoAvatar extends StatelessWidget {
  final int avatarId;
  final double size;
  final bool selected;
  final VoidCallback? onTap;

  const DinoAvatar({
    super.key,
    required this.avatarId,
    this.size = 72,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dino = kDinoAvatars[avatarId.clamp(0, kDinoAvatars.length - 1)];
    final isLong = dino.id.isEven; // sauropod vs theropod sketch

    final ring = size >= 64 ? 3.0 : 2.5;

    return Semantics(
      label: '${dino.name} avatar',
      selected: selected,
      button: onTap != null,
      child: Pressable(
        onTap: onTap,
        scale: 0.9,
        // The design system's avatar ring: a white gap, then paprika.
        child: AnimatedContainer(
          duration: AppMotion.base,
          curve: AppMotion.easeOut,
          width: size,
          height: size,
          padding: EdgeInsets.all(selected ? ring : 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? AppColors.brand : Colors.transparent,
          ),
          child: AnimatedContainer(
            duration: AppMotion.base,
            curve: AppMotion.easeOut,
            padding: EdgeInsets.all(selected ? 2 : 0),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dino.color,
              ),
              child: ClipOval(
                child: CustomPaint(
                  painter: isLong ? _SauropodPainter() : _TheropodPainter(),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sauropod (long-neck) line art ────────────────────────────────────────────
class _SauropodPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;

    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.028
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.52, h * 0.62), width: w * 0.52, height: h * 0.34),
      p,
    );

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.38, h * 0.48)
        ..quadraticBezierTo(w * 0.28, h * 0.32, w * 0.35, h * 0.18),
      p,
    );

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.38, h * 0.13), width: w * 0.16, height: w * 0.10),
      p,
    );

    final fill = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(w * 0.41, h * 0.115), w * 0.018, fill);

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.74, h * 0.60)
        ..quadraticBezierTo(w * 0.88, h * 0.56, w * 0.92, h * 0.68),
      p,
    );

    for (final xFrac in [0.42, 0.55, 0.62, 0.70]) {
      canvas.drawLine(
          Offset(w * xFrac, h * 0.76), Offset(w * xFrac, h * 0.88), p);
    }

    final dot = Paint()..color = Colors.white.withValues(alpha: 0.5);
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(Offset(w * (0.38 + i * 0.07), h * 0.44), w * 0.012, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── Theropod (T-Rex stance) line art ─────────────────────────────────────────
class _TheropodPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;

    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.028
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.60), width: w * 0.42, height: h * 0.30),
      p,
    );

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.36, h * 0.46)
        ..quadraticBezierTo(w * 0.30, h * 0.30, w * 0.38, h * 0.20),
      p,
    );

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.44, h * 0.17), width: w * 0.20, height: w * 0.12),
      p,
    );

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.34, h * 0.19)
        ..quadraticBezierTo(w * 0.42, h * 0.24, w * 0.53, h * 0.21),
      p,
    );

    final fill = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(w * 0.46, h * 0.148), w * 0.020, fill);

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.38, h * 0.50)
        ..lineTo(w * 0.28, h * 0.54)
        ..lineTo(w * 0.26, h * 0.59),
      p,
    );

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.70, h * 0.60)
        ..quadraticBezierTo(w * 0.88, h * 0.60, w * 0.93, h * 0.72),
      p,
    );

    for (final x in [0.46, 0.58]) {
      canvas.drawLine(
          Offset(w * x, h * 0.74), Offset(w * x - w * 0.04, h * 0.88), p);
      canvas.drawLine(Offset(w * x - w * 0.04, h * 0.88),
          Offset(w * x - w * 0.09, h * 0.90), p);
      canvas.drawLine(
          Offset(w * x - w * 0.04, h * 0.88), Offset(w * x, h * 0.91), p);
    }

    final dot = Paint()..color = Colors.white.withValues(alpha: 0.45);
    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(Offset(w * (0.40 + i * 0.07), h * 0.46), w * 0.012, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── User avatar (picker avatar → photo → initial) ────────────────────────────

class UserDinoAvatar extends StatelessWidget {
  final int? avatarId;
  final String? fallbackUrl;
  final String fallbackInitial;
  final double size;
  final bool ring;

  const UserDinoAvatar({
    super.key,
    required this.avatarId,
    this.fallbackUrl,
    this.fallbackInitial = '?',
    this.size = 56,
    this.ring = false,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarId != null) {
      return DinoAvatar(avatarId: avatarId!, size: size, selected: ring);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.brand,
        border: ring ? Border.all(color: AppColors.brand, width: 3) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: fallbackUrl != null && fallbackUrl!.isNotEmpty
          ? Image.network(
              fallbackUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initial(),
            )
          : _initial(),
    );
  }

  Widget _initial() => Center(
        child: Text(
          fallbackInitial.toUpperCase(),
          style: AppTextStyles.statNumber(size * 0.38)
              .copyWith(color: Colors.white),
        ),
      );
}
