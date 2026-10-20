import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/app_store.dart';
import '../../models/listing_model.dart';
import '../../widgets/app_image.dart';
import 'product_detail_screen.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> with SingleTickerProviderStateMixin {
  final TransformationController _transformController = TransformationController();
  ListingModel? _selectedListing;
  String _selectedNeighborhood = 'All';

  // Map canvas dimensions
  static const double _mapWidth = 1400.0;
  static const double _mapHeight = 1400.0;

  // Neighborhood centers on our 1400x1400 Mumbai coordinate space
  final Map<String, Offset> _neighborhoodCoords = {
    'Bhiwandi': const Offset(1050, 240),
    'Powai': const Offset(820, 480),
    'Andheri': const Offset(460, 500),
    'Juhu': const Offset(360, 620),
    'Bandra': const Offset(420, 780),
    'BKC': const Offset(620, 810),
    'Dadar': const Offset(480, 960),
    'Colaba': const Offset(440, 1220),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnOffset(const Offset(520, 680), scale: 1.0);
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _centerOnOffset(Offset target, {double scale = 1.25}) {
    final screenSize = MediaQuery.of(context).size;
    final double tx = -target.dx * scale + screenSize.width / 2;
    final double ty = -target.dy * scale + screenSize.height / 2;

    _transformController.value = Matrix4.identity()
      ..translateByDouble(tx, ty, 0.0, 1.0)
      ..scaleByDouble(scale, scale, 1.0, 1.0);
  }

  void _zoom(double delta) {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final newScale = (currentScale + delta).clamp(0.65, 2.5);
    final screenSize = MediaQuery.of(context).size;
    
    final currentTranslation = _transformController.value.getTranslation();
    final focusX = (screenSize.width / 2 - currentTranslation.x) / currentScale;
    final focusY = (screenSize.height / 2 - currentTranslation.y) / currentScale;

    _centerOnOffset(Offset(focusX, focusY), scale: newScale);
  }

  Offset _getListingOffset(ListingModel listing, int index) {
    final loc = listing.location.toLowerCase();
    for (final entry in _neighborhoodCoords.entries) {
      if (loc.contains(entry.key.toLowerCase())) {
        final jitter = Offset((index % 3 - 1) * 38.0, ((index ~/ 3) % 3 - 1) * 38.0);
        return entry.value + jitter;
      }
    }
    final fallbackList = [
      const Offset(430, 760), // Bandra
      const Offset(470, 520), // Andheri
      const Offset(1050, 240), // Bhiwandi
      const Offset(820, 480), // Powai
      const Offset(370, 620), // Juhu
      const Offset(620, 810), // BKC
    ];
    return fallbackList[index % fallbackList.length];
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cameras':
        return Icons.camera_alt_rounded;
      case 'gaming':
        return Icons.sports_esports_rounded;
      case 'projectors':
        return Icons.videocam_rounded;
      case 'audio':
        return Icons.speaker_rounded;
      case 'tech':
        return Icons.laptop_mac_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allListings = AppStore.instance.activeListings;
    final filteredListings = _selectedNeighborhood == 'All'
        ? allListings
        : allListings.where((l) => l.location.toLowerCase().contains(_selectedNeighborhood.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFD6E9DE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Live Mumbai Gear Map',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            Text(
              '${allListings.length} verified items nearby • Pinch to zoom',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Recenter Mumbai',
            icon: const Icon(Icons.my_location_rounded, color: AppColors.primary),
            onPressed: () => _centerOnOffset(const Offset(520, 680), scale: 1.15),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Interactive InteractiveViewer Map
          InteractiveViewer(
            transformationController: _transformController,
            boundaryMargin: const EdgeInsets.all(500),
            minScale: 0.65,
            maxScale: 2.8,
            child: SizedBox(
              width: _mapWidth,
              height: _mapHeight,
              child: Stack(
                children: [
                  // Painted realistic terrain, coastlines & roads
                  CustomPaint(
                    size: const Size(_mapWidth, _mapHeight),
                    painter: _MumbaiMapPainter(),
                  ),

                  // Area Landmarks Labels
                  ..._buildLandmarkMarkers(),

                  // Item Markers
                  ...List.generate(allListings.length, (i) {
                    final item = allListings[i];
                    final isHighlighted = filteredListings.contains(item);
                    final isSelected = _selectedListing?.id == item.id;
                    final pos = _getListingOffset(item, i);

                    return Positioned(
                      left: pos.dx - (isSelected ? 45 : 38),
                      top: pos.dy - (isSelected ? 48 : 40),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedListing = item);
                          _centerOnOffset(pos, scale: 1.45);
                        },
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: isSelected ? 1.18 : (isHighlighted ? 1.0 : 0.75),
                          child: Opacity(
                            opacity: isHighlighted ? 1.0 : 0.45,
                            child: _buildPinMarker(item, isSelected),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Top Neighborhood Filter Chips
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  _buildNeighborhoodChip('All', allListings.length),
                  _buildNeighborhoodChip('Bandra', 2),
                  _buildNeighborhoodChip('Andheri', 1),
                  _buildNeighborhoodChip('Bhiwandi', 1),
                  _buildNeighborhoodChip('Juhu', 1),
                  _buildNeighborhoodChip('Powai', 1),
                  _buildNeighborhoodChip('BKC', 1),
                ],
              ),
            ),
          ),

          // Floating Zoom (+ / -) & Recenter Controls
          Positioned(
            right: 16,
            bottom: _selectedListing != null ? 180 : 30,
            child: Column(
              children: [
                _buildCircleActionButton(
                  icon: Icons.add,
                  tooltip: 'Zoom In',
                  onTap: () => _zoom(0.25),
                ),
                const SizedBox(height: 8),
                _buildCircleActionButton(
                  icon: Icons.remove,
                  tooltip: 'Zoom Out',
                  onTap: () => _zoom(-0.25),
                ),
                const SizedBox(height: 8),
                _buildCircleActionButton(
                  icon: Icons.filter_center_focus_rounded,
                  tooltip: 'Reset View',
                  onTap: () => _centerOnOffset(const Offset(520, 680), scale: 1.15),
                ),
              ],
            ),
          ),

          // Selected Listing Bottom Card
          if (_selectedListing != null)
            Positioned(
              bottom: 18,
              left: 14,
              right: 14,
              child: _buildSelectedListingCard(_selectedListing!),
            ),
        ],
      ),
    );
  }

  Widget _buildNeighborhoodChip(String label, int count) {
    final isSelected = _selectedNeighborhood == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedNeighborhood = label;
          if (label != 'All' && _neighborhoodCoords.containsKey(label)) {
            _centerOnOffset(_neighborhoodCoords[label]!, scale: 1.4);
          } else {
            _centerOnOffset(const Offset(520, 680), scale: 1.15);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white24 : const Color(0xFFE8F5EE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinMarker(ListingModel item, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF003D2B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFFFFD700) : AppColors.primary,
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isSelected ? 0.35 : 0.18),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getCategoryIcon(item.category),
                size: 13,
                color: isSelected ? const Color(0xFFFFD700) : AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                item.priceDisplay,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_drop_down,
          size: 18,
          color: isSelected ? const Color(0xFF003D2B) : Colors.white,
        ),
      ],
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
      ),
    );
  }

  Widget _buildSelectedListingCard(ListingModel listing) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 82,
                  height: 82,
                  child: AppImageWidget(
                    pathOrUrl: listing.imageUrls.isNotEmpty ? listing.imageUrls.first : '',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5EE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            listing.category,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                        const SizedBox(width: 2),
                        Text(
                          '${listing.rating}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 12, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Text(
                          '${listing.distanceKm} km • ${listing.location}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                onPressed: () => setState(() => _selectedListing = null),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Rental Rate', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textSecondary)),
                  Text(
                    '${listing.priceDisplay}/day',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProductDetailScreen(listing: listing)),
                  );
                },
                icon: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                label: const Text('Rent Now →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLandmarkMarkers() {
    return [
      _buildLandmark(const Offset(220, 780), 'Arabian Sea 🌊', Colors.blueGrey),
      _buildLandmark(const Offset(420, 740), 'Bandra West 🛍️', AppColors.primary),
      _buildLandmark(const Offset(360, 580), 'Juhu Beach 🏖️', AppColors.primary),
      _buildLandmark(const Offset(470, 470), 'Andheri Hub 🚇', AppColors.primary),
      _buildLandmark(const Offset(540, 590), 'Mumbai Airport ✈️', Colors.deepOrange),
      _buildLandmark(const Offset(820, 440), 'Powai Lake 🏞️', AppColors.primary),
      _buildLandmark(const Offset(620, 780), 'BKC Tech Hub 🏢', AppColors.primary),
      _buildLandmark(const Offset(1050, 200), 'Bhiwandi Logistics 📦', AppColors.primary),
      _buildLandmark(const Offset(480, 930), 'Dadar Central 🚉', AppColors.primary),
      _buildLandmark(const Offset(440, 1180), 'Colaba & Gateway 🏛️', AppColors.primary),
      _buildLandmark(const Offset(1020, 840), 'Thane Creek 🚢', Colors.blueGrey),
    ];
  }

  Widget _buildLandmark(Offset pos, String label, Color color) {
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E3A2F),
          ),
        ),
      ),
    );
  }
}

