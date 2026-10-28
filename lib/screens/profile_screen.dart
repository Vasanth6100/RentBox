import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_image.dart';
import '../widgets/profile_details_sheet.dart';
import 'customer/bookings_screen.dart';
import 'owner/list_item_wizard_screen.dart';
import 'owner/my_listings_screen.dart';
import 'owner/owner_bookings_screen.dart';
import 'owner/earnings_payouts_screen.dart';
import 'login_screen.dart';
import '../services/app_update_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        final user = AppStore.instance.currentUser;
        final myListings = AppStore.instance.myListings;
        final myBookings = AppStore.instance.myCustomerBookings;
        final reservations = AppStore.instance.myOwnerBookings;
        final earnings = reservations.fold<double>(0, (sum, b) => sum + (b.rentalFee * 0.9));

        return Scaffold(
          backgroundColor: AppColors.mintBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: Text(
              'My Account',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Profile Header Card (Clickable to view details & change photo)
                InkWell(
                  onTap: () => showProfileDetailsSheet(context),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE4EDE7)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            ClipOval(
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary, width: 2),
                                ),
                                child: ClipOval(
                                  child: AppImageWidget(
                                    pathOrUrl: user.avatarUrl,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                            ),
                          ],
                        ),

                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.phone.isNotEmpty ? user.phone : 'Mumbai, Maharashtra',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified, size: 12, color: Color(0xFF065F46)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Verified Member • Mumbai Hub',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF065F46),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: Color(0xFF9AB2A6)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Quick Upload / Post Button (OLX Style)
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ListItemWizardScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF005C42), Color(0xFF004330)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF005C42).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Post / Rent Out Your Gear',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Upload cameras, PS5, projectors to earn extra income',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: const Color(0xFFD1EFE1),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Section: My Activity
                _buildSectionTitle('My Rentals & Gear'),
                const SizedBox(height: 10),
                _buildMenuTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'My Uploaded Gear',
                  subtitle: '${myListings.length} items listed by you (Active, Paused, Pending)',
                  badge: '${myListings.length}',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListingsScreen())),
                ),
                const SizedBox(height: 10),
                _buildMenuTile(
                  icon: Icons.shopping_bag_outlined,
                  title: 'My Bookings (Renting)',
                  subtitle: '${myBookings.length} items you rented from neighbors with pickup codes',
                  badge: '${myBookings.length}',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen())),
                ),
                const SizedBox(height: 10),
                _buildMenuTile(
                  icon: Icons.calendar_month_outlined,
                  title: 'Reservations Received',
                  subtitle: '${reservations.length} incoming requests to verify handover & return',
                  badge: '${reservations.length}',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerBookingsScreen())),
                ),
                const SizedBox(height: 10),
                _buildMenuTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Rental Earnings & Payouts',
                  subtitle: 'Net balance: ₹${earnings.toStringAsFixed(0)} • Direct bank transfer',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsPayoutsScreen())),
                ),

                const SizedBox(height: 24),

                // Section: Preferences & Safety
                _buildSectionTitle('Settings & Safety'),
                const SizedBox(height: 10),
                _buildMenuTile(
                  icon: Icons.shield_outlined,
                  title: 'Safe Deposit Guard & Escrow',
                  subtitle: 'How 100% protection and deposits work',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Deposits are held safely in escrow until gear is returned.')),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildMenuTile(
                  icon: Icons.help_outline,
                  title: 'Help & 24/7 Support',
                  subtitle: 'Instant chat with RentBox Mumbai Support',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Support helpline: support@rentbox.in')),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // App Version & Check Updates
                _buildMenuTile(
                  icon: Icons.system_update_rounded,
                  title: 'Check for Updates',
                  subtitle: 'Current Version: v${AppUpdateService.currentVersion}',
                  onTap: () => AppUpdateService.instance.checkForUpdate(context, manual: true),
                ),

                const SizedBox(height: 26),

                // Logout Button
                _buildLogoutButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4EDE7)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5EE),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF9FB5A9)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _showLogoutConfirmation,
        icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
        label: Text(
          'Log Out',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFDC2626),
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFEF2F2),
          side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Log Out',
              style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of RentBox?',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              AppStore.instance.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully.'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
