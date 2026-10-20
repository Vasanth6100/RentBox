import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/listing_model.dart';
import '../models/booking_model.dart';
import '../models/chat_model.dart';
import '../models/notification_model.dart';
import '../models/dispute_model.dart';
import '../models/review_model.dart';
import 'api_service.dart';

class AppStore extends ChangeNotifier {
  static final AppStore instance = AppStore._internal();
  factory AppStore() => instance;

  AppStore._internal() {
    _initSeedData();
    syncWithBackend();
  }

  Future<void> syncWithBackend() async {
    try {
      final isOnline = await ApiService.instance.checkHealth();
      if (!isOnline) return;

      final backendListings = await ApiService.instance.getListings(userId: _currentUser.id);
      if (backendListings.isNotEmpty) {
        _listings = backendListings;
      }

      final backendBookings = await ApiService.instance.getBookings();
      if (backendBookings.isNotEmpty) {
        _bookings = backendBookings;
      }

      final backendDisputes = await ApiService.instance.getDisputes();
      if (backendDisputes.isNotEmpty) {
        _disputes = backendDisputes;
      }

      final backendNotifs = await ApiService.instance.getNotifications(_currentUser.id);
      if (backendNotifs.isNotEmpty) {
        _notifications = backendNotifs;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('AppStore syncWithBackend error: $e');
    }
  }

  // --- Current User State ---
  late UserModel _currentUser;
  UserModel get currentUser => _currentUser;

  // --- Core Collections ---
  List<ListingModel> _listings = [];
  List<BookingModel> _bookings = [];
  final List<ChatConversation> _conversations = [];
  final Map<String, List<ChatMessage>> _messagesByConvId = {};
  List<NotificationModel> _notifications = [];
  List<DisputeCaseModel> _disputes = [];
  List<ReviewModel> _reviews = [];

  // --- Getters ---
  List<ListingModel> get allListings => List.unmodifiable(_listings);
  List<ListingModel> get activeListings =>
      _listings.where((l) => l.status == ListingStatus.active).toList();
  List<ListingModel> get pendingApprovalListings =>
      _listings.where((l) => l.status == ListingStatus.pendingApproval).toList();
  List<ListingModel> get myListings =>
      _listings.where((l) => l.ownerId == _currentUser.id).toList();

  List<BookingModel> get myCustomerBookings =>
      _bookings.where((b) => b.renterId == _currentUser.id).toList();
  List<BookingModel> get myOwnerBookings =>
      _bookings.where((b) => b.ownerId == _currentUser.id).toList();
  List<BookingModel> get allBookings => List.unmodifiable(_bookings);

  List<ChatConversation> get conversations => List.unmodifiable(_conversations);
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadNotificationsCount => _notifications.where((n) => !n.isRead).length;

  List<DisputeCaseModel> get allDisputes => List.unmodifiable(_disputes);
  List<DisputeCaseModel> get openDisputes =>
      _disputes.where((d) => d.status == DisputeStatus.open || d.status == DisputeStatus.underReview).toList();

  List<ListingModel> get favoriteListings => _listings
      .where((l) => _currentUser.favoriteListingIds.contains(l.id))
      .toList();

  void setCurrentUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  // --- Role Management ---
  void switchRole(UserRole role) {
    _currentUser = _currentUser.copyWith(activeRole: role);
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? phone, String? location, String? avatarUrl}) async {
    _currentUser = _currentUser.copyWith(
      name: name,
      phone: phone,
      location: location,
      avatarUrl: avatarUrl,
    );

    // Sync avatar & name across current user's listings and reviews in store
    if (avatarUrl != null || name != null) {
      _listings = _listings.map((l) {
        if (l.ownerId == _currentUser.id) {
          return l.copyWith(
            ownerAvatar: avatarUrl ?? l.ownerAvatar,
            ownerName: name ?? l.ownerName,
          );
        }
        return l;
      }).toList();

      _reviews = _reviews.map((r) {
        if (r.authorName == _currentUser.name) {
          return r.copyWith(
            authorAvatar: avatarUrl ?? r.authorAvatar,
            authorName: name ?? r.authorName,
          );
        }
        return r;
      }).toList();
    }

    notifyListeners();

    try {
      final updated = await ApiService.instance.updateProfile(
        userId: _currentUser.id,
        name: name,
        phone: phone,
        location: location,
        avatarUrl: avatarUrl,
      );
      if (updated != null) {
        _currentUser = updated;
        if (avatarUrl != null || name != null) {
          _listings = _listings.map((l) {
            if (l.ownerId == _currentUser.id) {
              return l.copyWith(
                ownerAvatar: updated.avatarUrl,
                ownerName: updated.name,
              );
            }
            return l;
          }).toList();
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AppStore.updateProfile backend error: $e');
    }
  }

  // --- Favourites Management ---
  void toggleFavorite(String listingId) {
    final favorites = List<String>.from(_currentUser.favoriteListingIds);
    if (favorites.contains(listingId)) {
      favorites.remove(listingId);
    } else {
      favorites.add(listingId);
    }
    _currentUser = _currentUser.copyWith(favoriteListingIds: favorites);
    notifyListeners();
    ApiService.instance.toggleFavorite(_currentUser.id, listingId);
  }

  bool isFavorite(String listingId) {
    return _currentUser.favoriteListingIds.contains(listingId);
  }

  // --- Listings Operations ---
  Future<ListingModel?> addListing(ListingModel listing) async {
    _listings.insert(0, listing);
    _addNotification(
      title: 'Listing Submitted',
      message: '"${listing.title}" is now added to RentBox.',
      type: NotificationType.listingApproval,
    );
    notifyListeners();

    try {
      final backendCreated = await ApiService.instance.createListing(listing);
      if (backendCreated != null) {
        final idx = _listings.indexWhere((l) => l.id == listing.id);
        if (idx != -1) {
          _listings[idx] = backendCreated;
        }
        notifyListeners();
        return backendCreated;
      }
    } catch (e) {
      debugPrint('AppStore.addListing backend error: $e');
    }
    return listing;
  }

  void approveListing(String listingId) {
    final index = _listings.indexWhere((l) => l.id == listingId);
    if (index != -1) {
      _listings[index] = _listings[index].copyWith(
        status: ListingStatus.active,
        rejectionReason: null,
      );
      _addNotification(
        title: 'Listing Approved! 🎉',
        message: '"${_listings[index].title}" is now live and bookable in Mumbai.',
        type: NotificationType.listingApproval,
      );
      notifyListeners();
      ApiService.instance.approveListing(listingId);
    }
  }

  void rejectListing(String listingId, String reason) {
    final index = _listings.indexWhere((l) => l.id == listingId);
    if (index != -1) {
      _listings[index] = _listings[index].copyWith(
        status: ListingStatus.rejected,
        rejectionReason: reason,
      );
      _addNotification(
        title: 'Listing Needs Attention',
        message: '"${_listings[index].title}" was rejected: $reason',
        type: NotificationType.listingApproval,
      );
      notifyListeners();
      ApiService.instance.rejectListing(listingId, reason);
    }
  }

  void requestReshoot(String listingId, String instructions) {
    final index = _listings.indexWhere((l) => l.id == listingId);
    if (index != -1) {
      _listings[index] = _listings[index].copyWith(
        status: ListingStatus.pendingApproval,
        rejectionReason: 'Reshoot requested: $instructions',
      );
      _addNotification(
        title: 'Photos Update Requested',
        message: 'Please re-upload photos for "${_listings[index].title}": $instructions',
        type: NotificationType.listingApproval,
      );
      notifyListeners();
    }
  }

  void toggleListingPause(String listingId) {
    final index = _listings.indexWhere((l) => l.id == listingId);
    if (index != -1) {
      final current = _listings[index].status;
      _listings[index] = _listings[index].copyWith(
        status: current == ListingStatus.active ? ListingStatus.paused : ListingStatus.active,
      );
      notifyListeners();
      ApiService.instance.toggleListingPause(listingId);
    }
  }

  void updateListingStatus(String listingId, ListingStatus status) {
    final index = _listings.indexWhere((l) => l.id == listingId);
    if (index != -1) {
      _listings[index] = _listings[index].copyWith(status: status);
      notifyListeners();
    }
  }

  void deleteListing(String listingId) {
    _listings.removeWhere((l) => l.id == listingId);
    notifyListeners();
  }

  // --- Booking Operations ---
  BookingModel createBooking({
    required ListingModel listing,
    required DateTime startDate,
    required DateTime endDate,
    required FulfillmentMethod fulfillmentMethod,
    required ProtectionPlan protectionPlan,
    required String paymentMethod,
  }) {
    final durationDays = endDate.difference(startDate).inDays.clamp(1, 365);
    final rentalFee = listing.pricePerDay * durationDays;
    final securityDeposit = listing.securityDeposit;
    final deliveryFee = fulfillmentMethod == FulfillmentMethod.ownerDelivery
        ? listing.deliveryCharge
        : 0.0;
    final protectionFee = protectionPlan == ProtectionPlan.standard
        ? 99.0
        : (protectionPlan == ProtectionPlan.basic ? 49.0 : 0.0);
    final taxes = (rentalFee * 0.05).roundToDouble(); // 5% platform tax
    final totalPayable = rentalFee + securityDeposit + deliveryFee + protectionFee + taxes;

    final bookingId = 'RB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final pickupCode = 'RB-${(1000 + (DateTime.now().microsecond % 9000))}';

    final newBooking = BookingModel(
      id: bookingId,
      listingId: listing.id,
      listingTitle: listing.title,
      listingImage: listing.imageUrls.first,
      renterId: _currentUser.id,
      renterName: _currentUser.name,
      ownerId: listing.ownerId,
      ownerName: listing.ownerName,
      startDate: startDate,
      endDate: endDate,
      durationDays: durationDays,
      fulfillmentMethod: fulfillmentMethod,
      protectionPlan: protectionPlan,
      dailyRate: listing.pricePerDay,
      rentalFee: rentalFee,
      securityDeposit: securityDeposit,
      deliveryFee: deliveryFee,
      protectionFee: protectionFee,
      taxes: taxes,
      totalPayable: totalPayable,
      status: BookingStatus.upcoming,
      pickupCode: pickupCode,
      paymentMethod: paymentMethod,
      paymentStatus: 'Paid',
      location: listing.location,
      createdAt: DateTime.now(),
    );

    _bookings.insert(0, newBooking);

    _addNotification(
      title: 'Booking Confirmed! 📦',
      message: 'Your rental for "${listing.title}" is booked. Pickup Code: $pickupCode',
      type: NotificationType.booking,
    );

    notifyListeners();
    ApiService.instance.createBooking(newBooking);
    return newBooking;
  }

  void cancelBooking(String bookingId) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(
        status: BookingStatus.cancelled,
        paymentStatus: 'Refunded (₹${_bookings[index].totalPayable.toStringAsFixed(0)})',
      );
      _addNotification(
        title: 'Booking Cancelled',
        message: 'Booking $bookingId cancelled. Full refund initiated.',
        type: NotificationType.booking,
      );
      notifyListeners();
      ApiService.instance.updateBookingStatus(bookingId, 'cancelled', paymentStatus: 'Refunded');
    }
  }

