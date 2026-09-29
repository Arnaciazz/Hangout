import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/hangout_button.dart';
import '../widgets/hangout_motion.dart';

class OtpScreen extends StatefulWidget {
  final String phone; // E.164, e.g. +919876543210

  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();

  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  final _keyNodes = List.generate(6, (_) => FocusNode());

  bool _verifying = false;
  bool _resending = false;
  int _resendCooldown = 30;
  Timer? _ticker;

  /// Drives a short horizontal shake when a code is rejected.
  late final AnimationController _shakeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    _startCooldown();
    for (final node in _focusNodes) {
      node.addListener(() => setState(() {}));
    }
  }

  void _startCooldown() {
    _ticker?.cancel();
    _resendCooldown = 30;
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    for (final f in _keyNodes) {
      f.dispose();
    }
    _ticker?.cancel();
    _shakeCtrl.dispose();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    setState(() {});
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_otp.length == 6) _verify();
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verify() async {
    if (_otp.length != 6 || _verifying) return;
    setState(() => _verifying = true);

    final result = await _authService.verifyOtp(widget.phone, _otp);
    if (!mounted) return;
    setState(() => _verifying = false);

    if (!result.success) {
      _shakeCtrl.forward(from: 0);
      HapticFeedback.heavyImpact();
      _showError(result.errorMessage ?? "That code didn't match.");
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      setState(() {});
    }
    // On success main.dart's auth listener navigates away on its own.
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0 || _resending) return;
    setState(() => _resending = true);

    final result = await _authService.sendOtp(widget.phone);
    if (!mounted) return;
    setState(() => _resending = false);

    if (!result.success) {
      _showError(result.errorMessage ?? "We couldn't resend that code.");
      return;
    }

    _startCooldown();
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code sent again'),
        backgroundColor: AppColors.accentFresh,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  String get _displayPhone {
    if (widget.phone.startsWith('+91') && widget.phone.length == 13) {
      final digits = widget.phone.substring(3);
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    return widget.phone;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(leading: const HangoutBackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.x4),
              Text('Enter the code', style: AppTextStyles.h1),
              const SizedBox(height: AppSpacing.x2),
              RichText(
                  text: TextSpan(
                    style: AppTextStyles.small,
                    children: [
                      const TextSpan(text: 'We texted a 6-digit code to '),
                      TextSpan(
                        text: _displayPhone,
                        style: AppTextStyles.smallStrong
                            .copyWith(color: AppColors.textStrong),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.x10),
              _buildOtpBoxes(),
              const SizedBox(height: AppSpacing.x8),
              HangoutButton(
                  label: 'Verify & continue',
                  size: HangoutButtonSize.lg,
                  block: true,
                  loading: _verifying,
                  onPressed: _otp.length == 6 ? _verify : null,
                ),
              const SizedBox(height: AppSpacing.x6),
              _buildResendRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBoxes() {
    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (context, child) {
        // Two decaying oscillations, so a wrong code reads as a head-shake.
        final t = _shakeCtrl.value;
        final dx = math.sin(t * math.pi * 4) * 10 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (i) {
          final focused = _focusNodes[i].hasFocus;
          final filled = _controllers[i].text.isNotEmpty;

          return AnimatedContainer(
            duration: AppMotion.base,
            curve: AppMotion.easeOut,
            width: 48,
            height: 60,
            decoration: BoxDecoration(
              color: filled ? AppColors.brandTint : AppColors.surface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(
                color: focused
                    ? AppColors.focusRing
                    : (filled ? AppColors.paprika200 : AppColors.border),
                width: 1.5,
              ),
              // The design system's focus treatment: a 4px brand-tint halo.
              boxShadow: focused
                  ? [
                      BoxShadow(
                        color: AppColors.brandTint,
                        blurRadius: 0,
                        spreadRadius: 4,
                      ),
                    ]
                  : AppShadows.sm,
            ),
            child: KeyboardListener(
              focusNode: _keyNodes[i],
              onKeyEvent: (event) => _onKeyEvent(i, event),
              child: TextFormField(
                controller: _controllers[i],
                focusNode: _focusNodes[i],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                showCursor: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyles.statNumber(24),
                decoration: const InputDecoration(
                  counterText: '',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => _onDigitChanged(i, v),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildResendRow() {
    final canResend = _resendCooldown <= 0 && !_resending;

    return Center(
      child: _resending
          ? const SizedBox(
              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : Pressable(
              onTap: canResend ? _resendOtp : null,
              scale: 0.96,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x2),
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.small,
                    children: [
                      const TextSpan(text: "Didn't get it? "),
                      TextSpan(
                        text: canResend
                            ? 'Send it again'
                            : 'Resend in ${_resendCooldown}s',
                        style: AppTextStyles.smallStrong.copyWith(
                          color: canResend ? AppColors.brand : AppColors.textFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
