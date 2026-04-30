import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/group_service.dart';
import '../models/group.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'group_detail_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  final String? preselectedMode; // 'hunger' | 'travel' | null
  const CreateGroupScreen({super.key, this.preselectedMode});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen>
    with SingleTickerProviderStateMixin {
  final _service = GroupService();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode();

  String _mode = 'hunger'; // 'hunger' | 'travel'
  bool _loading = false;

  late final AnimationController _bounceCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    lowerBound: 0.95,
    upperBound: 1.0,
  )..value = 1.0;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedMode != null) _mode = widget.preselectedMode!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    // Bounce animation on the button
    await _bounceCtrl.reverse();
    await _bounceCtrl.forward();

    setState(() => _loading = true);
    try {
      final group = await _service.createGroup(_nameController.text, _mode);
      if (!mounted) return;
      // Replace this screen with group detail
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('New Group', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.onSurface)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'What are you deciding?',
                style: AppTextStyles.headlineMedium.copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Give your group a name and pick a mode.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.outline),
              ),
              const SizedBox(height: 32),
              _buildModeSelector(),
              const SizedBox(height: 28),
              _buildNameField(),
              const Spacer(),
              _buildCreateButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Mode Selector ─────────────────────────────────────────────────────────

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(child: _ModeCard(
          emoji: '🍽️',
          label: 'Hunger',
          subtitle: 'Find restaurants',
          color: const Color(0xFF1B6D01),
          bgColor: const Color(0xFFE8FDD8),
          selected: _mode == 'hunger',
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _mode = 'hunger');
          },
        )),
        const SizedBox(width: 16),
        Expanded(child: _ModeCard(
          emoji: '🌍',
          label: 'Travel',
          subtitle: 'Explore places',
          color: const Color(0xFFA83300),
          bgColor: const Color(0xFFFFEDE8),
          selected: _mode == 'travel',
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _mode = 'travel');
          },
        )),
      ],
    );
  }

  // ─── Name field ────────────────────────────────────────────────────────────

  Widget _buildNameField() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Group name', style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurface)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            focusNode: _nameFocus,
            textCapitalization: TextCapitalization.words,
            maxLength: 40,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurface),
            decoration: InputDecoration(
              counterText: '',
              hintText: _mode == 'hunger' ? 'e.g. Friday Night Crew' : 'e.g. Weekend Getaway',
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.outline),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _mode == 'hunger' ? AppColors.primaryGreen : AppColors.tertiaryOrange,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.error, width: 2),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _mode == 'hunger' ? '🍽️' : '🌍',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 56, minHeight: 56),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter a group name';
              if (v.trim().length < 2) return 'Name must be at least 2 characters';
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ─── Create button ─────────────────────────────────────────────────────────

  Widget _buildCreateButton() {
    final gradient = _mode == 'hunger'
        ? AppColors.greenGradient
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF9600), Color(0xFFFF5200)],
          );

    return ScaleTransition(
      scale: _bounceCtrl,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: _loading ? null : gradient,
            color: _loading ? AppColors.surfaceContainerHigh : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ElevatedButton(
            onPressed: _loading ? null : _create,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Create Group',
                        style: AppTextStyles.button.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Mode card widget ─────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? bgColor : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : AppColors.cardBorder,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(label,
                style: AppTextStyles.labelBold.copyWith(
                  color: selected ? color : AppColors.onSurface,
                )),
            Text(subtitle,
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.outline)),
          ],
        ),
      ),
    );
  }
}
