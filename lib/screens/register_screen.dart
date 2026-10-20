import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_logo.dart';
import '../services/api_service.dart';
import '../services/app_store.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your full name.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final user = await ApiService.instance.register(
        name: name,
        email: email,
        phone: phone.replaceAll(' ', ''),
        password: password,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user != null) {
        AppStore.instance.setCurrentUser(user);
        await AppStore.instance.syncWithBackend();

        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Welcome to RentBox, ${user.name}! 🎉'),
            backgroundColor: const Color(0xFF005C42),
            duration: const Duration(seconds: 2),
          ),
        );

        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        final err = ApiService.instance.lastRegisterError ??
            'Registration failed. Please try again.';
        setState(() => _errorMessage = err);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection error: $e';
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
              onBack: () => Navigator.pop(context),
              onProfile: () {},
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    const SizedBox(height: 4),

                    // Logo Emblem with checkmark
                    const RentBoxLogo(
                      size: 78,
                      badgeType: LogoBadgeType.checkmark,
                      isCircle: true,
                    ),
                    const SizedBox(height: 12),

                    // Header title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Create account',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF14241E),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('✨', style: TextStyle(fontSize: 20)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Join RentBox to rent gear and earn from unused\nitems.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF657A70),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Community count badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7EFEA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.groups_outlined, size: 16, color: Color(0xFF264C3D)),
                          const SizedBox(width: 6),
                          Text(
                            '50,000+ local neighbors sharing',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF214436),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Large Form Container Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
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
                          // Full name
                          _buildFieldLabel('Full Name', rightHint: 'Real name helps'),
                          const SizedBox(height: 6),
                          _buildTextInput(
                            controller: _nameController,
                            icon: Icons.person_outline_rounded,
                            hint: 'Full Name',
                          ),
                          const SizedBox(height: 16),

                          // Email Address
                          _buildFieldLabel('Email Address'),
                          const SizedBox(height: 6),
                          _buildTextInput(
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            hint: 'name@example.com',
                          ),
                          const SizedBox(height: 16),

                          // Mobile Number
                          _buildFieldLabel('Mobile Number', rightHint: 'Instant SMS OTP'),
                          const SizedBox(height: 6),
                          Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF5F1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 12),
                                const Icon(Icons.smartphone_rounded, color: Color(0xFF6B8479), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'IN +91',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1D352B),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password
                          _buildFieldLabel('Password', rightHint: 'At least 8 characters'),
                          const SizedBox(height: 6),
                          Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF5F1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF6B8479), size: 18),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: const Color(0xFF6B8479),
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Password strength indicator
                          Row(
                            children: [
                              _buildStrengthBar(filled: true),
                              const SizedBox(width: 6),
                              _buildStrengthBar(filled: true),
                              const SizedBox(width: 6),
                              _buildStrengthBar(filled: true),
                              const SizedBox(width: 6),
                              _buildStrengthBar(filled: false),
                              const SizedBox(width: 10),
                              Text(
                                'Strong',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0D7854),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          // Inline error display
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFECEC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFCA5A5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFFB91C1C),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Create account button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF005C42),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Create account',
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
                          const SizedBox(height: 16),

                          // OR divider
                          Row(
                            children: [
                              const Expanded(child: Divider(color: Color(0xFFE2EBE5), thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'OR',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF7E968C),
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(color: Color(0xFFE2EBE5), thickness: 1)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Sign up with Google button
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F6F3),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: const Color(0xFFE2ECE6)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'G',
                                  style: TextStyle(
                                    color: Color(0xFF4285F4),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Sign up with\nGoogle',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E352B),
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Terms text
                    Text.rich(
                      TextSpan(
                        text: 'By continuing, you agree to RentBox ',
                        children: [
                          TextSpan(
                            text: 'Terms',
                            style: GoogleFonts.plusJakartaSans(
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF005C42),
                            ),
                          ),
                          const TextSpan(text: ' & '),
                          TextSpan(
                            text: 'Privacy\nPolicy.',
                            style: GoogleFonts.plusJakartaSans(
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF005C42),
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFF657E73),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Already have an account? Log in
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
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
                            TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Log in',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF005C42),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildFieldLabel(String label, {String? rightHint}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF284036),
          ),
        ),
        if (rightHint != null)
          Text(
            rightHint,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F7D56),
            ),
          ),
      ],
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF5F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF6B8479), size: 18),
          hintText: hint,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildStrengthBar({required bool filled}) {
    return Expanded(
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF006B4C) : const Color(0xFFD6E3DC),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
