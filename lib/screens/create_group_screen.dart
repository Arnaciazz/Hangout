import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/group_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/hangout_button.dart';
import 'group_detail_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  final String? preselectedMode; // 'hunger' | 'travel' | null
  const CreateGroupScreen({super.key, this.preselectedMode});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _service = GroupService();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode();

  String _mode = 'hunger';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedMode != null) _mode = widget.preselectedMode!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  bool get _isHunger => _mode == 'hunger';

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();

    setState(() => _loading = true);
    try {
      final group = await _service.createGroup(_nameController.text, _mode);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String msg) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(leading: const HangoutBackButton()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter, AppSpacing.x2, AppSpacing.gutter, AppSpacing.x8),
        children: [
          Text('New crew', style: AppTextStyles.h1),
          const SizedBox(height: 4),
          Text(
            'The people you decide with. You’ll get a code to share.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.x8),
          Text('What will you decide?', style: AppTextStyles.smallStrong),
          const SizedBox(height: AppSpacing.x2),
          _ModeToggle(
            value: _mode,
            onChanged: (m) {
              HapticFeedback.selectionClick();
              setState(() => _mode = m);
            },
          ),
          const SizedBox(height: AppSpacing.x6),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameController,
              focusNode: _nameFocus,
              textCapitalization: TextCapitalization.words,
              maxLength: 40,
              style: AppTextStyles.body.copyWith(color: AppColors.textStrong),
              decoration: InputDecoration(
                labelText: 'Crew name',
                hintText: _isHunger ? 'Friday dinner lot' : 'Weekend wanderers',
                counterText: '',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Give the crew a name';
                if (v.trim().length < 2) return 'A bit longer than that';
                return null;
              },
              onFieldSubmitted: (_) => _create(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyActionBar(
        child: HangoutButton(
          label: 'Create crew',
          size: HangoutButtonSize.lg,
          block: true,
          loading: _loading,
          onPressed: _create,
        ),
      ),
    );
  }
}

/// Two-option segmented control in the design system's pill vocabulary.
class _ModeToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _ModeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget segment(String mode, IconData icon, String label) {
      final selected = value == mode;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(mode),
            child: AnimatedContainer(
              duration: AppMotion.base,
              curve: AppMotion.easeOut,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? AppColors.surface : Colors.transparent,
                borderRadius: AppRadius.pillAll,
                boxShadow: selected ? AppShadows.sm : const [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 18,
                      color: selected ? AppColors.brand : AppColors.textMuted),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: AppTextStyles.smallStrong.copyWith(
                      color: selected ? AppColors.textStrong : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        children: [
          segment('hunger', Icons.restaurant_rounded, 'Food'),
          segment('travel', Icons.explore_rounded, 'Places'),
        ],
      ),
    );
  }
}
