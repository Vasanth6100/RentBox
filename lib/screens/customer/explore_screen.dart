import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/listing_model.dart';
import '../../services/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_image.dart';
import 'product_detail_screen.dart';
import 'map_view_screen.dart';

class ExploreScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialQuery;

  const ExploreScreen({
    super.key,
    this.initialCategory,
    this.initialQuery,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late String _selectedCategory;
  final _searchController = TextEditingController();
  String _sortBy = 'Recommended'; // Recommended, Price: Low to High, Top Rated, Nearest
  final bool _verifiedOnly = false;
  double _maxPrice = 5000.0;

  final List<String> _categories = [
    'All',
    'Cameras',
    'Gaming',
    'Projectors',
    'Audio',
    'Tech',
    'Outdoor',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppStore.instance.syncWithBackend();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        final all = AppStore.instance.activeListings;
        final filtered = all.where((l) {
          // Category filter
          if (_selectedCategory != 'All' &&
              !l.category.toLowerCase().contains(_selectedCategory.toLowerCase())) {
            return false;
          }
          // Search query
          final q = _searchController.text.trim().toLowerCase();
          if (q.isNotEmpty &&
              !l.title.toLowerCase().contains(q) &&
              !l.brand.toLowerCase().contains(q) &&
              !l.location.toLowerCase().contains(q)) {
            return false;
          }
          // Verified owner filter
          if (_verifiedOnly && !l.isOwnerVerified) {
            return false;
          }
          // Max price filter
          if (l.pricePerDay > _maxPrice) {
            return false;
          }
          return true;
        }).toList();

        // Sorting
        if (_sortBy == 'Price: Low to High') {
          filtered.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
        } else if (_sortBy == 'Top Rated') {
          filtered.sort((a, b) => b.rating.compareTo(a.rating));
        } else if (_sortBy == 'Nearest') {
          filtered.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        }

        return Scaffold(
          backgroundColor: AppColors.mintBackground,
          appBar: _buildAppBar(context),
          body: Column(
            children: [
              _buildSearchBar(context),
              _buildCategoryChips(),
              _buildFilterSortBar(context, filtered.length),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => AppStore.instance.syncWithBackend(),
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: _buildEmptyState(),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _buildListingCard(context, filtered[index]);
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 44,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RentBoxLogo(size: 26, badgeType: LogoBadgeType.none, isCircle: false),
          const SizedBox(width: 8),
          Text(
            'Explore Rentals',
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
          tooltip: 'Map View',
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F2EA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.map_outlined, color: AppColors.primary, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Map',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapViewScreen()),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFEEF5F1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2EDE6)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search, color: Color(0xFF6B8479), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search cameras, gaming, projectors...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Color(0xFF6B8479)),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : const Color(0xFFF0F5F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : const Color(0xFFE2EBE5),
                    ),
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterSortBar(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$count items found near Mumbai',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (context) => [
              'Recommended',
              'Price: Low to High',
              'Top Rated',
              'Nearest',
            ].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2ECE6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sort_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    _sortBy,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(BuildContext context, ListingModel item) {
    final isFav = AppStore.instance.isFavorite(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5EDE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
                child: SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: AppImageWidget(
                    pathOrUrl: item.imageUrls.isNotEmpty ? item.imageUrls.first : '',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Rating Badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      Text(
                        '${item.rating} (${item.reviewsCount})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Verified Owner Pill
              if (item.isOwnerVerified)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF005C42).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Verified Owner',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Favorite Heart Button
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () => AppStore.instance.toggleFavorite(item.id),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                    child: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 18,
                      color: isFav ? const Color(0xFFEF4444) : const Color(0xFF435A50),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                        children: [
                          TextSpan(text: '₹${item.pricePerDay.toStringAsFixed(0)}'),
                          TextSpan(
                            text: '/day',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.near_me_outlined, size: 13, color: Color(0xFF759185)),
                    const SizedBox(width: 4),
                    Text(
                      '${item.distanceKm} km away • ${item.location}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Spec preview tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildSpecChip(item.condition),
                    _buildSpecChip('₹${item.securityDeposit.toStringAsFixed(0)} Deposit'),
                    if (item.isDeliveryAvailable) _buildSpecChip('Delivery Available'),
                  ],
                ),
                const SizedBox(height: 14),

                // Book Now Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(listing: item),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: Text(
                      'View Details & Book',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF28483C),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 60, color: Color(0xFFA5BCB0)),
            const SizedBox(height: 14),
            Text(
              'No rentals found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try clearing your search query or adjusting your category filters.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedCategory = 'All';
                  _maxPrice = 5000.0;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(140, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                ),
              ),
              child: const Text('Reset Filters', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
