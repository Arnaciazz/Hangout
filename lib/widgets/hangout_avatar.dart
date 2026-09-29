import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';

/// Circular avatar with an image, initials fallback, and an optional brand
/// status ring.
class HangoutAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool ring;
  final Color? ringColor;

  const HangoutAvatar({
    super.key,
    this.imageUrl,
    this.name = '',
    this.size = 44,
    this.ring = false,
    this.ringColor,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0]).join().toUpperCase();
  }

  /// Deterministic warm tint so each person keeps the same colour everywhere.
  Color get _tint {
    const palette = [
      AppColors.avocado200,
      AppColors.paprika200,
      AppColors.honey300,
      AppColors.sand300,
      AppColors.avocado300,
    ];
    if (name.isEmpty) return palette.first;
    return palette[name.codeUnits.fold<int>(0, (a, b) => a + b) % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final fill = _tint;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: ring
            ? Border.all(color: ringColor ?? AppColors.brand, width: 2)
            : null,
        boxShadow: AppShadows.sm,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initialsChild(),
            )
          : _initialsChild(),
    );
  }

  Widget _initialsChild() {
    return Center(
      child: Text(
        _initials,
        style: AppTextStyles.statNumber(size * 0.36)
            .copyWith(color: AppColors.sand800),
      ),
    );
  }
}

/// Overlapping stack of avatars — "5 friends going".
class AvatarGroup extends StatelessWidget {
  final List<({String name, String? imageUrl})> people;
  final double size;
  final int max;

  const AvatarGroup({
    super.key,
    required this.people,
    this.size = 32,
    this.max = 4,
  });

  @override
  Widget build(BuildContext context) {
    final shown = people.take(max).toList();
    final extra = people.length - shown.length;

    if (shown.isEmpty) return const SizedBox.shrink();

    // Each avatar sits `step` from the previous one, so they overlap by
    // roughly a third. Laid out with a Stack rather than negative margins —
    // Container asserts margins are non-negative.
    final step = size * 0.66;
    final slots = shown.length + (extra > 0 ? 1 : 0);
    final width = step * (slots - 1) + size;

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: step * i,
              top: 0,
              child: Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                ),
                padding: const EdgeInsets.all(2),
                child: HangoutAvatar(
                  name: shown[i].name,
                  imageUrl: shown[i].imageUrl,
                  size: size - 4,
                ),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: step * shown.length,
              top: 0,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceInverse,
                  shape: BoxShape.circle,
                  border: const Border.fromBorderSide(
                    BorderSide(color: AppColors.surface, width: 2),
                  ),
                ),
                child: Text(
                  '+$extra',
                  style: AppTextStyles.captionStrong.copyWith(
                    color: Colors.white,
                    fontSize: size * 0.32,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
