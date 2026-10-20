import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/dispute_model.dart';
import '../../services/app_store.dart';
import '../../theme/app_theme.dart';

class AdminDisputesScreen extends StatelessWidget {
  const AdminDisputesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        final disputes = AppStore.instance.allDisputes;

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
              'Disputes & Claims',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: disputes.length,
            itemBuilder: (context, i) {
              final d = disputes[i];
              final isOpen = d.status == DisputeStatus.open;

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
                        Text('${d.caseId} • Booking: ${d.bookingId}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isOpen ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isOpen ? 'Open Claim' : 'Resolved',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isOpen ? const Color(0xFF991B1B) : const Color(0xFF065F46),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(d.itemTitle, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text('Claimed by: ${d.renterName} vs ${d.ownerName}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAF9), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reason: ${d.reason}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text(d.description, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF4C6157))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Disputed Sum: ₹${d.amountInvolved.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFDC2626))),
                        if (isOpen)
                          ElevatedButton(
                            onPressed: () {
                              AppStore.instance.resolveDispute(d.id, 'Full deposit released to renter after video evidence check.');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Dispute resolved & closed.')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size(100, 34),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('Resolve Case', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                          )
                        else
                          Text('Resolution: ${d.resolution ?? "Completed"}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
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
