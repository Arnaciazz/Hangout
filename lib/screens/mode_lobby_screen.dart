import 'package:flutter/material.dart';

import '../models/group.dart';
import '../services/group_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/hangout_avatar.dart';
import '../widgets/hangout_button.dart';
import '../widgets/hangout_chips.dart';
import '../widgets/hangout_list.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import 'session_setup_screen.dart';

/// After picking what to decide: choose who's deciding — one of your crews in
/// this mode, or just you.
class ModeLobbyScreen extends StatefulWidget {
  final String mode; // 'hunger' | 'travel'

  const ModeLobbyScreen({super.key, required this.mode});

  @override
  State<ModeLobbyScreen> createState() => _ModeLobbyScreenState();
}

class _ModeLobbyScreenState extends State<ModeLobbyScreen> {
  final _service = GroupService();
  late final Stream<List<Group>> _groups = _service.watchMyGroups();

  bool get _isHunger => widget.mode == 'hunger';

  void _start(Group? group) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SessionSetupScreen(group: group, mode: widget.mode),
    ));
  }

  void _newCrew() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CreateGroupScreen(preselectedMode: widget.mode),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(leading: const HangoutBackButton()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter, AppSpacing.x2, AppSpacing.gutter, AppSpacing.x10),
        children: [
          Text(_isHunger ? 'Where to eat' : 'Where to go',
              style: AppTextStyles.h1),
          const SizedBox(height: 4),
          Text('Pick who’s deciding.', style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.x8),
          SectionHeader(
            title: 'With a crew',
            trailing: HangoutButton(
              label: 'New',
              iconLeft: Icons.add_rounded,
              size: HangoutButtonSize.sm,
              variant: HangoutButtonVariant.ghost,
              onPressed: _newCrew,
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          StreamBuilder<List<Group>>(
            stream: _groups,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const SizedBox(
                  height: 72,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final groups =
                  snap.data!.where((g) => g.mode == widget.mode).toList();
              if (groups.isEmpty) return _noCrews();

              return HangoutListGroup(
                children: [
                  for (final g in groups)
                    HangoutListRow(
                      leading: HangoutAvatar(name: g.name, size: 40),
                      title: g.name,
                      subtitle:
                          '${g.memberCount} ${g.memberCount == 1 ? 'person' : 'people'}',
                      trailing: HangoutButton(
                        label: 'Start',
                        size: HangoutButtonSize.sm,
                        variant: HangoutButtonVariant.tonal,
                        onPressed: () => _start(g),
                      ),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => GroupDetailScreen(group: g),
                      )),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.x8),
          const SectionHeader(title: 'On your own'),
          const SizedBox(height: AppSpacing.x2),
          HangoutListGroup(
            children: [
              HangoutListRow(
                leading: const SizedBox(
                  width: 40,
                  child: Icon(Icons.person_rounded, color: AppColors.textMuted),
                ),
                title: 'Just me',
                subtitle: 'Swipe solo and decide fast',
                showChevron: true,
                onTap: () => _start(null),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _noCrews() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isHunger ? 'No food crews yet' : 'No explore crews yet',
            style: AppTextStyles.title,
          ),
          const SizedBox(height: 4),
          Text(
            'Start one, share the code, and everyone swipes on the same places.',
            style: AppTextStyles.small,
          ),
          const SizedBox(height: AppSpacing.x3),
          HangoutButton(
            label: 'Start a crew',
            size: HangoutButtonSize.sm,
            variant: HangoutButtonVariant.tonal,
            onPressed: _newCrew,
          ),
        ],
      ),
    );
  }
}
