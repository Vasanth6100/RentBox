import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../services/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_image.dart';
import 'review_dialog.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        final bookings = AppStore.instance.myCustomerBookings;
        final upcoming = bookings.where((b) => b.status == BookingStatus.upcoming).toList();
        final active = bookings.where((b) => b.status == BookingStatus.active).toList();
        final completed = bookings.where((b) => b.status == BookingStatus.completed || b.status == BookingStatus.cancelled).toList();

        return Scaffold(
          backgroundColor: AppColors.mintBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Rentals',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Manage reservations & pick-ups',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                Tab(text: 'Upcoming (${upcoming.length})'),
                Tab(text: 'Active (${active.length})'),
                Tab(text: 'Completed (${completed.length})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildBookingsList(context, upcoming, 'No upcoming rentals'),
              _buildBookingsList(context, active, 'No active rentals currently in hand'),
              _buildBookingsList(context, completed, 'No completed rentals history'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingsList(BuildContext context, List<BookingModel> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today_outlined, size: 54, color: Color(0xFFA5BCB0)),
              const SizedBox(height: 14),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Explore available gear near you to place a rental.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(18),
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(context, list[index]);
      },
    );
  }

  Widget _buildBookingCard(BuildContext context, BookingModel b) {
    final dateFmt = DateFormat('dd MMM');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4EDE7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Status badge & ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusPill(b.status),
              Text(
                b.id,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main info row
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: AppImageWidget(
                    pathOrUrl: b.listingImage,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.listingTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Owner: ${b.ownerName} • ${b.location}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dateFmt.format(b.startDate)} - ${dateFmt.format(b.endDate)} (${b.durationDays} days)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFFE6EEE8), height: 22),

          // Pricing & Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Paid',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '₹${b.totalPayable.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (b.status == BookingStatus.upcoming) ...[
                    OutlinedButton(
                      onPressed: () => _confirmCancelBooking(context, b),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size(0, 34),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 11.5)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _showPickupCodeModal(context, b),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        minimumSize: const Size(0, 34),
                      ),
                      child: const Text('View Code', style: TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ] else if (b.status == BookingStatus.active) ...[
                    ElevatedButton(
                      onPressed: () {
                        AppStore.instance.markBookingCompleted(b.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gear returned safely! Booking completed.')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        minimumSize: const Size(0, 34),
                      ),
                      child: const Text('Confirm Return', style: TextStyle(fontSize: 11.5, color: Colors.white)),
                    ),
                  ] else if (b.status == BookingStatus.completed && !b.isReviewed) ...[
                    ElevatedButton(
                      onPressed: () => ReviewDialog.show(context, b),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8F5EE),
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        minimumSize: const Size(0, 34),
                      ),
                      child: const Text('Rate Gear ★', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ),
                  ] else ...[
                    Text(
                      b.status == BookingStatus.cancelled ? 'Refunded' : 'Reviewed ★',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(BookingStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case BookingStatus.upcoming:
        bg = const Color(0xFFD6F3E3);
        fg = const Color(0xFF0D674A);
        label = 'Upcoming';
        break;
      case BookingStatus.active:
        bg = const Color(0xFFDCEEFE);
        fg = const Color(0xFF1D4ED8);
        label = 'Active (In Hand)';
        break;
      case BookingStatus.completed:
        bg = const Color(0xFFE6EFEB);
        fg = const Color(0xFF334B42);
        label = 'Completed';
        break;
      case BookingStatus.cancelled:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }

  void _showPickupCodeModal(BuildContext context, BookingModel b) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFD8E5DE), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 18),
            Text(
              'Handover Verification Code',
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Show this 6-digit alphanumeric code to owner ${b.ownerName} upon inspection.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EE),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: Text(
                b.pickupCode,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Location: ${b.location}',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _confirmCancelBooking(BuildContext context, BookingModel b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: Text('Are you sure you want to cancel booking for "${b.listingTitle}"? A 100% refund of ₹${b.totalPayable.toStringAsFixed(0)} will be credited back to your original payment method.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Booking')),
          TextButton(
            onPressed: () {
              AppStore.instance.cancelBooking(b.id);
              Navigator.pop(ctx);
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
