import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/listing_model.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_image.dart';
import '../widgets/profile_details_sheet.dart';
import 'profile_screen.dart';
import '../services/app_store.dart';
import 'customer/explore_screen.dart';
import 'customer/bookings_screen.dart';
import 'customer/product_detail_screen.dart';
import 'customer/map_view_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'owner/list_item_wizard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  String _selectedCategory = 'All';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'emoji': ''},
    {'name': 'Cameras', 'emoji': '📷'},
    {'name': 'Gaming', 'emoji': '🎮'},
    {'name': 'Projectors', 'emoji': '📽️'},
    {'name': 'Audio', 'emoji': '🔊'},
  ];

  @override
  void initState() {
    super.initState();
    AppStore.instance.syncWithBackend();
  }

  final List<Map<String, dynamic>> _popularItems = [
    {
      'title': 'Sony Alpha Camera',
      'location': '2 km away • Bhiwandi',
      'price': '₹700',
      'rating': '4.8',
      'imageUrl': 'assets/images/camera.jpg',
      'isFavorite': false,
      'color': const Color(0xFF1A3A5C),
      'icon': Icons.camera_alt_rounded,
    },
    {
      'title': 'PS5 Console',
      'location': '3.5 km away • Thane',
      'price': '₹900',
      'rating': '4.9',
      'imageUrl': 'assets/images/ps5.jpg',
      'isFavorite': true,
      'color': const Color(0xFF2D1B4E),
      'icon': Icons.sports_esports_rounded,
    },
  ];

  final List<Map<String, dynamic>> _trendingItems = [
    {
      'title': 'Epson Projector',
      'location': 'Mumbai',
      'price': '₹500',
      'rating': '4.7',
      'imageUrl': 'assets/images/projector.jpg',
      'isFavorite': false,
      'color': const Color(0xFF1A3D2B),
      'icon': Icons.videocam_rounded,
    },
    {
      'title': 'JBL Party Speaker',
      'location': 'Navi Mumbai',
      'price': '₹800',
      'rating': '4.9',
      'imageUrl': 'assets/images/speaker.jpg',
      'isFavorite': false,
      'color': const Color(0xFF3D1A1A),
      'icon': Icons.speaker_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        final allActive = AppStore.instance.activeListings.isNotEmpty
            ? AppStore.instance.activeListings
            : AppStore.instance.allListings;

        List<ListingModel> filteredListings = allActive;
        if (_selectedCategory != 'All') {
          filteredListings = allActive
              .where((l) => l.category.toLowerCase().contains(_selectedCategory.toLowerCase()))
              .toList();
        }

        final popularListings = filteredListings.isNotEmpty
            ? filteredListings.take(2).toList()
            : allActive.take(2).toList();

        final trendingListings = filteredListings.length > 2
            ? filteredListings.skip(2).take(2).toList()
            : (allActive.length > 2 ? allActive.skip(2).take(2).toList() : allActive.take(2).toList());

        return Scaffold(
          backgroundColor: const Color(0xFFF6FAF7),
          body: SafeArea(
            child: Column(
              children: [
                _buildTopAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        _buildGreetingSection(),
                        const SizedBox(height: 16),
                        _buildSearchBar(),
                        const SizedBox(height: 16),
                        _buildCategoriesList(),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          title: 'Popular near you',
                          onSeeAll: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreScreen()));
                          },
                        ),
                        const SizedBox(height: 14),
                        if (popularListings.isEmpty)
                          ..._popularItems.map((item) => _buildPopularCard(item))
                        else
                          ...popularListings.map((listing) => _buildPopularListingCard(listing)),
                        const SizedBox(height: 14),
                        _buildSharingPromoBanner(),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          title: 'Trending',
                          onSeeAll: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreScreen()));
                          },
                        ),
                        const SizedBox(height: 14),
                        if (trendingListings.isEmpty)
                          _buildTrendingList()
                        else
                          _buildDynamicTrendingList(trendingListings),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          const RentBoxLogo(
            size: 32,
            badgeType: LogoBadgeType.none,
            isCircle: false,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'RentBox',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF13221C),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MapViewScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3EDE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, size: 10, color: Color(0xFF0F7A56)),
                          const SizedBox(width: 3),
                          Text(
                            'Mumbai 🗺️',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF264337),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Home Explore',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF758F83),
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Admin Portal',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
            },
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE8F5EE),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF005C42), size: 17),
            ),
          ),
          const SizedBox(width: 2),
          IconButton(
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreScreen()));
            },
            icon: const Icon(Icons.search, color: Color(0xFF334B41), size: 21),
          ),
          const SizedBox(width: 4),
          ListenableBuilder(
            listenable: AppStore.instance,
            builder: (context, _) {
              return GestureDetector(
                onTap: () => showProfileDetailsSheet(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD3E7DC), width: 1.5),
                  ),
                  child: ClipOval(
                    child: AppImageWidget(
                      pathOrUrl: AppStore.instance.currentUser.avatarUrl,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),

        ],
      ),
    );
  }

  Widget _buildGreetingSection() {
    final userName = AppStore.instance.currentUser.name.split(' ').first;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Hi, $userName',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF13231D),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('👋', style: TextStyle(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              'What would you like to rent?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF678175),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE2EFE7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 13, color: Color(0xFF0F7A56)),
              const SizedBox(width: 4),
              Text(
                'Mumbai',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF234437),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE4EDE7)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Icon(Icons.search, color: Color(0xFF759184), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Search rentals...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      color: const Color(0xFF88A196),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(5),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF5F1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Color(0xFF385549), size: 18),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat['name'];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = cat['name'] as String;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E2D27) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : const Color(0xFFE2EBE5),
                  ),
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      cat['name'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : const Color(0xFF263C32),
                      ),
                    ),
                    if ((cat['emoji'] as String).isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(cat['emoji'] as String, style: const TextStyle(fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required VoidCallback onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF14241E),
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            'See all',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF005C42),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPopularListingCard(ListingModel listing) {
    final isFav = AppStore.instance.isFavorite(listing.id);
    final imgUrl = listing.imageUrls.isNotEmpty ? listing.imageUrls.first : 'assets/images/camera.jpg';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(listing: listing)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFE4EDE7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image container with overlays
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: AppImageWidget(
                      pathOrUrl: imgUrl,
                      fit: BoxFit.cover,
                      height: 180,
                      width: double.infinity,
                    ),
                  ),
                ),

                // Star Rating badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 3),
                        Text(
                          listing.rating.toStringAsFixed(1),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF14241E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Heart Button
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => AppStore.instance.toggleFavorite(listing.id),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.92),
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

            // Bottom card text & price
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF13221C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.near_me_outlined, size: 13, color: Color(0xFF759185)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${listing.distanceKm.toStringAsFixed(1)} km away • ${listing.location}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: const Color(0xFF678276),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF005C42),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                      children: [
                        TextSpan(text: '₹${listing.pricePerDay.toStringAsFixed(0)}'),
                        TextSpan(
                          text: '/day',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF678276),
                          ),
                        ),
                      ],
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

  Widget _buildPopularCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        final listings = AppStore.instance.allListings;
        final listing = listings.isNotEmpty ? listings.first : null;
        if (listing != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetailScreen(listing: listing)),
          );
        }
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE4EDE7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image container with overlays
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: AppImageWidget(
                    pathOrUrl: item['imageUrl'] as String,
                    fit: BoxFit.cover,
                    height: 180,
                    width: double.infinity,
                  ),
                ),
              ),

              // Star Rating badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      Text(
                        item['rating'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF14241E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Heart Button
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                  child: Icon(
                    (item['isFavorite'] as bool) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 18,
                    color: (item['isFavorite'] as bool) ? const Color(0xFFEF4444) : const Color(0xFF435A50),
                  ),
                ),
              ),
            ],
          ),

          // Bottom card text & price
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF13221C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.near_me_outlined, size: 13, color: Color(0xFF759185)),
                        const SizedBox(width: 4),
                        Text(
                          item['location'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: const Color(0xFF678276),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF005C42),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                    children: [
                      TextSpan(text: item['price'] as String),
                      TextSpan(
                        text: '/day',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF678276),
                        ),
                      ),
                    ],
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

  Widget _buildSharingPromoBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFD6F3E3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFBCE8D0).withValues(alpha: 0.6),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NEIGHBORHOOD SHARING',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF007553),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Have something unused?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0D251D),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Earn up to ₹15,000/mo by listing items.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF436054),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005C42),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'List an item',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicTrendingList(List<ListingModel> items) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(
      children: items.map((listing) {
        final isFav = AppStore.instance.isFavorite(listing.id);
        final imgUrl = listing.imageUrls.isNotEmpty ? listing.imageUrls.first : 'assets/images/projector.jpg';

        return Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductDetailScreen(listing: listing)),
              );
            },
            child: Container(
              margin: EdgeInsets.only(right: listing == items.first && items.length > 1 ? 10 : 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE4EDE7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
                        child: SizedBox(
                          height: 120,
                          width: double.infinity,
                          child: AppImageWidget(
                            pathOrUrl: imgUrl,
                            fit: BoxFit.cover,
                            height: 120,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 2),
                              Text(
                                listing.rating.toStringAsFixed(1),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF14241E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => AppStore.instance.toggleFavorite(listing.id),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            child: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 15,
                              color: isFav ? const Color(0xFFEF4444) : const Color(0xFF435A50),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF14231E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF005C42),
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                            children: [
                              TextSpan(text: '₹${listing.pricePerDay.toStringAsFixed(0)}'),
                              TextSpan(
                                text: '/day',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF678276),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrendingList() {
    return Row(
      children: _trendingItems.map((item) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: item == _trendingItems.first ? 10 : 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE4EDE7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
                      child: SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: AppImageWidget(
                          pathOrUrl: item['imageUrl'] as String,
                          fit: BoxFit.cover,
                          height: 120,
                          width: double.infinity,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 2),
                            Text(
                              item['rating'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF14241E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          size: 15,
                          color: Color(0xFF435A50),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF14231E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF005C42),
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                          children: [
                            TextSpan(text: item['price'] as String),
                            TextSpan(
                              text: '/day',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF678276),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['location'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: const Color(0xFF758F83),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFE4EDE7), width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.explore_outlined, 'Explore'),
              // Floating Center + Button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ListItemWizardScreen()),
                  );
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF005C42),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x33005C42),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 26),
                ),
              ),
              _buildNavItem(2, Icons.calendar_today_outlined, 'Bookings'),
              _buildNavItem(3, Icons.person_outline_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          setState(() {
            _currentNavIndex = 0;
          });
        } else if (index == 1) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreScreen()));
        } else if (index == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen()));
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        }
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? const Color(0xFF005C42) : const Color(0xFF7B9588),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF005C42) : const Color(0xFF7B9588),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
