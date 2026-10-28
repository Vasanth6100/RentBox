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
    _initCurrentUser();
    initAndSync();
  }

  Future<void> initAndSync() async {
    await ApiService.instance.checkHealth();
    await syncWithBackend();
  }

  Future<void> syncWithBackend() async {
    try {
      _listings = await ApiService.instance.getListings();
      _bookings = await ApiService.instance.getBookings();
      _disputes = await ApiService.instance.getDisputes();

      if (_currentUser.id.isNotEmpty) {
        _notifications = await ApiService.instance.getNotifications(_currentUser.id);
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
      _listings.where((l) =>
          l.status != ListingStatus.rejected &&
          l.status != ListingStatus.paused &&
          l.status != ListingStatus.pendingApproval).toList();
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
    syncWithBackend();
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

  void logout() {
    ApiService.instance.authToken = null;
    _currentUser = UserModel(
      id: '',
      name: 'Guest User',
      email: '',
      phone: '',
      avatarUrl: 'assets/images/avatar.jpg',
      location: 'Mumbai, Maharashtra',
      activeRole: UserRole.customer,
      joinedDate: DateTime.now(),
      favoriteListingIds: [],
    );
    notifyListeners();
    syncWithBackend();
  }

  // --- Listings Operations ---
  Future<ListingModel?> addListing(ListingModel listing) async {
    final activeListing = listing.copyWith(status: ListingStatus.active);

    // 1. Post directly to central backend to persist to database
    ListingModel? backendCreated;
    try {
      backendCreated = await ApiService.instance.createListing(activeListing);
    } catch (e) {
      debugPrint('AppStore.addListing backend error: $e');
    }

    final finalListing = backendCreated ?? activeListing;

    final existingIdx = _listings.indexWhere((l) => l.id == finalListing.id || l.id == listing.id);
    if (existingIdx != -1) {
      _listings[existingIdx] = finalListing;
    } else {
      _listings.insert(0, finalListing);
    }

    _addNotification(
      title: 'Item Listed Live! ðŸŽ‰',
      message: '"${finalListing.title}" is now published and live for everyone on RentBox.',
      type: NotificationType.booking,
    );
    notifyListeners();

    // 2. Refresh store from global shared database
    await syncWithBackend();
    return finalListing;
  }

  void approveListing(String listingId) {
    final index = _listings.indexWhere((l) => l.id == listingId);
    if (index != -1) {
      _listings[index] = _listings[index].copyWith(
        status: ListingStatus.active,
        rejectionReason: null,
      );
      _addNotification(
        title: 'Listing Approved! ðŸŽ‰',
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
  Future<BookingModel> createBooking({
    required ListingModel listing,
    required DateTime startDate,
    required DateTime endDate,
    required FulfillmentMethod fulfillmentMethod,
    required ProtectionPlan protectionPlan,
    required String paymentMethod,
  }) async {
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

    final localBooking = BookingModel(
      id: bookingId,
      listingId: listing.id,
      listingTitle: listing.title,
      listingImage: listing.imageUrls.isNotEmpty ? listing.imageUrls.first : 'assets/images/camera.jpg',
      renterId: _currentUser.id.isNotEmpty ? _currentUser.id : 'USER-1',
      renterName: _currentUser.name.isNotEmpty ? _currentUser.name : 'Verified Customer',
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

    // Save to central backend database
    BookingModel? backendBooking;
    try {
      backendBooking = await ApiService.instance.createBooking(localBooking);
    } catch (e) {
      debugPrint('AppStore.createBooking backend error: $e');
    }

    final confirmedBooking = backendBooking ?? localBooking;

    final existingIdx = _bookings.indexWhere((b) => b.id == confirmedBooking.id || b.id == localBooking.id);
    if (existingIdx != -1) {
      _bookings[existingIdx] = confirmedBooking;
    } else {
      _bookings.insert(0, confirmedBooking);
    }

    _addNotification(
      title: 'Booking Confirmed! ðŸ“¦',
      message: 'Your rental for "${listing.title}" is booked. Pickup Code: ${confirmedBooking.pickupCode}',
      type: NotificationType.booking,
    );

    notifyListeners();
    await syncWithBackend();
    return confirmedBooking;
  }

  void cancelBooking(String bookingId) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(
        status: BookingStatus.cancelled,
        paymentStatus: 'Refunded (â‚¹${_bookings[index].totalPayable.toStringAsFixed(0)})',
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
        title: 'Rental Completed & Deposit Returned ðŸ›¡ï¸',
        message: 'Security deposit of â‚¹${_bookings[index].securityDeposit.toStringAsFixed(0)} returned to source account.',
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
          title: 'Rental Completed & Deposit Returned ðŸ›¡ï¸',
          message: 'Security deposit of â‚¹${_bookings[index].securityDeposit.toStringAsFixed(0)} returned.',
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

  // --- Initialize Guest User (no dummy data) ---
  void _initCurrentUser() {
    _currentUser = UserModel(
      id: '',
      name: 'Guest User',
      email: '',
      phone: '',
      avatarUrl: 'assets/images/avatar.jpg',
      location: 'Mumbai, Maharashtra',
      activeRole: UserRole.customer,
      joinedDate: DateTime.now(),
      favoriteListingIds: [],
    );

    _listings = [];
    _bookings = [];
    _reviews = [];
    _notifications = [];
    _disputes = [];
  }
}

