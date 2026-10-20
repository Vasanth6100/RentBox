import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/listing_model.dart';
import '../../services/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_image.dart';
import 'checkout_screen.dart';
import 'chat_screen.dart';
import 'owner_public_profile_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ListingModel listing;

  const ProductDetailScreen({
    super.key,
    required this.listing,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final item = widget.listing;

    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        final isFav = AppStore.instance.isFavorite(item.id);
        final reviews = AppStore.instance.getReviewsForListing(item.id);

        return Scaffold(
          backgroundColor: AppColors.mintBackground,
          appBar: _buildAppBar(context, item, isFav),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGallery(item),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Best Rate & Verification Tag
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0EFE6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_user_rounded, size: 12, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Inspected & Verified Gear',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2EBE5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 3),
                                Text(
                                  '${item.rating} (${item.reviewsCount} reviews)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Title & Location
                      Text(
                        item.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.near_me_outlined, size: 14, color: Color(0xFF6B877B)),
                          const SizedBox(width: 4),
                          Text(
                            '${item.distanceKm} km away • ${item.location}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Owner Card
                      _buildOwnerCard(context, item),
                      const SizedBox(height: 20),

                      // Specifications Grid
                      Text(
                        'Specifications',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildSpecGrid(item),
                      const SizedBox(height: 20),

                      // Description
                      Text(
                        'About this item',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          color: const Color(0xFF384D44),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // What's in the box
                      Text(
                        "What's in the box",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: item.includedItems.map((boxItem) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE3EDE7)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline, size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  boxItem,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Security Deposit & Delivery Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F4EE),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFD6EAE0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '100% Refundable Security Deposit: ₹${item.securityDeposit.toStringAsFixed(0)}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Returned immediately upon gear check and safe return.',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Color(0xFFD6E9DF), height: 20),
                            Row(
                              children: [
                                const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.isDeliveryAvailable
                                        ? 'Doorstep Delivery Available (₹${item.deliveryCharge.toStringAsFixed(0)}) or Free Self-Pickup'
                                        : 'Free Self-Pickup Only from ${item.location}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Reviews section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reviews (${reviews.length})',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '★ ${item.rating}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (reviews.isEmpty)
                        Text(
                          'No written reviews yet for this listing.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        ...reviews.map((rev) => _buildReviewItem(rev)),
                      const SizedBox(height: 90), // Spacing for sticky footer
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomSheet: _buildStickyFooter(context, item),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ListingModel item, bool isFav) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RentBoxLogo(size: 26, badgeType: LogoBadgeType.none, isCircle: false),
          const SizedBox(width: 8),
          Text(
            'Item Details',
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
          icon: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFav ? const Color(0xFFEF4444) : AppColors.textPrimary,
          ),
          onPressed: () => AppStore.instance.toggleFavorite(item.id),
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Listing link copied to clipboard!')),
            );
          },
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildGallery(ListingModel item) {
    return Stack(
      children: [
        SizedBox(
          height: 280,
          width: double.infinity,
          child: PageView.builder(
            itemCount: item.imageUrls.length,
            onPageChanged: (i) => setState(() => _currentImageIndex = i),
            itemBuilder: (context, index) {
              return AppImageWidget(
                pathOrUrl: item.imageUrls[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: 280,
              );
            },
          ),
        ),
        Positioned(
          bottom: 12,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${_currentImageIndex + 1} / ${item.imageUrls.length}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerCard(BuildContext context, ListingModel item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EDE7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OwnerPublicProfileScreen(
                    ownerId: item.ownerId,
                    ownerName: item.ownerName,
                    ownerAvatarUrl: item.ownerAvatar,
                  ),
                ),
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD3E7DC), width: 1.5),
                image: DecorationImage(
                  image: getAppImageProvider(item.ownerAvatar),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OwnerPublicProfileScreen(
                      ownerId: item.ownerId,
                      ownerName: item.ownerName,
                      ownerAvatarUrl: item.ownerAvatar,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.ownerName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.check_circle, size: 14, color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.ownerRating}★ • ${item.ownerResponseTime}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final conv = AppStore.instance.getOrCreateConversation(
                listingId: item.id,
                listingTitle: item.title,
                otherUserId: item.ownerId,
                otherUserName: item.ownerName,
                otherUserAvatar: item.ownerAvatar,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(conversation: conv),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8F5EE),
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
            label: Text(
              'Chat',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecGrid(ListingModel item) {
    final specList = [
      {'label': 'Brand', 'val': item.brand},
      {'label': 'Model', 'val': item.modelName},
      {'label': 'Condition', 'val': item.condition},
      {'label': 'Deposit', 'val': '₹${item.securityDeposit.toStringAsFixed(0)}'},
      ...item.specifications.entries.map((e) => {'label': e.key, 'val': e.value}),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: specList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 68,
      ),
      itemBuilder: (context, index) {
        final spec = specList[index];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4EDE7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                spec['label']!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                spec['val']!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewItem(dynamic rev) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
              CircleAvatar(
                radius: 14,
                backgroundImage: getAppImageProvider(rev.authorAvatar as String),
              ),
              const SizedBox(width: 8),
              Text(
                rev.authorName as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 2),
                  Text(
                    '${rev.rating}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            rev.comment as String,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF4C6157),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyFooter(BuildContext context, ListingModel item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFFE4EDE7), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Rate',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                    children: [
                      TextSpan(text: '₹${item.pricePerDay.toStringAsFixed(0)}'),
                      TextSpan(
                        text: '/day',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckoutScreen(listing: item),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Rent Now',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
