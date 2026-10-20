import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/booking_model.dart';
import '../../services/app_store.dart';
import '../../theme/app_theme.dart';

class ReviewDialog extends StatefulWidget {
  final BookingModel booking;

  const ReviewDialog({super.key, required this.booking});

  static void show(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (_) => ReviewDialog(booking: booking),
    );
  }

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  double _rating = 5.0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Rate Your Rental Experience',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.booking.listingTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starVal = index + 1.0;
              return IconButton(
                onPressed: () => setState(() => _rating = starVal),
                icon: Icon(
                  starVal <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: const Color(0xFFF59E0B),
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 3,
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Describe equipment quality, battery life, and handover ease...',
              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_commentController.text.trim().isEmpty) {
              _commentController.text = 'Great gear in pristine condition! Highly recommend.';
            }
            AppStore.instance.addReview(
              bookingId: widget.booking.id,
              listingId: widget.booking.listingId,
              rating: _rating,
              comment: _commentController.text.trim(),
            );
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Thank you! Review published.')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(100, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('Submit Review', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
