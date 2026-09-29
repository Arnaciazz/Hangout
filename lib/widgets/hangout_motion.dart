import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_tokens.dart';

/// Wraps any widget in Hangout's press behaviour: a springy scale-down with a
/// light haptic tick. Presses *bounce* — they never just darken.
///
/// This is the app's only ambient motion. Screens do not animate in; state
/// changes (selection, a card leaving the deck) carry their own transitions.
///
/// [scale] follows the design system: 0.96 for buttons and cards, 0.90 for
/// round icon buttons.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptics;
  final HitTestBehavior behavior;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.96,
    this.haptics = true,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  // Created eagerly in initState, never lazily: a disabled Pressable returns
  // early from build() without touching these, and a lazy `late final` would
  // then construct a Ticker inside dispose() — which throws, because the
  // element is already deactivated by then.
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
      reverseDuration: AppMotion.base,
    );
    _anim = Tween<double>(begin: 1, end: widget.scale).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: AppMotion.easeOut,
        reverseCurve: AppMotion.spring,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled) return widget.child;

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) {
        _ctrl.forward();
        if (widget.haptics) HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: _ctrl.reverse,
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              if (widget.haptics) HapticFeedback.mediumImpact();
              widget.onLongPress!.call();
            },
      child: ScaleTransition(scale: _anim, child: widget.child),
    );
  }
}
