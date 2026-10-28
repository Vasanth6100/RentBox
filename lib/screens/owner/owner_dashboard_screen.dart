import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/app_store.dart';
import '../../theme/app_theme.dart';
import 'list_item_wizard_screen.dart';
import 'my_listings_screen.dart';
import 'owner_bookings_screen.dart';
import 'earnings_payouts_screen.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        final listings = AppStore.instance.myListings;
        final bookings = AppStore.instance.myOwnerBookings;
        final earnings = bookings.fold<double>(0, (sum, b) => sum + (b.rentalFee * 0.9)); // 90% to owner

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
              'Owner Partner Hub',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Earnings Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF006B4F), Color(0xFF004D36)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Net Earnings', style: GoogleFonts.plusJakartaSans(color: const Color(0xFFD3EFE1), fontSize: 13, fontWeight: FontWeight.w600)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                            child: const Text('Direct Bank Payout', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '₹${earnings.toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsPayoutsScreen()));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: const Text('View Payouts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Fast Stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('Active Listings', '${listings.length}', Icons.inventory_2_outlined),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard('Bookings Received', '${bookings.length}', Icons.shopping_bag_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Management Hub Actions
                Text('Manage Equipment', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                _buildActionTile(
                  icon: Icons.add_circle_outline,
                  title: 'List New Gear',
                  subtitle: 'Add cameras, gaming consoles or tech to earn up to ₹15,000/mo',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ListItemWizardScreen())),
                ),
                const SizedBox(height: 10),
                _buildActionTile(
                  icon: Icons.format_list_bulleted,
                  title: 'My Listings (${listings.length})',
                  subtitle: 'Manage your active and paused rental gear',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListingsScreen())),
                ),
                const SizedBox(height: 10),
                _buildActionTile(
                  icon: Icons.calendar_month_outlined,
                  title: 'Reservations & Handover',
                  subtitle: 'Verify renter pickup codes & confirm gear return',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerBookingsScreen())),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EDE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 8),
          Text(val, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4EDE7)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE8F5EE)),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF9FB5A9)),
          ],
        ),
      ),
    );
  }
}
