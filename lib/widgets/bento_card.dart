import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BentoCard extends StatefulWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final Gradient? gradient;
  final double borderRadius;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool hasStickerEffect;
  final double? width;
  final double? height;

  const BentoCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.gradient,
    this.borderRadius = 32,
    this.padding = const EdgeInsets.all(24),
    this.onTap,
    this.hasStickerEffect = true,
    this.width,
    this.height,
  });

  @override
  State<BentoCard> createState() => _BentoCardState();
}

class _BentoCardState extends State<BentoCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null ? (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      } : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        transform: _isPressed
            ? (Matrix4.identity()..translate(0.0, 2.0))
            : Matrix4.identity(),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.gradient == null
              ? (widget.backgroundColor ?? AppColors.surface)
              : null,
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: widget.borderColor ?? AppColors.cardBorder,
            width: 2,
          ),
          boxShadow: widget.hasStickerEffect && !_isPressed
              ? [
                  BoxShadow(
                    color: AppColors.stickerShadow,
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    offset: const Offset(-2, -2),
                    blurRadius: 6,
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.stickerShadow.withOpacity(0.05),
                    offset: const Offset(0, 1),
                    blurRadius: 4,
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius - 2),
          child: Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
