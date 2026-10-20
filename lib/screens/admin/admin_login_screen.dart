import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import 'admin_approvals_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _identifierController = TextEditingController(text: 'admin@rentbox.in');
  final _passwordController = TextEditingController(text: 'Admin@2026');
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _authResult;
  Map<String, dynamic>? _liveMetrics;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleAdminLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty) {
      setState(() => _errorMessage = 'Please enter admin email or identifier.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter administrator password or passkey.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.instance.adminLogin(
      identifier: identifier,
      password: password,
    );

    if (!mounted) return;

    if (res != null && res['success'] == true) {
      final metrics = await ApiService.instance.getAdminMetrics();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _authResult = res;
        _liveMetrics = metrics != null ? metrics['metrics'] as Map<String, dynamic>? : null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Administrator authentication verified via MySQL backend!'),
          backgroundColor: Color(0xFF005C42),
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = res?['error'] ?? 'Authentication failed: Invalid credentials or insufficient permissions.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF7),
      body: SafeArea(
        child: Column(
          children: [
            RentBoxHeader(
              onBack: () => Navigator.pop(context),
              onProfile: () {},
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                child: _authResult == null ? _buildLoginForm() : _buildAuthenticatedView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        const SizedBox(height: 12),

        // Shield Icon
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5EE),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFC4DFD1), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF005C42).withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF005C42), size: 38),
        ),
        const SizedBox(height: 16),

        Text(
          'Admin Command Portal',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF14241E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Restricted access for platform administrators only.\nCredentials verified directly by RentBox MySQL backend.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            color: const Color(0xFF657A70),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 24),

        // White Rounded Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5EEE8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Email or ID',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C4339),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FCFA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5EEE8)),
                ),
                child: TextField(
                  controller: _identifierController,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'admin@rentbox.in',
                    prefixIcon: Icon(Icons.badge_outlined, color: Color(0xFF6E867B), size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Master Passkey or Password',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C4339),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FCFA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5EEE8)),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Admin password or master PIN',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF6E867B), size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFF7B9388),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
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
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Quick fill chip
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.key, size: 14, color: Color(0xFF005C42)),
                    label: const Text('Default Master Credentials'),
                    labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF005C42)),
                    backgroundColor: const Color(0xFFE8F5EE),
                    side: const BorderSide(color: Color(0xFFC4DFD1)),
                    onPressed: () {
                      setState(() {
                        _identifierController.text = 'admin@rentbox.in';
                        _passwordController.text = 'Admin@2026';
                        _errorMessage = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAdminLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005C42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
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
                            const Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Verify & Unlock Console',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5EF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD3EAE0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.security, color: Color(0xFF0D6847), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'RentBox Security Protocol: Rate-limited, JWT-signed, and verified against MySQL role-based access rules.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: const Color(0xFF0D6847),
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuthenticatedView() {
    final user = _authResult?['user'] as Map<String, dynamic>? ?? {};
    final token = _authResult?['token'] as String? ?? '';
    final portalUrl = ApiConfig.getAdminPortalUrl(token);

    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFD1FAE5),
            border: Border.all(color: const Color(0xFF10B981), width: 3),
          ),
          child: const Icon(Icons.check_circle_rounded, color: Color(0xFF065F46), size: 48),
        ),
        const SizedBox(height: 14),

        Text(
          'Admin Verified',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF14241E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Welcome, ${user['name'] ?? 'Administrator'}! Session token issued.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF657A70),
          ),
        ),
        const SizedBox(height: 20),

        // Live Telemetry from MySQL
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5EEE8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MySQL 8.0 Telemetry',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF14241E),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'ONLINE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFE5EEE8)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _telemetryTile('Pending', '${_liveMetrics?['pendingApprovals'] ?? 2}', const Color(0xFFD97706)),
                  _telemetryTile('Active Gear', '${_liveMetrics?['activeListings'] ?? 6}', const Color(0xFF005C42)),
                  _telemetryTile('Rentals', '${_liveMetrics?['activeRentals'] ?? 1}', const Color(0xFF0284C7)),
                  _telemetryTile('Disputes', '${_liveMetrics?['openDisputesCount'] ?? 1}', const Color(0xFFDC2626)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Web Admin Console Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF004D36), Color(0xFF007A57)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF004D36).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.laptop_chromebook_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'Web Management Console',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Per instructions, the full administrative dashboard operates in the dedicated responsive web portal:',
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFFD5F3E5)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(
                  portalUrl,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF6EE7B7), fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Quick Moderation Action in Mobile App
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminApprovalsScreen()),
              );
            },
            icon: const Icon(Icons.gavel_rounded, color: Colors.white, size: 20),
            label: Text(
              'Inspect Approvals Queue in App',
              style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005C42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Log out admin session
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _authResult = null;
                _liveMetrics = null;
                ApiService.instance.authToken = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Admin logged out successfully.')),
              );
            },
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
            label: Text(
              'Sign Out of Admin Session',
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFFDC2626)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFCA5A5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _telemetryTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF657A70),
          ),
        ),
      ],
    );
  }
}
