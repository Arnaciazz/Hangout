import 'package:flutter/material.dart';

import '../screens/mode_lobby_screen.dart';
import '../theme/app_colors.dart';
import 'hangout_list.dart';

/// "What are we deciding?" — the one way to start a hangout, shared by the
/// centre tab and Home.
///
/// [onPick] receives 'hunger' or 'travel' after the sheet closes; by default
/// it opens that mode's lobby.
Future<void> showStartHangoutSheet(
  BuildContext context, {
  void Function(String mode)? onPick,
}) {
  void pick(BuildContext sheet, String mode) {
    Navigator.pop(sheet);
    if (onPick != null) {
      onPick(mode);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ModeLobbyScreen(mode: mode),
    ));
  }

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => HangoutSheet(
      title: 'What are we deciding?',
      child: HangoutListGroup(
        children: [
          HangoutListRow(
            leading: const Icon(Icons.restaurant_rounded, color: AppColors.brand),
            title: 'Somewhere to eat',
            subtitle: 'Restaurants, cafés, bars',
            showChevron: true,
            onTap: () => pick(ctx, 'hunger'),
          ),
          HangoutListRow(
            leading: const Icon(Icons.explore_rounded, color: AppColors.brand),
            title: 'Somewhere to go',
            subtitle: 'Parks, museums, days out',
            showChevron: true,
            onTap: () => pick(ctx, 'travel'),
          ),
        ],
      ),
    ),
  );
}
