import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/app_store.dart';
import '../../theme/app_theme.dart';

class AdminRentalsScreen extends StatelessWidget {
  const AdminRentalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM');
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        final rentals = AppStore.instance.allBookings;

        return Scaffold(
          backgroundColor: AppColors.mintBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Rental Transactions',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: rentals.length,
            itemBuilder: (context, i) {
              final booking = rentals[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE4EDE7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(booking.id, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5EE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(booking.paymentStatus, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(booking.listingTitle, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Renter: ${booking.renterName}  •  Owner: ${booking.ownerName}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('${dateFmt.format(booking.startDate)} - ${dateFmt.format(booking.endDate)} (${booking.durationDays} days) • Code: ${booking.pickupCode}', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF2C4A3E), fontWeight: FontWeight.w600)),
                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Security Deposit: ₹${booking.securityDeposit.toStringAsFixed(0)} (Escrow Held)', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary)),
                        Text('₹${booking.totalPayable.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