class _MumbaiMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Water base: Arabian Sea & Thane Creek
    final waterPaint = Paint()..color = const Color(0xFFBCE1F5);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), waterPaint);

    // 2. Land Mass (Mumbai Island + Salsette Peninsula)
    final landPaint = Paint()
      ..color = const Color(0xFFF1F6F3)
      ..style = PaintingStyle.fill;

    final landPath = Path();
    landPath.moveTo(420, 1260); // Colaba tip
    landPath.lineTo(460, 1240);
    landPath.lineTo(490, 1140);
    landPath.lineTo(520, 1000); // Worli / Dadar
    landPath.lineTo(700, 850);  // Kurla / Ghatkopar
    landPath.lineTo(950, 600);  // Bhandup / Mulund
    landPath.lineTo(1200, 300); // Thane / Bhiwandi
    landPath.lineTo(1200, 50);
    landPath.lineTo(700, 50);
    landPath.lineTo(580, 200);  // Borivali
    landPath.lineTo(450, 380);  // Malad / Goregaon
    landPath.lineTo(360, 580);  // Juhu
    landPath.lineTo(390, 780);  // Bandra
    landPath.lineTo(430, 880);  // Mahim Bay
    landPath.lineTo(420, 1000); // Worli
    landPath.lineTo(390, 1140); // Marine Drive
    landPath.close();

    canvas.drawPath(landPath, landPaint);

    // 3. Green Zones
    final forestPaint = Paint()..color = const Color(0xFFC7E5D3);
    final forestPath = Path();
    forestPath.addOval(Rect.fromLTWH(620, 260, 260, 220));
    canvas.drawPath(forestPath, forestPaint);

    // Powai Lake
    final lakePaint = Paint()..color = const Color(0xFF98CEEE);
    canvas.drawOval(Rect.fromLTWH(790, 460, 90, 55), lakePaint);

    // 4. Expressways & Highways
    final highwayPaint = Paint()
      ..color = const Color(0xFFFFD166)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final roadPath = Path();
    // Western Express Highway
    roadPath.moveTo(420, 800);
    roadPath.lineTo(470, 580);
    roadPath.lineTo(480, 470);
    roadPath.lineTo(520, 350);
    roadPath.lineTo(560, 200);

    // Eastern Express Highway
    roadPath.moveTo(510, 980);
    roadPath.lineTo(620, 800);
    roadPath.lineTo(720, 620);
    roadPath.lineTo(900, 440);
    roadPath.lineTo(1050, 250);

    // Bandra-Worli Sea Link
    final seaLinkPaint = Paint()
      ..color = const Color(0xFF007553)
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(390, 810), const Offset(420, 950), seaLinkPaint);

    canvas.drawPath(roadPath, highwayPaint);

    // 5. Grid lines (Streets)
    final streetPaint = Paint()
      ..color = const Color(0xFFDCE9E2)
      ..strokeWidth = 1.5;

    for (double y = 100; y < size.height; y += 80) {
      canvas.drawLine(Offset(250, y), Offset(size.width - 150, y), streetPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
