import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_image.dart';
import 'admin_approvals_screen.dart';
import 'admin_rentals_screen.dart';
import 'admin_kyc_screen.dart';
import 'admin_disputes_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        final pending = AppStore.instance.pendingApprovalListings;
        final allRentals = AppStore.instance.allBookings;
        final openDisputes = AppStore.instance.openDisputes;
        final grossRevenue = allRentals.fold<double>(0, (sum, b) => sum + b.totalPayable);

        return Scaffold(
          backgroundColor: AppColors.mintBackground,
          appBar: _buildAdminHeader(context),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSystemStatusStrip(),
                const SizedBox(height: 14),

                // Review Queue Banner
                _buildReviewQueueBanner(context, pending.length),
                const SizedBox(height: 16),

                // Metric Cards Grid
                _buildMetricCards(grossRevenue, allRentals.length, pending.length, openDisputes.length),
                const SizedBox(height: 20),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildQuickActions(context),
                const SizedBox(height: 20),

                // Live Activity
                Text(
                  'Live Platform Activity',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildLiveActivity(allRentals),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAdminHeader(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RentBoxLogo(size: 26, badgeType: LogoBadgeType.none, isCircle: false),
          const SizedBox(width: 8),
          Text(
            'RentBox Admin',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
          onPressed: () {},
        ),
        Container(
          margin: const EdgeInsets.only(right: 14),
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF1E2D27),
          ),
          child: const Center(
            child: Text('AD', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemStatusStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EDE7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981))),
              const SizedBox(width: 6),
              Text('Cluster Operational', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF173E2F))),
            ],
          ),
          Text('Mumbai Central Hub • v2.4.1', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildReviewQueueBanner(BuildContext context, int pendingCount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF006B4F),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006B4F).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'PRIORITY QUEUE',
                    style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Listing Review Queue',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                Text(
                  '$pendingCount gear submissions awaiting verification & bill check.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFFD3EFE1)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminApprovalsScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              'Inspect Queue',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards(double gross, int active, int pending, int disputes) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildMetricCard('Gross Rentals', '₹${(gross / 1000).toStringAsFixed(1)}K', '+18.4% today', Icons.currency_rupee, const Color(0xFF10B981)),
              const SizedBox(height: 10),
              _buildMetricCard('Pending Review', '$pending listings', 'Avg 18 mins SLA', Icons.rule_folder_outlined, const Color(0xFFF59E0B)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              _buildMetricCard('Total Rentals', '$active bookings', 'Active turnover', Icons.sync_alt, const Color(0xFF3B82F6)),
              const SizedBox(height: 10),
              _buildMetricCard('Open Cases', '$disputes tickets', 'Deposit disputes', Icons.gavel_outlined, const Color(0xFFEF4444)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String val, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EDE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(val, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'title': 'Approve Listings', 'icon': Icons.checklist_rtl_rounded, 'screen': const AdminApprovalsScreen()},
      {'title': 'KYC Verification', 'icon': Icons.verified_user_outlined, 'screen': const AdminKycScreen()},
      {'title': 'Manage Rentals', 'icon': Icons.inventory_2_outlined, 'screen': const AdminRentalsScreen()},
      {'title': 'Review Disputes', 'icon': Icons.shield_outlined, 'screen': const AdminDisputesScreen()},
    ];

    return Row(
      children: actions.map((a) {
        return Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => a['screen'] as Widget),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE4EDE7)),
              ),
              child: Column(
                children: [
                  Icon(a['icon'] as IconData, size: 22, color: AppColors.primary),
                  const SizedBox(height: 6),
                  Text(
                    a['title'] as String,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLiveActivity(List<dynamic> rentals) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EDE7)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rentals.length.clamp(0, 4),
        separatorBuilder: (_, _) => const Divider(color: Color(0xFFEBF1ED), height: 1),
        itemBuilder: (context, i) {
          final b = rentals[i];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AppImageWidget(pathOrUrl: b.listingImage as String, width: 44, height: 44, fit: BoxFit.cover),
            ),
            title: Text(b.listingTitle as String, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Text('Renter: ${b.renterName} • ${b.location}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary)),
            trailing: Text('₹${b.totalPayable.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
          );
        },
      ),
    );
  }
}
