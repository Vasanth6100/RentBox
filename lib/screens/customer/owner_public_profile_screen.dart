import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/listing_model.dart';
import '../../services/app_store.dart';
import '../../widgets/app_image.dart';
import 'product_detail_screen.dart';

class OwnerPublicProfileScreen extends StatelessWidget {
  final String ownerId;
  final String ownerName;
  final String? ownerAvatarUrl;

  const OwnerPublicProfileScreen({
    super.key,
    required this.ownerId,
    required this.ownerName,
    this.ownerAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final allListings = AppStore.instance.activeListings;
    final ownerListings = allListings.where((l) => l.ownerId == ownerId).toList();
    final reviews = AppStore.instance.getReviewsForListing(ownerId); // reuse as owner reviews
    final avgRating = ownerListings.isNotEmpty
        ? ownerListings.map((l) => l.rating).reduce((a, b) => a + b) / ownerListings.length
        : 4.7;

    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, avgRating, ownerListings.length),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Row
                  Row(
                    children: [
                      _buildStatChip(Icons.inventory_2_outlined, '${ownerListings.length}', 'Listings'),
                      const SizedBox(width: 12),
                      _buildStatChip(Icons.star_rounded, avgRating.toStringAsFixed(1), 'Rating'),
                      const SizedBox(width: 12),
                      _buildStatChip(Icons.verified_user_outlined, 'KYC', 'Verified'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // About section
                  _buildSectionTitle('About the Owner'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE4EDE7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Mumbai, India',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Member since 2023',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'I rent out quality electronics and gadgets to nearby people at fair prices. '
                          'All items are well-maintained and insured. '
                          'I respond quickly and make handovers smooth and hassle-free.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Listings
                  _buildSectionTitle('Items for Rent (${ownerListings.length})'),
                  const SizedBox(height: 10),
                  if (ownerListings.isEmpty)
                    _buildEmpty('No active listings yet')
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.78,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: ownerListings.length,
                      itemBuilder: (context, i) => _buildListingCard(context, ownerListings[i]),
                    ),
                  const SizedBox(height: 24),

                  // Reviews
                  _buildSectionTitle('Reviews'),
                  const SizedBox(height: 10),
                  if (reviews.isEmpty)
                    _buildEmpty('No reviews yet')
                  else
                    ...reviews.take(3).map(
                          (r) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE4EDE7)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ...List.generate(
                                      5,
                                      (i) => Icon(
                                        Icons.star_rounded,
                                        size: 14,
                                        color: i < r.rating.round()
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFFD1D5DB),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      r.authorName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  r.comment,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, double rating, int itemCount) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF006B4F), Color(0xFF004D36)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: ClipOval(
                  child: AppImageWidget(
                    pathOrUrl: ownerAvatarUrl ?? 'assets/images/avatar.jpg',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                ownerName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, size: 13, color: Color(0xFF6EE7B7)),
                    const SizedBox(width: 4),
                    Text(
                      'Verified Owner',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE4EDE7)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildEmpty(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildListingCard(BuildContext context, ListingModel listing) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(listing: listing)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4EDE7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              child: AppImageWidget(
                pathOrUrl: listing.imageUrls.isNotEmpty ? listing.imageUrls.first : '',
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.priceDisplay,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
