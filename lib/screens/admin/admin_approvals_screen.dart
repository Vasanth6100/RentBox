import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/listing_model.dart';
import '../../services/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_image.dart';

class AdminApprovalsScreen extends StatefulWidget {
  const AdminApprovalsScreen({super.key});

  @override
  State<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends State<AdminApprovalsScreen> {
  String _selectedFilter = 'Live'; // Live, Paused, Rejected, All
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
        final all = AppStore.instance.allListings;
        final filtered = all.where((l) {
          if (_selectedFilter == 'Live' && l.status != ListingStatus.active) return false;
          if (_selectedFilter == 'Paused' && l.status != ListingStatus.paused) return false;
          if (_selectedFilter == 'Rejected' && l.status != ListingStatus.rejected) return false;

          final q = _searchController.text.trim().toLowerCase();
          if (q.isNotEmpty &&
              !l.title.toLowerCase().contains(q) &&
              !l.ownerName.toLowerCase().contains(q)) {
            return false;
          }
          return true;
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.mintBackground,
          appBar: _buildHeader(context),
          body: Column(
            children: [
              _buildStreamStatusStrip(),
              _buildSearchBar(),
              _buildFilterPills(),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _buildModerationCard(context, filtered[index]);
                        },
                      ),
              ),
              _buildQueueSummaryFooter(filtered.length),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildHeader(BuildContext context) {
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
            'Catalog Moderation',
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
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
          onPressed: () async {
            await AppStore.instance.syncWithBackend();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Catalog refreshed from shared database.')),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildStreamStatusStrip() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981))),
              const SizedBox(width: 6),
              Text(
                'LIVE MODERATION STREAM',
                style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF1E3E30), letterSpacing: 0.6),
              ),
            ],
          ),
          Text(
            'Auto-sync: Active (SSE)',
            style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFEEF5F1),
          borderRadius: BorderRadius.circular(22),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Filter by listing title or owner name...',
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF6B8479)),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPills() {
    final filters = ['Live', 'Paused', 'Rejected', 'All'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: filters.map((f) {
            final isSel = _selectedFilter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(f),
                selected: isSel,
                selectedColor: AppColors.primary,
                backgroundColor: const Color(0xFFF0F5F2),
                labelStyle: TextStyle(
                  color: isSel ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
                onSelected: (_) => setState(() => _selectedFilter = f),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildModerationCard(BuildContext context, ListingModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Header info
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AppImageWidget(
                        pathOrUrl: item.imageUrls.isNotEmpty ? item.imageUrls.first : '',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.imageUrls.length} photos',
                          style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F4EC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item.category,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          _buildStatusTag(item.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Owner: ${item.ownerName} • ${item.location}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${item.pricePerDay.toStringAsFixed(0)}/day  •  Deposit: ₹${item.securityDeposit.toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFEBF1ED), height: 1),

          // Document Verification Indicators
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _buildDocBadge('Original Bill', item.hasBill),
                const SizedBox(width: 8),
                _buildDocBadge('Serial Checked', item.hasSerialVerified),
                const SizedBox(width: 8),
                _buildDocBadge('Owner KYC', item.hasIdVerified),
              ],
            ),
          ),
          const Divider(color: Color(0xFFEBF1ED), height: 1),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.status == ListingStatus.active
                              ? const Color(0xFFE8F5EE)
                              : (item.status == ListingStatus.paused ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.status == ListingStatus.active
                              ? '✓ Live on Explore'
                              : (item.status == ListingStatus.paused ? '⏸ Paused' : '✕ Moderated'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: item.status == ListingStatus.active
                                ? AppColors.primary
                                : (item.status == ListingStatus.paused ? const Color(0xFFD97706) : const Color(0xFFDC2626)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.status == ListingStatus.active) ...[
                  OutlinedButton(
                    onPressed: () {
                      AppStore.instance.toggleListingPause(item.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('"${item.title}" paused.')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD97706),
                      side: const BorderSide(color: Color(0xFFFCD34D)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(0, 34),
                    ),
                    child: const Text('Pause', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _showRejectDialog(context, item),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(0, 34),
                    ),
                    child: const Text('Reject', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ] else if (item.status == ListingStatus.paused) ...[
                  ElevatedButton(
                    onPressed: () {
                      AppStore.instance.toggleListingPause(item.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"${item.title}" re-activated!'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: const Size(0, 34),
                    ),
                    child: const Text('Activate', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, item),
                  icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                  label: const Text('Delete', style: TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ListingModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Listing Permanently?'),
        content: Text('Are you sure you want to delete "${item.title}"? This will immediately remove it from RentBox.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              AppStore.instance.deleteListing(item.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${item.title}" deleted by Admin.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDocBadge(String label, bool verified) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          color: verified ? const Color(0xFFE8F5EE) : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              verified ? Icons.check_circle : Icons.warning_amber_rounded,
              size: 11,
              color: verified ? AppColors.primary : const Color(0xFFD97706),
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: verified ? AppColors.primary : const Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTag(ListingStatus status) {
    switch (status) {
      case ListingStatus.pendingApproval:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
          child: const Text('Pending Review', style: TextStyle(color: Color(0xFF92400E), fontSize: 9.5, fontWeight: FontWeight.bold)),
        );
      case ListingStatus.active:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(8)),
          child: const Text('Live', style: TextStyle(color: Color(0xFF065F46), fontSize: 9.5, fontWeight: FontWeight.bold)),
        );
      case ListingStatus.rejected:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
          child: const Text('Rejected', style: TextStyle(color: Color(0xFF991B1B), fontSize: 9.5, fontWeight: FontWeight.bold)),
        );
      case ListingStatus.paused:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(8)),
          child: const Text('Paused', style: TextStyle(color: Color(0xFF374151), fontSize: 9.5, fontWeight: FontWeight.bold)),
        );
    }
  }

  Widget _buildQueueSummaryFooter(int count) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$count items in this queue',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            Text(
              'Avg response: 14 mins',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ],
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
            const Icon(Icons.done_all_rounded, size: 54, color: Color(0xFFA5BCB0)),
            const SizedBox(height: 12),
            Text(
              'Moderation Queue Clear!',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'No items currently pending approval under this filter.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, ListingModel item) {
    final reasonCtrl = TextEditingController(text: 'Insufficient bill proof & unclear serial number photo.');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Listing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Provide specific feedback to ${item.ownerName}:', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            TextField(controller: reasonCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Enter reason...')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              AppStore.instance.rejectListing(item.id, reasonCtrl.text.trim());
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Confirm Rejection', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
