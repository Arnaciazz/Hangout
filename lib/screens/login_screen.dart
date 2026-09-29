import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/hangout_button.dart';
import '../widgets/hangout_logo.dart';
import '../widgets/hangout_motion.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _googleLoading = false;
  bool _otpLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleLoading = true);
    final result = await _authService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _googleLoading = false);
    if (result.cancelled) return;
    if (!result.success) {
      _showError(result.errorMessage ?? "That didn't work. Try again?");
    }
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _otpLoading = true);
    final rawPhone = _phoneController.text.trim();
    final e164 = rawPhone.startsWith('+') ? rawPhone : '+91$rawPhone';
    final result = await _authService.sendOtp(e164);
    if (!mounted) return;
    setState(() => _otpLoading = false);
    if (!result.success) {
      _showError(result.errorMessage ?? "We couldn't send that code.");
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OtpScreen(phone: e164)),
    );
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter, 56, AppSpacing.gutter, AppSpacing.x8),
          children: [
            const HangoutWordmark(height: 34),
            const SizedBox(height: AppSpacing.x10),
            Text('We should hang out sometime.', style: AppTextStyles.h1),
            const SizedBox(height: AppSpacing.x3),
            Text(
              'Swipe on places with your crew. Everyone votes, one spot wins.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.x10),
            _buildGoogleButton(),
            const SizedBox(height: AppSpacing.x5),
            _buildDivider(),
            const SizedBox(height: AppSpacing.x5),
            _buildPhoneForm(),
            const SizedBox(height: AppSpacing.x4),
            HangoutButton(
              label: 'Send code',
              size: HangoutButtonSize.lg,
              block: true,
              loading: _otpLoading,
              onPressed: _handleSendOtp,
            ),
            const SizedBox(height: AppSpacing.x8),
            _buildFooterNote(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return Pressable(
      onTap: _googleLoading ? null : _handleGoogleSignIn,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.pillAll,
          border: Border.all(color: AppColors.borderStrong),
        ),
        child: _googleLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _GoogleIcon(),
                  const SizedBox(width: AppSpacing.x3),
                  Text('Continue with Google',
                      style: AppTextStyles.button
                          .copyWith(color: AppColors.textStrong)),
                ],
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
          child: Text('or use your phone', style: AppTextStyles.caption),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildPhoneForm() {
    return Form(
      key: _formKey,
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 10,
        style: AppTextStyles.body.copyWith(color: AppColors.textStrong),
        decoration: InputDecoration(
          counterText: '',
          hintText: 'Mobile number',
          prefixIcon: Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 10, 15),
            child: Text('+91',
                style: AppTextStyles.bodyStrong.copyWith(color: AppColors.brand)),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Enter your mobile number';
          if (v.trim().length != 10) return "That's not a 10-digit number";
          return null;
        },
      ),
    );
  }

  Widget _buildFooterNote() {
    return Text(
      'By continuing you agree to our Terms of Service and Privacy Policy.',
      style: AppTextStyles.caption,
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(20, 20), painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    const sweeps = [
      (0.0, 90.0, Color(0xFF4285F4)),
      (90.0, 90.0, Color(0xFF34A853)),
      (180.0, 90.0, Color(0xFFFBBC05)),
      (270.0, 90.0, Color(0xFFEA4335)),
    ];
    final rect = Rect.fromCircle(center: center, radius: r);
    for (final (start, sweep, color) in sweeps) {
      paint.color = color;
      canvas.drawArc(
          rect, start * (3.14159 / 180), sweep * (3.14159 / 180), true, paint);
    }
    paint.color = Colors.white;
    canvas.drawCircle(center, r * 0.55, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
