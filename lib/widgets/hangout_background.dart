import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The app's ground: flat warm cream (`sand-50`), per the design system.
///
/// Every screen's Scaffold is transparent and sits on this, so the ground is
/// defined once. It is deliberately plain — white surfaces on cream carry the
/// hierarchy; the background never competes with them.
class HangoutBackground extends StatelessWidget {
  final Widget child;

  const HangoutBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: AppColors.bg, child: child);
  }
}
