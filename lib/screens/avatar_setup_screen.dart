import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/profile_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/dino_avatar.dart';
import '../widgets/hangout_button.dart';

// ─── Nickname generator ───────────────────────────────────────────────────────

const _adjectives = [
  'Cool', 'Brave', 'Swift', 'Mighty', 'Happy', 'Wild', 'Cosmic',
  'Neon', 'Fluffy', 'Dapper', 'Zesty', 'Epic', 'Speedy', 'Groovy',
  'Silly', 'Snazzy', 'Rad', 'Fierce', 'Cozy', 'Jolly',
];

const _dinoNames = [
  'Rex', 'Diplo', 'Stego', 'Raptor', 'Bronto', 'Trex', 'Ptero',
  'Anky', 'Tricera', 'Spiney', 'Carno', 'Allo', 'Iggy', 'Dino',
];

String generateNickname() {
  final rng = Random();
  final adj = _adjectives[rng.nextInt(_adjectives.length)];
  final dino = _dinoNames[rng.nextInt(_dinoNames.length)];
  final num = rng.nextInt(900) + 100;
  return '$adj$dino$num';
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AvatarSetupScreen extends StatefulWidget {
  final VoidCallback? onSetupComplete;

  /// When set, the screen edits an existing profile instead of onboarding.
  final String? initialNickname;
  final int? initialAvatarId;

  const AvatarSetupScreen({
    super.key,
    this.onSetupComplete,
    this.initialNickname,
    this.initialAvatarId,
  });

  bool get isEditing => initialNickname != null;

  @override
  State<AvatarSetupScreen> createState() => _AvatarSetupScreenState();
}

class _AvatarSetupScreenState extends State<AvatarSetupScreen> {
  final _profileService = ProfileService();
  final _nicknameCtrl = TextEditingController();

  late int _selectedAvatarId =
      (widget.initialAvatarId ?? 0).clamp(0, kDinoAvatars.length - 1);
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nicknameCtrl.text = widget.initialNickname ?? generateNickname();
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    super.dispose();
  }

  void _regenerateNickname() {
    HapticFeedback.selectionClick();
    setState(() => _nicknameCtrl.text = generateNickname());
  }

  Future<void> _save() async {
    final nickname = _nicknameCtrl.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a nickname first')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _profileService.saveNicknameAndAvatar(
        nickname: nickname,
        avatarId: _selectedAvatarId,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      widget.onSetupComplete?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Couldn't save that: $e"),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = kDinoAvatars[_selectedAvatarId];
    final editing = widget.isEditing;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: editing
          ? AppBar(
              leading: const HangoutBackButton(),
              title: Text('Edit profile', style: AppTextStyles.title),
            )
          : null,
      body: SafeArea(
        top: !editing,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            editing ? AppSpacing.x2 : AppSpacing.x8,
            AppSpacing.gutter,
            AppSpacing.x8,
          ),
          children: [
            if (!editing) ...[
              Text('Make it yours', style: AppTextStyles.h1),
              const SizedBox(height: 4),
              Text(
                'This is how your crews will see you. You can change it later.',
                style: AppTextStyles.small,
              ),
              const SizedBox(height: AppSpacing.x8),
            ],
            Row(
              children: [
                AnimatedSwitcher(
                  duration: AppMotion.base,
                  switchInCurve: AppMotion.spring,
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: DinoAvatar(
                    key: ValueKey(_selectedAvatarId),
                    avatarId: _selectedAvatarId,
                    size: 88,
                  ),
                ),
                const SizedBox(width: AppSpacing.x4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selected.name, style: AppTextStyles.h3),
                      const SizedBox(height: 2),
                      ListenableBuilder(
                        listenable: _nicknameCtrl,
                        builder: (context, _) => Text(
                          '@${_nicknameCtrl.text.trim()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.small,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: kDinoAvatars.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: AppSpacing.x3,
                crossAxisSpacing: AppSpacing.x3,
              ),
              itemBuilder: (context, i) => DinoAvatar(
                avatarId: i,
                size: 56,
                selected: _selectedAvatarId == i,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedAvatarId = i);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.x8),
            TextField(
              controller: _nicknameCtrl,
              maxLength: 20,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              style: AppTextStyles.bodyStrong,
              decoration: InputDecoration(
                labelText: 'Nickname',
                prefixText: '@',
                prefixStyle:
                    AppTextStyles.bodyStrong.copyWith(color: AppColors.brand),
                helperText: 'Shuffle for a new one, or type your own.',
                suffixIcon: HangoutIconButton(
                  icon: Icons.shuffle_rounded,
                  tooltip: 'New nickname',
                  onPressed: _regenerateNickname,
                ),
              ),
              buildCounter: (_,
                      {required currentLength,
                      required isFocused,
                      maxLength}) =>
                  null,
            ),
          ],
        ),
      ),
      bottomNavigationBar: StickyActionBar(
        child: HangoutButton(
          label: editing ? 'Save' : "Let's go",
          size: HangoutButtonSize.lg,
          block: true,
          loading: _saving,
          onPressed: _save,
        ),
      ),
    );
  }
}
