import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/listing_model.dart';
import '../../services/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_image.dart';
import 'list_item_wizard_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> with SingleTickerProviderStateMixin {
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
        final myListings = AppStore.instance.myListings;
        final activeListings = myListings.where((l) => l.status == ListingStatus.active).toList();
        final pendingListings = myListings.where((l) => l.status == ListingStatus.pendingApproval).toList();
        final pausedListings = myListings.where((l) => l.status == ListingStatus.paused).toList();

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
              'My Listings',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.primary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ListItemWizardScreen()),
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(text: 'Active (${activeListings.length})'),
                Tab(text: 'Pending (${pendingListings.length})'),
                Tab(text: 'Paused (${pausedListings.length})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildListingsList(activeListings, 'active'),
              _buildListingsList(pendingListings, 'pending'),
              _buildListingsList(pausedListings, 'paused'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListingsList(List<ListingModel> items, String tabType) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 54, color: AppColors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                'No $tabType listings found',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add items using the + button to start renting them out.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE4EDE7)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AppImageWidget(
                    pathOrUrl: item.imageUrls.isNotEmpty ? item.imageUrls.first : '',
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.priceDisplay}/day • Deposit: ₹${item.securityDeposit.toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.location,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                  onSelected: (val) {
                    if (val == 'toggle') {
                      final newStatus = item.status == ListingStatus.active
                          ? ListingStatus.paused
                          : ListingStatus.active;
                      AppStore.instance.updateListingStatus(item.id, newStatus);
                    } else if (val == 'delete') {
                      AppStore.instance.deleteListing(item.id);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(item.status == ListingStatus.active ? 'Pause Listing' : 'Activate Listing'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Listing', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
