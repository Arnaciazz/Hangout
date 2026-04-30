import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group.dart';
import '../services/group_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'session_setup_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final _service = GroupService();
  late Group _group;
  bool _loadingCode = false;

  String get _myId => Supabase.instance.client.auth.currentUser!.id;
  bool get _amOwner => _group.isOwner(_myId);

  @override
  void initState() {
    super.initState();
    _group = widget.group;
  }

  // ─── Refresh code ──────────────────────────────────────────────────────────

  Future<void> _refreshCode() async {
    setState(() => _loadingCode = true);
    try {
      final newCode = await _service.refreshInviteCode(_group.id);
      setState(() {
        _group = Group(
          id: _group.id,
          name: _group.name,
          mode: _group.mode,
          createdBy: _group.createdBy,
          inviteCode: newCode,
          createdAt: _group.createdAt,
          members: _group.members,
        );
      });
    } catch (_) {
      _showError('Could not refresh code.');
    } finally {
      if (mounted) setState(() => _loadingCode = false);
    }
  }

  // ─── Copy to clipboard ────────────────────────────────────────────────────

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _group.inviteCode));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Code copied!',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
      backgroundColor: AppColors.primaryGreen,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─── WhatsApp share ───────────────────────────────────────────────────────

  Future<void> _shareWhatsApp() async {
    final message = Uri.encodeComponent(
      'Join my Shuffle group *${_group.name}* '
      '${_group.mode == 'hunger' ? '🍽️' : '🌍'}\n\n'
      'Use invite code: *${_group.inviteCode}*\n\n'
      'Download Shuffle and enter the code to join!',
    );
    final uri = Uri.parse('whatsapp://send?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback: share the message text for the user to copy
      await Clipboard.setData(ClipboardData(
        text: 'Join my Shuffle group "${_group.name}" — code: ${_group.inviteCode}',
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'WhatsApp not found — invite text copied to clipboard!',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.tertiaryOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  // ─── Leave / delete group ─────────────────────────────────────────────────

  Future<void> _confirmLeave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _amOwner ? 'Delete Group?' : 'Leave Group?',
          style: AppTextStyles.headlineSmall,
        ),
        content: Text(
          _amOwner
              ? 'This will delete "${_group.name}" and remove all members.'
              : 'You will leave "${_group.name}".',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.outline),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppTextStyles.labelBold.copyWith(color: AppColors.outline)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              _amOwner ? 'Delete' : 'Leave',
              style: AppTextStyles.labelBold.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      if (_amOwner) {
        await _service.deleteGroup(_group.id);
        // Pop all the way back to home so the group list refreshes via stream
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        await _service.leaveGroup(_group.id);
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceFirst('Exception: ', ''));
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

  // ─── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isHunger = _group.mode == 'hunger';
    final modeColor = isHunger ? const Color(0xFF1B6D01) : const Color(0xFFA83300);
    final modeBg = isHunger ? const Color(0xFFE8FDD8) : const Color(0xFFFFEDE8);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _amOwner ? Icons.delete_outline_rounded : Icons.logout_rounded,
              color: AppColors.error,
            ),
            tooltip: _amOwner ? 'Delete group' : 'Leave group',
            onPressed: _confirmLeave,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: modeBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(isHunger ? '🍽️' : '🌍',
                      style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_group.name,
                        style: AppTextStyles.headlineMedium
                            .copyWith(color: AppColors.onSurface)),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: modeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isHunger ? 'Hunger' : 'Travel',
                        style: AppTextStyles.labelSmall.copyWith(color: modeColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Invite code ──
          Text('Invite Code',
              style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurface)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder, width: 1.5),
            ),
            child: Column(
              children: [
                // Code display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _group.inviteCode.split('').asMap().entries.map((e) {
                    return Container(
                      width: 40,
                      height: 48,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: modeBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          e.value,
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: modeColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _copyCode,
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy Code'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.onSurface,
                          side: const BorderSide(color: AppColors.cardBorder),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _shareWhatsApp,
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_amOwner) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _loadingCode ? null : _refreshCode,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_loadingCode)
                          const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          const Icon(Icons.refresh_rounded,
                              size: 14, color: AppColors.outline),
                        const SizedBox(width: 6),
                        Text('Generate new code',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.outline)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Members ──
          Row(
            children: [
              Text('Members',
                  style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurface)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_group.memberCount} / 10',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.outline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ..._group.members.map((m) => _MemberTile(member: m, isMe: m.userId == _myId)),

          const SizedBox(height: 32),

          // ── Start Session button ──────────────────────────────────────────
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: isHunger ? AppColors.greenGradient : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF9600), Color(0xFFFF5200)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SessionSetupScreen(
                      group: _group,
                      mode: isHunger ? 'hunger' : 'travel',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: Text(isHunger ? '🍽️' : '🌍',
                  style: const TextStyle(fontSize: 20)),
              label: Text(
                'Start ${isHunger ? 'Hunger' : 'Travel'} Session',
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Member tile ──────────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  final GroupMember member;
  final bool isMe;

  const _MemberTile({required this.member, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceContainerHigh,
            backgroundImage:
                member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
            child: member.avatarUrl == null
                ? Text(
                    member.displayName.isNotEmpty
                        ? member.displayName[0].toUpperCase()
                        : '?',
                    style: AppTextStyles.labelBold.copyWith(color: AppColors.outline),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Text(
              isMe ? '${member.displayName} (you)' : member.displayName,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurface,
                fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          // Role badge
          if (member.isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE8FDD8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Owner',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: const Color(0xFF1B6D01))),
            ),
        ],
      ),
    );
  }
}
