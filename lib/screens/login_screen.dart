import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
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

  // ─── Google Sign-In ───────────────────────────────────────────────────────

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleLoading = true);
    final result = await _authService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _googleLoading = false);

    if (result.cancelled) return;
    if (!result.success) {
      _showError(result.errorMessage ?? 'Sign-in failed.');
    }
    // On success, main.dart's auth state listener will navigate automatically
  }

  // ─── Phone OTP ────────────────────────────────────────────────────────────

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _otpLoading = true);

    final rawPhone = _phoneController.text.trim();
    // Always send in E.164 format to Supabase
    final e164 = rawPhone.startsWith('+') ? rawPhone : '+91$rawPhone';

    final result = await _authService.sendOtp(e164);
    if (!mounted) return;
    setState(() => _otpLoading = false);

    if (!result.success) {
      _showError(result.errorMessage ?? 'Could not send OTP.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpScreen(phone: e164),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              _buildLogo(),
              const SizedBox(height: 40),
              _buildTagline(),
              const SizedBox(height: 48),
              _buildGoogleButton(),
              const SizedBox(height: 32),
              _buildFooterNote(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─── UI Widgets ───────────────────────────────────────────────────────────

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.greenGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.shuffle_rounded, color: Colors.white, size: 44),
        ),
        const SizedBox(height: 16),
        Text(
          'Shuffle',
          style: AppTextStyles.display.copyWith(
            color: AppColors.onSurface,
            letterSpacing: -1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTagline() {
    return Column(
      children: [
        Text(
          'Stop arguing.\nStart deciding.',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Swipe on restaurants & places with your crew.\nEveryone votes. One winner.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _googleLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: AppColors.surface,
        ),
        child: _googleLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google 'G' icon using coloured squares
                  _GoogleIcon(),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: AppTextStyles.button.copyWith(color: AppColors.onSurface),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.cardBorder, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or use your phone',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.outline),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.cardBorder, thickness: 1)),
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
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurface),
        decoration: InputDecoration(
          counterText: '',
          prefixIcon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Text(
              '+91',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          hintText: 'Mobile number',
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
            borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Enter your mobile number';
          if (value.trim().length != 10) return 'Enter a valid 10-digit number';
          return null;
        },
      ),
    );
  }

  Widget _buildSendOtpButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _otpLoading ? null : _handleSendOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryGreen.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _otpLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                'Send OTP',
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildFooterNote() {
    return Text(
      'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
      textAlign: TextAlign.center,
      style: AppTextStyles.labelSmall.copyWith(color: AppColors.outline),
    );
  }
}

// Simple Google 'G' logo using a custom painter — no asset needed
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 22),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Draw coloured arcs to approximate the G logo
    const sweepData = [
      (0.0, 90.0, Color(0xFF4285F4)),   // blue
      (90.0, 90.0, Color(0xFF34A853)),  // green
      (180.0, 90.0, Color(0xFFFBBC05)), // yellow
      (270.0, 90.0, Color(0xFFEA4335)), // red
    ];

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    for (final (start, sweep, color) in sweepData) {
      paint.color = color;
      canvas.drawArc(
        rect,
        start * (3.14159 / 180),
        sweep * (3.14159 / 180),
        true,
        paint,
      );
    }

    // White circle in the middle
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.55, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
