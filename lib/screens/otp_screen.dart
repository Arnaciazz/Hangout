import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class OtpScreen extends StatefulWidget {
  final String phone; // E.164 format e.g. +919876543210

  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _authService = AuthService();

  // 6 individual digit controllers + focus nodes
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  bool _verifying = false;
  bool _resending = false;
  int _resendCooldown = 30; // seconds
  late final _ticker = Stream.periodic(const Duration(seconds: 1));
  late final _tickerSub = _ticker.listen((_) {
    if (_resendCooldown > 0) setState(() => _resendCooldown--);
  });

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _tickerSub.cancel();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  // Auto-advance focus to next box on digit entry
  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    // Auto-verify when all 6 digits entered
    if (_otp.length == 6) _verify();
  }

  // Handle backspace — go to previous box
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
      _showError(result.errorMessage ?? 'Invalid OTP. Please try again.');
      // Clear all boxes and refocus first
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
    }
    // Success: main.dart's auth listener navigates away automatically
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0 || _resending) return;
    setState(() => _resending = true);

    final result = await _authService.sendOtp(widget.phone);
    if (!mounted) return;
    setState(() {
      _resending = false;
      if (result.success) _resendCooldown = 30;
    });

    if (!result.success) {
      _showError(result.errorMessage ?? 'Could not resend OTP.');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent again!',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String get _displayPhone {
    // Show as +91 XXXXX XXXXX
    if (widget.phone.startsWith('+91') && widget.phone.length == 13) {
      final digits = widget.phone.substring(3);
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    return widget.phone;
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('Enter the code', style: AppTextStyles.headlineLarge.copyWith(color: AppColors.onSurface)),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.outline),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit code to '),
                    TextSpan(
                      text: _displayPhone,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              _buildOtpBoxes(),
              const SizedBox(height: 32),
              _buildVerifyButton(),
              const SizedBox(height: 24),
              _buildResendRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 48,
          height: 60,
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) => _onKeyEvent(i, event),
            child: TextFormField(
              controller: _controllers[i],
              focusNode: _focusNodes[i],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.headlineSmall.copyWith(color: AppColors.onSurface),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2.5),
                ),
              ),
              onChanged: (v) => _onDigitChanged(i, v),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (_verifying || _otp.length != 6) ? null : _verify,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryGreen.withOpacity(0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _verifying
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                'Verify & Continue',
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildResendRow() {
    final canResend = _resendCooldown == 0 && !_resending;
    return Center(
      child: _resending
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : GestureDetector(
              onTap: canResend ? _resendOtp : null,
              child: RichText(
                text: TextSpan(
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.outline),
                  children: [
                    const TextSpan(text: "Didn't receive it? "),
                    TextSpan(
                      text: canResend
                          ? 'Resend OTP'
                          : 'Resend in ${_resendCooldown}s',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: canResend ? AppColors.primaryGreen : AppColors.outline,
                        fontWeight: FontWeight.w700,
                        decoration: canResend ? TextDecoration.underline : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
