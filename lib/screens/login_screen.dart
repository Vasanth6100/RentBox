import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_logo.dart';
import '../services/api_service.dart';
import '../services/app_store.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';
import 'home_screen.dart';
import 'admin/admin_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final identifier = _emailPhoneController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email or mobile number.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email or mobile number.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your password.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (password.length < 4) {
      setState(() => _errorMessage = 'Password must be at least 4 characters.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 4 characters.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final user = await ApiService.instance.login(
        emailPhone: identifier,
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
            content: Text('Welcome back, ${user.name}! Logged in successfully.'),
            backgroundColor: const Color(0xFF005C42),
            duration: const Duration(seconds: 1),
          ),
        );

        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        final err = ApiService.instance.lastLoginError ?? 'Invalid email or password. Please check your credentials.';
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
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Connection error: $e'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // Central Logo
                    const RentBoxLogo(
                      size: 92,
                      badgeType: LogoBadgeType.lock,
                      isCircle: true,
                    ),
                    const SizedBox(height: 14),

                    // RentBox title
                    Text(
                      'RentBox',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF14241E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RENT MORE. SPEND\nLESS.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF005C42),
                        letterSpacing: 1.1,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Welcome back
                    Text(
                      'Welcome back',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF14231E),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Log in to rent or list items near you.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF657A70),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email or Mobile field
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Email or Mobile Number',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2C4339),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE5EEE8)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _emailPhoneController,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'name@example.com or 10-digit mobile',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF8EA399),
                            fontSize: 13.5,
                          ),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Icon(Icons.alternate_email_rounded, color: Color(0xFF6E867B), size: 20),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Password label row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Password',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2C4339),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF005C42),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE5EEE8)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF8EA399),
                            fontSize: 13.5,
                          ),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Icon(Icons.lock_outline_rounded, color: Color(0xFF6E867B), size: 20),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: const Color(0xFF7B9388),
                              size: 20,
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
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
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
                    ],

                    const SizedBox(height: 20),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF005C42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 1,
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
                                    'Login',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dedicated Secondary Admin Login Option
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                          );
                        },
                        icon: const Icon(Icons.shield_outlined, color: Color(0xFF005C42), size: 19),
                        label: Text(
                          'Admin Login',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF005C42),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFBCE0CC), width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Login with OTP
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4F0E8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF0D674B), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Login with OTP',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF163D2E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Or continue with divider
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Color(0xFFE0EBE4), thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or continue\nwith',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF7A9187),
                              height: 1.1,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: Color(0xFFE0EBE4), thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Continue with Google
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE2EBE5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildGoogleLogo(),
                          const SizedBox(width: 12),
                          Text(
                            'Continue with\nGoogle',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF20362C),
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Neighborhood Verified badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4EC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFD6EAE0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF6EE7B7),
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: Color(0xFF065F46),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Neighborhood Verified',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF102E22),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Renting safe, trusted items nearby',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: const Color(0xFF4F6E61),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Don't have an account? Create account
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            color: const Color(0xFF4C665C),
                          ),
                          children: const [
                            TextSpan(text: "Don't have an account?  "),
                            TextSpan(
                              text: 'Create\naccount',
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

  Widget _buildGoogleLogo() {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontWeight: FontWeight.bold,
          fontSize: 20,
          fontFamily: 'Roboto',
        ),
      ),
    );
  }
}