  void markBookingActive(String bookingId) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(status: BookingStatus.active);
      notifyListeners();
    }
  }

  void markBookingCompleted(String bookingId) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(status: BookingStatus.completed);
      _addNotification(
        title: 'Rental Completed & Deposit Returned 🛡️',
        message: 'Security deposit of ₹${_bookings[index].securityDeposit.toStringAsFixed(0)} returned to source account.',
        type: NotificationType.payment,
      );
      notifyListeners();
    }
  }

  void updateBookingStatus(String bookingId, BookingStatus status) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(status: status);
      if (status == BookingStatus.completed) {
        _addNotification(
          title: 'Rental Completed & Deposit Returned 🛡️',
          message: 'Security deposit of ₹${_bookings[index].securityDeposit.toStringAsFixed(0)} returned.',
          type: NotificationType.payment,
        );
      }
      notifyListeners();
    }
  }

  // --- Reviews ---
  void addReview({
    required String bookingId,
    required String listingId,
    required double rating,
    required String comment,
  }) {
    final review = ReviewModel(
      id: 'REV-${DateTime.now().millisecondsSinceEpoch}',
      listingId: listingId,
      bookingId: bookingId,
      authorName: _currentUser.name,
      authorAvatar: _currentUser.avatarUrl,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );
    _reviews.insert(0, review);

    final bookingIndex = _bookings.indexWhere((b) => b.id == bookingId);
    if (bookingIndex != -1) {
      _bookings[bookingIndex] = _bookings[bookingIndex].copyWith(isReviewed: true);
    }
    notifyListeners();
  }

  List<ReviewModel> getReviewsForListing(String listingId) {
    return _reviews.where((r) => r.listingId == listingId).toList();
  }

  // --- Messaging ---
  List<ChatMessage> getMessages(String conversationId) {
    return _messagesByConvId[conversationId] ?? [];
  }

  void sendMessage({
    required String conversationId,
    required String text,
  }) {
    final msg = ChatMessage(
      id: 'MSG-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: _currentUser.id,
      text: text,
      timestamp: DateTime.now(),
    );

    if (!_messagesByConvId.containsKey(conversationId)) {
      _messagesByConvId[conversationId] = [];
    }
    _messagesByConvId[conversationId]!.add(msg);

    final convIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (convIndex != -1) {
      _conversations[convIndex] = _conversations[convIndex].copyWith(
        lastMessage: text,
        lastMessageTime: DateTime.now(),
      );
    }
    notifyListeners();
  }

  ChatConversation getOrCreateConversation({
    required String listingId,
    required String listingTitle,
    required String otherUserId,
    required String otherUserName,
    required String otherUserAvatar,
  }) {
    final existing = _conversations.firstWhere(
      (c) => c.listingId == listingId && c.otherUserId == otherUserId,
      orElse: () {
        final newConv = ChatConversation(
          id: 'CONV-${DateTime.now().millisecondsSinceEpoch}',
          listingId: listingId,
          listingTitle: listingTitle,
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          otherUserAvatar: otherUserAvatar,
          lastMessage: 'Hi, is this item available for rental?',
          lastMessageTime: DateTime.now(),
        );
        _conversations.insert(0, newConv);
        _messagesByConvId[newConv.id] = [
          ChatMessage(
            id: 'M1',
            conversationId: newConv.id,
            senderId: otherUserId,
            text: 'Hello! Yes, the gear is sanitized and available.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        ];
        return newConv;
      },
    );
    notifyListeners();
    return existing;
  }

  // --- Disputes ---
  void fileDispute({
    required String bookingId,
    required String itemTitle,
    required String ownerName,
    required String reason,
    required String description,
    required double amountInvolved,
  }) {
    final dispute = DisputeCaseModel(
      id: 'DISP-${DateTime.now().millisecondsSinceEpoch}',
      caseId: 'CASE-00${_disputes.length + 1}',
      bookingId: bookingId,
      itemTitle: itemTitle,
      renterName: _currentUser.name,
      ownerName: ownerName,
      reason: reason,
      description: description,
      amountInvolved: amountInvolved,
      status: DisputeStatus.open,
      createdAt: DateTime.now(),
    );
    _disputes.insert(0, dispute);
    _addNotification(
      title: 'Dispute Ticket Created',
      message: 'Ticket ${dispute.caseId} opened for review by Admin Support.',
      type: NotificationType.security,
    );
    notifyListeners();
    ApiService.instance.fileDispute(
      bookingId: bookingId,
      itemTitle: itemTitle,
      ownerName: ownerName,
      renterName: _currentUser.name,
      reason: reason,
      description: description,
      amountInvolved: amountInvolved,
    );
  }

  void resolveDispute(String disputeId, String resolution) {
    final index = _disputes.indexWhere((d) => d.id == disputeId);
    if (index != -1) {
      _disputes[index] = _disputes[index].copyWith(
        status: DisputeStatus.resolved,
        resolution: resolution,
      );
      notifyListeners();
      ApiService.instance.resolveDispute(disputeId, resolution);
    }
  }

  // --- Notifications Helper ---
  void _addNotification({
    required String title,
    required String message,
    required NotificationType type,
  }) {
    _notifications.insert(
      0,
      NotificationModel(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: message,
        type: type,
        timestamp: DateTime.now(),
      ),
    );
  }

  void markNotificationAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllNotificationsAsRead() {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  // --- Initial Seed Data ---
  void _initSeedData() {
    _currentUser = UserModel(
      id: 'USER-1',
      name: 'Vasanth Kumar',
      email: 'vasanth@rentbox.in',
      phone: '+91 98765 43210',
      avatarUrl: 'assets/images/avatar.jpg',
      location: 'Mumbai, Maharashtra',
      activeRole: UserRole.customer,
      joinedDate: DateTime(2024, 1, 15),
      favoriteListingIds: ['item-1', 'item-2'],
    );

    _listings = [
      ListingModel(
        id: 'LIST-1',
        title: 'Sony Alpha Camera',
        category: 'Cameras',
        pricePerDay: 700.0,
        securityDeposit: 3000.0,
        brand: 'Sony',
        modelName: 'Alpha A7 IV',
        condition: 'Like New',
        description:
            'Professional 33MP Full-Frame mirrorless camera with 4K 60p 10-bit recording. Perfect for weddings, corporate shoots, and cinematic travel vlogs.',
        specifications: {
          'Sensor': '33MP Full-Frame Exmor R',
          'Video': '4K 60p 10-bit 4:2:2',
          'Mount': 'Sony E-Mount',
          'Autofocus': '759 AF points with Real-time Eye AF',
          'Weight': '658g (Body only)',
        },
        includedItems: [
          'Camera body',
          '24–70 mm F2.8 GM lens',
          '2x Sony NP-FZ100 Batteries',
          '64 GB Fast SD card',
          'Dual Charger & Carry Bag',
        ],
        imageUrls: [
          'assets/images/camera.jpg',
        ],
        location: 'Bhiwandi, Mumbai',
        distanceKm: 2.0,
        ownerId: 'OWNER-1',
        ownerName: 'Rajesh Sharma',
        ownerAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
        ownerRating: 4.8,
        ownerResponseTime: 'Replies in 15 mins',
        isOwnerVerified: true,
        status: ListingStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
        rating: 4.8,
        reviewsCount: 38,
        deliveryCharge: 150.0,
        isDeliveryAvailable: true,
      ),
      ListingModel(
        id: 'LIST-2',
        title: 'PS5 Console',
        category: 'Gaming',
        pricePerDay: 900.0,
        securityDeposit: 4000.0,
        brand: 'Sony',
        modelName: 'PlayStation 5 Disc Edition',
        condition: 'Like New',
        description:
            'Next-gen Sony PlayStation 5 with lightning-fast SSD, ultra-high speed HDMI 2.1, and 2 DualSense wireless controllers. Comes preloaded with popular titles.',
        specifications: {
          'Storage': '825GB Ultra-High Speed NVMe',
          'Resolution': 'Up to 4K 120Hz & 8K HDR',
          'Audio': 'Tempest 3D AudioTech',
          'Controllers': '2x DualSense Haptic Feedback',
        },
        includedItems: [
          'PS5 Console Disc Edition',
          '2 DualSense Wireless Controllers',
          'FIFA 24 & Spider-Man 2 Games',
          'HDMI 2.1 Cable & Power Cord',
        ],
        imageUrls: [
          'assets/images/ps5.jpg',
        ],
        location: 'Thane, Mumbai',
        distanceKm: 3.5,
        ownerId: 'OWNER-2',
        ownerName: 'Aditya Nair',
        ownerAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&auto=format&fit=crop&q=80',
        ownerRating: 4.9,
        ownerResponseTime: 'Replies in 10 mins',
        isOwnerVerified: true,
        status: ListingStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        rating: 4.9,
        reviewsCount: 52,
        deliveryCharge: 200.0,
        isDeliveryAvailable: true,
      ),
      ListingModel(
        id: 'LIST-3',
        title: 'Epson Projector',
        category: 'Projectors',
        pricePerDay: 500.0,
        securityDeposit: 2500.0,
        brand: 'Epson',
        modelName: 'Home Cinema Full HD 3800',
        condition: 'Excellent',
        description:
            '3,800 Lumens Full HD cinema projector. Ideal for backyard movie nights, sports screenings, or office presentations with high ambient light.',
        specifications: {
          'Brightness': '3,800 ANSI Lumens',
          'Native Resolution': '1080p Full HD (1920x1080)',
          'Contrast Ratio': '16,000:1',
          'Connectivity': '2x HDMI, USB, Audio Out',
        },
        includedItems: [
          'Projector unit',
          '10m HDMI Cable',
          'Remote Control',
          'Power Cord & Tripod adapter',
        ],
        imageUrls: [
          'assets/images/projector.jpg',
        ],
        location: 'Dadar, Mumbai',
        distanceKm: 4.2,
        ownerId: 'OWNER-3',
        ownerName: 'Vikram Mehta',
        ownerAvatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&auto=format&fit=crop&q=80',
        ownerRating: 4.7,
        ownerResponseTime: 'Replies in 30 mins',
        isOwnerVerified: true,
        status: ListingStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        rating: 4.7,
        reviewsCount: 19,
        deliveryCharge: 150.0,
        isDeliveryAvailable: true,
      ),
      ListingModel(
        id: 'LIST-4',
        title: 'JBL Party Speaker',
        category: 'Audio',
        pricePerDay: 800.0,
        securityDeposit: 3000.0,
        brand: 'JBL',
        modelName: 'PartyBox 310',
        condition: 'Like New',
        description:
            '240W RMS powerful JBL Pro Sound with synced dynamic light show. Features built-in wheels, telescopic handle, and 18-hour battery life.',
        specifications: {
          'Power Output': '240W RMS',
          'Battery Life': 'Up to 18 Hours',
          'Water Resistance': 'IPX4 Splashproof',
          'Inputs': 'Mic/Guitar inputs with volume control',
        },
        includedItems: [
          'JBL PartyBox 310',
          'AC Power Cable',
          'Wireless Microphone kit',
        ],
        imageUrls: [
          'assets/images/speaker.jpg',
        ],
        location: 'Navi Mumbai',
        distanceKm: 6.0,
        ownerId: 'OWNER-1',
        ownerName: 'Rajesh Sharma',
        ownerAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
        ownerRating: 4.9,
        ownerResponseTime: 'Replies in 15 mins',
        isOwnerVerified: true,
        status: ListingStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        rating: 4.9,
        reviewsCount: 31,
        deliveryCharge: 250.0,
        isDeliveryAvailable: true,
      ),
      // --- Pending Admin Moderation Listings ---
      ListingModel(
        id: 'LIST-PENDING-1',
        title: 'DJI Mini 4 Pro Drone',
        category: 'Tech',
        pricePerDay: 1200.0,
        securityDeposit: 6000.0,
        brand: 'DJI',
        modelName: 'Mini 4 Pro Fly More Combo',
        condition: 'Like New',
        description:
            'Under 249g ultra-light drone with omnidirectional obstacle sensing, 4K/60fps HDR video, and 20km video transmission. Verified owner with DGCA registration.',
        specifications: {
          'Weight': '249g',
          'Video': '4K/60fps HDR, 4K/100fps Slow Motion',
          'Flight Time': 'Up to 34 minutes per battery',
        },
        includedItems: [
          'DJI Mini 4 Pro Drone',
          'RC 2 Smart Controller with Screen',
          '3x Intelligent Flight Batteries',
          'Two-Way Charging Hub & Case',
        ],
        imageUrls: [
          'assets/images/drone.jpg',
        ],
        location: 'Bandra West, Mumbai',
        distanceKm: 5.1,
        ownerId: 'OWNER-4',
        ownerName: 'Kunal Verma',
        ownerAvatar: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200&auto=format&fit=crop&q=80',
        ownerRating: 4.8,
        status: ListingStatus.pendingApproval,
        hasBill: true,
        hasSerialVerified: true,
        hasIdVerified: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        rating: 5.0,
        reviewsCount: 6,
      ),
      ListingModel(
        id: 'LIST-PENDING-2',
        title: 'GoPro Hero 12 Black',
        category: 'Cameras',
        pricePerDay: 450.0,
        securityDeposit: 2000.0,
        brand: 'GoPro',
        modelName: 'Hero 12 Creator Edition',
        condition: 'Excellent',
        description:
            'Rugged waterproof action camera with HyperSmooth 6.0 video stabilization and 5.3K60 recording. Includes underwater housing and chest mount.',
        specifications: {
          'Resolution': '5.3K 60fps / 4K 120fps',
          'Waterproof': '10m without housing / 60m with case',
          'Stabilization': 'HyperSmooth 6.0 with AutoBoost',
        },
        includedItems: [
          'GoPro Hero 12 Black',
          '2x Enduro Batteries',
          'Waterproof Dive Housing',
          'Chest & Helmet Mounts',
        ],
        imageUrls: [
          'assets/images/camera.jpg',
        ],
        location: 'Andheri East, Mumbai',
        distanceKm: 7.2,
        ownerId: 'OWNER-5',
        ownerName: 'Priya Chawla',
        ownerAvatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200&auto=format&fit=crop&q=80',
        ownerRating: 4.7,
        status: ListingStatus.pendingApproval,
        hasBill: true,
        hasSerialVerified: false,
        hasIdVerified: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        rating: 4.7,
        reviewsCount: 14,
      ),
    ];

    // Seed Bookings
    _bookings = [
      BookingModel(
        id: 'RB-9842',
        listingId: 'LIST-1',
        listingTitle: 'Sony Alpha Camera',
        listingImage: 'assets/images/camera.jpg',
        renterId: _currentUser.id,
        renterName: _currentUser.name,
        ownerId: 'OWNER-1',
        ownerName: 'Rajesh Sharma',
        startDate: DateTime.now().add(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        durationDays: 3,
        fulfillmentMethod: FulfillmentMethod.ownerDelivery,
        protectionPlan: ProtectionPlan.standard,
        dailyRate: 700.0,
        rentalFee: 2100.0,
        securityDeposit: 3000.0,
        deliveryFee: 150.0,
        protectionFee: 99.0,
        taxes: 105.0,
        totalPayable: 5454.0,
        status: BookingStatus.upcoming,
        pickupCode: 'RB-9842',
        paymentMethod: 'UPI (GPay)',
        paymentStatus: 'Paid',
        location: 'Bhiwandi, Mumbai',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      BookingModel(
        id: 'RB-8120',
        listingId: 'LIST-2',
        listingTitle: 'PS5 Console',
        listingImage: 'assets/images/ps5.jpg',
        renterId: _currentUser.id,
        renterName: _currentUser.name,
        ownerId: 'OWNER-2',
        ownerName: 'Aditya Nair',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 2)),
        durationDays: 3,
        fulfillmentMethod: FulfillmentMethod.selfPickup,
        protectionPlan: ProtectionPlan.standard,
        dailyRate: 900.0,
        rentalFee: 2700.0,
        securityDeposit: 4000.0,
        deliveryFee: 0.0,
        protectionFee: 99.0,
        taxes: 135.0,
        totalPayable: 6934.0,
        status: BookingStatus.active,
        pickupCode: 'RB-8120',
        paymentMethod: 'Credit Card',
        paymentStatus: 'Paid',
        location: 'Thane, Mumbai',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      BookingModel(
        id: 'RB-7341',
        listingId: 'LIST-4',
        listingTitle: 'JBL Party Speaker',
        listingImage: 'assets/images/speaker.jpg',
        renterId: _currentUser.id,
        renterName: _currentUser.name,
        ownerId: 'OWNER-1',
        ownerName: 'Rajesh Sharma',
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().subtract(const Duration(days: 8)),
        durationDays: 2,
        fulfillmentMethod: FulfillmentMethod.selfPickup,
        protectionPlan: ProtectionPlan.basic,
        dailyRate: 800.0,
        rentalFee: 1600.0,
        securityDeposit: 3000.0,
        deliveryFee: 0.0,
        protectionFee: 49.0,
        taxes: 80.0,
        totalPayable: 4729.0,
        status: BookingStatus.completed,
        pickupCode: 'RB-7341',
        paymentMethod: 'UPI',
        paymentStatus: 'Deposit Refunded',
        location: 'Navi Mumbai',
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
        isReviewed: true,
      ),
    ];

    // Seed Reviews
    _reviews = [
      ReviewModel(
        id: 'REV-1',
        listingId: 'LIST-1',
        bookingId: 'RB-6101',
        authorName: 'Sneha Patel',
        authorAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&auto=format&fit=crop&q=80',
        rating: 5.0,
        comment: 'Camera condition was super clean and sensor had zero dust. Owner gave helpful instructions!',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      ReviewModel(
        id: 'REV-2',
        listingId: 'LIST-1',
        bookingId: 'RB-5982',
        authorName: 'Manish Iyer',
        authorAvatar: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=200&auto=format&fit=crop&q=80',
        rating: 4.8,
        comment: 'Great gear, batteries held full charge. Handover at Bhiwandi was seamless.',
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
    ];

    // Seed Notifications
    _notifications = [
      NotificationModel(
        id: 'N1',
        title: 'Pickup Ready: Sony Alpha Camera',
        message: 'Owner Rajesh Sharma confirmed your pickup slot for tomorrow 10:00 AM.',
        type: NotificationType.booking,
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      NotificationModel(
        id: 'N2',
        title: 'Deposit Security Active 🛡️',
        message: 'Your security deposit of ₹3,000 is safely held in RentBox Escrow.',
        type: NotificationType.security,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      NotificationModel(
        id: 'N3',
        title: 'New Review on Completed Rental',
        message: 'Your rental for JBL PartyBox was marked complete. Leave a rating!',
        type: NotificationType.reminder,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    // Seed Disputes
    _disputes = [
      DisputeCaseModel(
        id: 'DISP-1',
        caseId: 'CASE-001',
        bookingId: 'RB-6921',
        itemTitle: 'DJI Ronin Gimbal',
        renterName: 'Rohan Deshmukh',
        ownerName: 'Amit Joshi',
        reason: 'Minor Scratch on Handle',
        description: 'Owner claimed ₹500 deduction for scratch. Renter states it was present during initial handover.',
        status: DisputeStatus.open,
        amountInvolved: 500.0,
        createdAt: DateTime.now().subtract(const Duration(hours: 18)),
      ),
    ];
  }
}
