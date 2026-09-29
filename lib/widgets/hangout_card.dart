import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import 'hangout_chips.dart';
import 'hangout_motion.dart';

enum CardElevation { flat, sm, md, lg }

/// Generic soft surface panel — white on cream, warm-tinted shadow, no border.
/// Only [CardElevation.flat] cards get a hairline border.
class HangoutCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final CardElevation elevation;
  final double radius;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final Border? border;

  const HangoutCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.elevation = CardElevation.md,
    this.radius = AppRadius.lg,
    this.color,
    this.gradient,
    this.onTap,
    this.width,
    this.height,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final shadow = switch (elevation) {
      CardElevation.flat => const <BoxShadow>[],
      CardElevation.sm => AppShadows.sm,
      CardElevation.md => AppShadows.md,
      CardElevation.lg => AppShadows.lg,
    };

    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: gradient == null ? (color ?? AppColors.surface) : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: shadow,
          border:
              border ??
              (elevation == CardElevation.flat
                  ? Border.all(color: AppColors.border)
                  : null),
        ),
        child: child,
      ),
    );
  }
}

/// The signature image-forward place card: photo top, floating glass rating
/// badge and favourite, then title / location / tags below.
///
/// Text never sits on a raw photo — anything over the image rides on
/// [AppColors.photoScrim].
class PlaceCard extends StatefulWidget {
  final String title;
  final String? imageUrl;
  final String? location;
  final double? rating;
  final List<String> tags;
  final Widget? meta;
  final bool favorite;
  final VoidCallback? onFavorite;
  final VoidCallback? onTap;
  final double width;
  final double? imageHeight;

  const PlaceCard({
    super.key,
    required this.title,
    this.imageUrl,
    this.location,
    this.rating,
    this.tags = const [],
    this.meta,
    this.favorite = false,
    this.onFavorite,
    this.onTap,
    this.width = 260,
    this.imageHeight,
  });

  @override
  State<PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<PlaceCard> {
  /// Room the title / location / tags block needs before the photo starts
  /// giving up height.
  static const _minInfoHeight = 96.0;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: widget.onTap,
      scale: 0.97,
      child: LayoutBuilder(
        builder: (context, constraints) {
          var imgH = widget.imageHeight ?? widget.width * 0.72;

          // In a fixed-height rail, shrink the photo rather than let the text
          // block get squeezed out of the card.
          if (constraints.hasBoundedHeight) {
            final room = constraints.maxHeight - _minInfoHeight;
            if (room < imgH) imgH = room < 0 ? 0 : room;
          }

          return _buildCard(imgH);
        },
      ),
    );
  }

  Widget _buildCard(double imgH) {
    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlAll,
        boxShadow: AppShadows.lg,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: imgH,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                HangoutPhoto(url: widget.imageUrl),
                if (widget.rating != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: HangoutBadge.rating(widget.rating!),
                  ),
                if (widget.onFavorite != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Pressable(
                      onTap: widget.onFavorite,
                      scale: 0.86,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.sm,
                        ),
                        child: AnimatedSwitcher(
                          duration: AppMotion.fast,
                          transitionBuilder:
                              (child, anim) =>
                                  ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            widget.favorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey(widget.favorite),
                            size: 17,
                            color:
                                widget.favorite
                                    ? AppColors.brand
                                    : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Flexible + a non-scrolling scroll view: the photo above already
          // yields height, and this guarantees the card clips rather than
          // throwing if the text still doesn't fit (very large text scale).
          Flexible(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title,
                    ),
                    if (widget.location != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              widget.location!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.small,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (widget.tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final t in widget.tags.take(3))
                            HangoutTag(label: t),
                        ],
                      ),
                    ],
                    if (widget.meta != null) ...[
                      const SizedBox(height: 12),
                      widget.meta!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Network photo with a sunken placeholder while it loads, a short fade once
/// decoded, and a plain fallback when there is no image.
class HangoutPhoto extends StatelessWidget {
  final String? url;
  final IconData fallbackIcon;

  const HangoutPhoto({
    super.key,
    this.url,
    this.fallbackIcon = Icons.restaurant_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = _PhotoFallback(icon: fallbackIcon);
    if (url == null || url!.isEmpty) return fallback;

    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
      frameBuilder: (context, child, frame, wasSync) {
        if (wasSync) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: AppMotion.base,
          curve: AppMotion.easeOut,
          child: frame == null ? fallback : child,
        );
      },
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  final IconData icon;

  const _PhotoFallback({required this.icon});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceSunken,
      child: Center(child: Icon(icon, size: 26, color: AppColors.sand400)),
    );
  }
}
