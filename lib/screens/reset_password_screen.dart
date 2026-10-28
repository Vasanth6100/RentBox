import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_logo.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  bool _isEmailSelected = true;
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isResetting = false;
  bool _codeSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    final value = _isEmailSelected
        ? _emailController.text.trim()
        : _phoneController.text.trim();

    if (value.isEmpty) {
      setState(() => _errorMessage = 'Please enter your ${_isEmailSelected ? 'email address' : 'mobile number'}.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.instance.requestPasswordReset(
        emailOrPhone: value,
        isEmail: _isEmailSelected,
      );

      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          _codeSent = true;
          _isLoading = false;
          _errorMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Reset code sent! Check your ${_isEmailSelected ? 'inbox' : 'SMS'}.'),
            backgroundColor: const Color(0xFF005C42),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['error'] ?? 'Account not found. Please check your details.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not connect to server. Please try again.';
      });
    }
  }

  Future<void> _handleVerifyAndReset() async {
    final value = _isEmailSelected
        ? _emailController.text.trim()
        : _phoneController.text.trim();
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter the 6-digit verification code.');
      return;
    }
    if (newPassword.length < 6) {
      setState(() => _errorMessage = 'New password must be at least 6 characters.');
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isResetting = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.instance.resetPassword(
        emailOrPhone: value,
        isEmail: _isEmailSelected,
        code: code,
        newPassword: newPassword,
      );

      if (!mounted) return;
      setState(() => _isResetting = false);

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Password reset successfully! Please log in.'),
            backgroundColor: const Color(0xFF005C42),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        setState(() {
          _errorMessage = res['error'] ?? 'Invalid verification code. Please check and try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResetting = false;
        _errorMessage = 'Could not connect to server. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      body: SafeArea(
        child: Column(
          children: [
            RentBoxHeader(
              showProfile: false,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  children: [
                    const SizedBox(height: 6),

                    // Central Logo
                    const RentBoxLogo(
                      size: 82,
                      badgeType: LogoBadgeType.checkmark,
                      isCircle: true,
                    ),
                    const SizedBox(height: 16),

                    // ACCOUNT RECOVERY badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2EFE7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ACCOUNT RECOVERY',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF335345),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Heading
                    Text(
                      _codeSent ? 'Verify & Reset' : 'Reset your password',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF13221C),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _codeSent
                          ? 'Enter the 6-digit verification code and choose your new password.'
                          : 'Enter your registered details to receive a 6-\ndigit verification code.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: const Color(0xFF5D766C),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form Container Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE6F0EA)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!_codeSent) ...[
                            // Tab toggle (Email / SMS OTP)
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF5F1),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _isEmailSelected = true),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: _isEmailSelected ? const Color(0xFF172420) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        alignment: Alignment.center,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.alternate_email_rounded,
                                              size: 16,
                                              color: _isEmailSelected ? Colors.white : const Color(0xFF678175),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Email',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: _isEmailSelected ? Colors.white : const Color(0xFF334B40),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _isEmailSelected = false),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: !_isEmailSelected ? const Color(0xFF172420) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        alignment: Alignment.center,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.smartphone_rounded,
                                              size: 16,
                                              color: !_isEmailSelected ? Colors.white : const Color(0xFF678175),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'SMS\nOTP',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: !_isEmailSelected ? Colors.white : const Color(0xFF334B40),
                                                height: 1.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Field Label
                            Text(
                              _isEmailSelected ? 'Registered Email Address' : 'Registered Mobile Number',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF284036),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Input
                            Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF5F1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: TextField(
                                controller: _isEmailSelected ? _emailController : _phoneController,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    _isEmailSelected ? Icons.email_outlined : Icons.phone_android_rounded,
                                    color: const Color(0xFF6B8479),
                                    size: 18,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Secondary Switch Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isEmailSelected = !_isEmailSelected;
                                  });
                                },
                                child: Text(
                                  _isEmailSelected ? 'Or use Mobile Number\n(+91)' : 'Or use Email Address',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF005C42),
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Error message
                            if (_errorMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    color: const Color(0xFF991B1B),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Send Reset Code Button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSendCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF005C42),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Send Reset Code',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                        ],
                                      ),
                              ),
                            ),
                          ] else ...[
                            // Step 2: Verification Code & New Password
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5EE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.mark_email_read_rounded, size: 16, color: Color(0xFF005C42)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Code sent to ${_isEmailSelected ? _emailController.text : _phoneController.text}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF005C42),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() => _codeSent = false),
                                    child: Text(
                                      'Change',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF005C42),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Verification Code Field
                            Text(
                              '6-Digit Verification Code',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF284036),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF5F1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: TextField(
                                controller: _codeController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 4,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: const InputDecoration(
                                  counterText: '',
                                  hintText: '000000',
                                  prefixIcon: Icon(Icons.lock_clock_outlined, color: Color(0xFF6B8479), size: 18),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // New Password Field
                            Text(
                              'New Password',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF284036),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF5F1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: TextField(
                                controller: _newPasswordController,
                                obscureText: _obscureNewPassword,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6B8479), size: 18),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: const Color(0xFF6B8479),
                                      size: 18,
                                    ),
                                    onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Confirm Password Field
                            Text(
                              'Confirm New Password',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF284036),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF5F1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: TextField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.lock_reset, color: Color(0xFF6B8479), size: 18),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: const Color(0xFF6B8479),
                                      size: 18,
                                    ),
                                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Error message
                            if (_errorMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    color: const Color(0xFF991B1B),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Reset Password Button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isResetting ? null : _handleVerifyAndReset,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF005C42),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: _isResetting
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Verify & Reset Password',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Resend Code link
                            Center(
                              child: TextButton(
                                onPressed: _isLoading ? null : _handleSendCode,
                                child: Text(
                                  'Resend Verification Code',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF005C42),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),

                          // Security Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF5F1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.shield_rounded,
                                  color: Color(0xFF006B4C),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Protected by RentBox 256-bit encryption',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1E352B),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Never share your OTP with anyone. RentBox executives will never ask for verification codes.',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          color: const Color(0xFF5A7569),
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Remember password? Log in >
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF4C665C),
                          ),
                          children: const [
                            TextSpan(text: 'Remember\npassword?  '),
                            TextSpan(
                              text: 'Log in >',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF005C42),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Footer branding
                    Text(
                      'RentBox • Rent More. Spend\nLess.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7A9488),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
