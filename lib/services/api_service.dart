import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/listing_model.dart';
import '../models/booking_model.dart';
import '../models/user_model.dart';
import '../models/dispute_model.dart';
import '../models/notification_model.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  factory ApiService() => instance;
  ApiService._internal();

  /// Returns the current active API base URL (delegated to central ApiConfig)
  String get baseUrl => ApiConfig.baseUrl;

  /// Returns the base server root without '/api'
  String get serverRootUrl => ApiConfig.serverRootUrl;

  /// Whether running in production
  bool get isProduction => ApiConfig.isProduction;

  String? authToken;

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  // --- Health Check ---
  Future<bool> checkHealth() async {
    // 1. Try currently configured baseUrl
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(milliseconds: 1500));
      if (res.statusCode == 200) return true;
    } catch (_) {}

    // 2. Proactively probe candidate working endpoints in order
    final candidates = <String>[
      if (defaultTargetPlatform == TargetPlatform.android) 'http://10.0.2.2:5000/api',
      if (defaultTargetPlatform == TargetPlatform.android) 'http://10.253.0.168:5000/api',
      'http://localhost:5000/api',
      ApiConfig.defaultProductionApiUrl,
    ];

    for (final candidate in candidates) {
      if (candidate == baseUrl) continue;
      try {
        final res = await http
            .get(Uri.parse('$candidate/health'))
            .timeout(const Duration(milliseconds: 1500));
        if (res.statusCode == 200) {
          ApiConfig.runtimeBaseUrlOverride = candidate;
          debugPrint('[RentBox API] Connected to live backend at: $candidate');
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  String? lastLoginError;
  String? lastRegisterError;

  // --- Auth & Users ---
  Future<UserModel?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'customer',
    String location = 'Mumbai, Maharashtra',
  }) async {
    lastRegisterError = null;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'role': role,
          'location': location,
        }),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
        if (data['token'] != null) {
          authToken = data['token'] as String;
        }
        return _userFromJson(data['user'] as Map<String, dynamic>);
      } else {
        lastRegisterError = data['error'] as String? ?? 'Registration failed. Please try again.';
      }
    } catch (e) {
      debugPrint('ApiService.register error: $e');
      lastRegisterError = 'Could not connect to backend server: $e';
    }
    return null;
  }

  Future<UserModel?> login({String? emailPhone, String? password}) async {
    lastLoginError = null;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: headers,
        body: jsonEncode({'emailPhone': emailPhone, 'password': password}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        if (data['token'] != null) {
          authToken = data['token'] as String;
        }
        return _userFromJson(data['user'] as Map<String, dynamic>);
      } else {
        lastLoginError = data['error'] as String? ?? 'Invalid email or password.';
      }
    } catch (e) {
      debugPrint('ApiService.login error: $e');
      lastLoginError = 'Could not connect to backend server: $e';
    }
    return null;
  }

  Future<Map<String, dynamic>> requestPasswordReset({
    required String emailOrPhone,
    required bool isEmail,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (isEmail) 'email': emailOrPhone else 'phone': emailOrPhone,
        }),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      debugPrint('ApiService.requestPasswordReset error: $e');
      return {'success': false, 'error': 'Could not connect to server.'};
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String emailOrPhone,
    required bool isEmail,
    required String code,
    required String newPassword,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (isEmail) 'email': emailOrPhone else 'phone': emailOrPhone,
          'code': code,
          'newPassword': newPassword,
        }),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      debugPrint('ApiService.resetPassword error: $e');
      return {'success': false, 'error': 'Could not connect to server: $e'};
    }
  }

  Future<List<Map<String, dynamic>>> getKycApplicants() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/admin/kyc/applicants'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint('ApiService.getKycApplicants error: $e');
    }
    return [];
  }

  Future<bool> updateKycStatus({
    required String userId,
    required String status,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/admin/users/$userId/kyc'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.updateKycStatus error: $e');
      return false;
    }
  }

  // Dedicated Admin Authentication Verified with Backend
  Future<Map<String, dynamic>?> adminLogin({
    required String identifier,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/admin-login'),
        headers: headers,
        body: jsonEncode({
          'emailPhone': identifier,
          'password': password,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['token'] != null) {
          authToken = data['token'] as String;
        }
        return data;
      } else {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {'success': false, 'error': data['error'] ?? 'Authentication failed'};
      }
    } catch (e) {
      debugPrint('ApiService.adminLogin error: $e');
      return {'success': false, 'error': 'Could not connect to backend server: $e'};
    }
  }

  Future<Map<String, dynamic>?> getAdminMetrics() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/admin/metrics'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiService.getAdminMetrics error: $e');
    }
    return null;
  }

  Future<UserModel?> getCurrentUser(String userId) async {
    try {
      final res =
          await http.get(Uri.parse('$baseUrl/users/current?userId=$userId'));
      if (res.statusCode == 200) {
        return _userFromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('ApiService.getCurrentUser error: $e');
    }
    return null;
  }

  Future<UserModel?> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? location,
    String? avatarUrl,
  }) async {
    try {
      final payload = <String, dynamic>{'userId': userId};
      if (name != null) payload['name'] = name;
      if (phone != null) payload['phone'] = phone;
      if (location != null) payload['location'] = location;
      if (avatarUrl != null) payload['avatarUrl'] = avatarUrl;

      final res = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['user'] != null) {
          return _userFromJson(data['user'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('ApiService.updateProfile error: $e');
    }
    return null;
  }

  Future<String?> uploadImage(Uint8List bytes, {String filename = 'photo.jpg'}) async {
    try {
      final base64Data = base64Encode(bytes);
      final res = await http.post(
        Uri.parse('$baseUrl/upload'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Data,
          'filename': filename,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final url = data['url'] as String?;
        final fullUrl = data['fullUrl'] as String?;
        return url ?? fullUrl;
      }
    } catch (e) {
      debugPrint('ApiService.uploadImage error: $e');
    }
    return null;
  }

  Future<bool> toggleFavorite(String userId, String listingId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/users/favorites/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'listingId': listingId}),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.toggleFavorite error: $e');
      return false;
    }
  }

  // --- Listings ---
  Future<List<ListingModel>> getListings(
      {String? category, String? status, String? search, String? userId}) async {
    try {
      final params = <String, String>{};
      if (category != null && category != 'All') params['category'] = category;
      if (status != null) params['status'] = status;
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (userId != null && userId.isNotEmpty) params['userId'] = userId;

      final uri = Uri.parse('$baseUrl/listings')
          .replace(queryParameters: params.isNotEmpty ? params : null);
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body) as List;
        return list
            .map((json) => _listingFromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('ApiService.getListings error: $e');
    }
    return [];
  }

  Future<ListingModel?> createListing(ListingModel listing) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/listings'),
        headers: headers,
        body: jsonEncode({
          'id': listing.id,
          'title': listing.title,
          'category': listing.category,
          'pricePerDay': listing.pricePerDay,
          'securityDeposit': listing.securityDeposit,
          'brand': listing.brand,
          'modelName': listing.modelName,
          'condition': listing.condition,
          'location': listing.location,
          'description': listing.description,
          'features': <String>[],
          'includedAccessories': listing.includedItems,
          'imageUrls': listing.imageUrls,
          'ownerId': listing.ownerId,
          'ownerName': listing.ownerName,
          'ownerAvatar': listing.ownerAvatar,
          'ownerRating': listing.ownerRating,
          'ownerReviewsCount': listing.reviewsCount,
          'isInstantBooking': listing.isDeliveryAvailable,
          'deliveryCharge': listing.deliveryCharge,
          'minRentDays': 1,
          'maxRentDays': 30,
          'status': 'active',
          'createdAt': listing.createdAt.toIso8601String(),
        }),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return _listingFromJson(
            jsonDecode(res.body) as Map<String, dynamic>);
      } else {
        debugPrint('ApiService.createListing failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('ApiService.createListing error: $e');
    }
    return null;
  }

  Future<bool> approveListing(String listingId) async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl/listings/$listingId/approve'));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.approveListing error: $e');
      return false;
    }
  }

  Future<bool> rejectListing(String listingId, String reason) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/listings/$listingId/reject'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reason': reason}),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.rejectListing error: $e');
      return false;
    }
  }

  Future<bool> toggleListingPause(String listingId) async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl/listings/$listingId/toggle-pause'));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.toggleListingPause error: $e');
      return false;
    }
  }

  // --- Bookings ---
  Future<List<BookingModel>> getBookings(
      {String? renterId, String? ownerId, String? status}) async {
    try {
      final params = <String, String>{};
      if (renterId != null) params['renterId'] = renterId;
      if (ownerId != null) params['ownerId'] = ownerId;
      if (status != null) params['status'] = status;

      final uri = Uri.parse('$baseUrl/bookings')
          .replace(queryParameters: params.isNotEmpty ? params : null);
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body) as List;
        return list
            .map((json) => _bookingFromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('ApiService.getBookings error: $e');
    }
    return [];
  }

  Future<BookingModel?> createBooking(BookingModel booking) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: headers,
        body: jsonEncode({
          'id': booking.id,
          'listingId': booking.listingId,
          'listingTitle': booking.listingTitle,
          'listingImage': booking.listingImage,
          'renterId': booking.renterId,
          'renterName': booking.renterName,
          'ownerId': booking.ownerId,
          'ownerName': booking.ownerName,
          'startDate': booking.startDate.toIso8601String(),
          'endDate': booking.endDate.toIso8601String(),
          'durationDays': booking.durationDays,
          'fulfillmentMethod': booking.fulfillmentMethod.name,
          'protectionPlan': booking.protectionPlan.name,
          'dailyRate': booking.dailyRate,
          'rentalFee': booking.rentalFee,
          'securityDeposit': booking.securityDeposit,
          'deliveryFee': booking.deliveryFee,
          'protectionFee': booking.protectionFee,
          'taxes': booking.taxes,
          'totalPayable': booking.totalPayable,
          'status': booking.status.name,
          'pickupCode': booking.pickupCode,
          'paymentMethod': booking.paymentMethod,
          'paymentStatus': booking.paymentStatus,
          'location': booking.location,
          'createdAt': booking.createdAt.toIso8601String(),
        }),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return _bookingFromJson(
            jsonDecode(res.body) as Map<String, dynamic>);
      } else {
        debugPrint('ApiService.createBooking failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('ApiService.createBooking error: $e');
    }
    return null;
  }

  Future<bool> updateBookingStatus(String bookingId, String status,
      {String? paymentStatus}) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/bookings/$bookingId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'status': status, 'paymentStatus': paymentStatus}),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.updateBookingStatus error: $e');
      return false;
    }
  }

  // --- Disputes ---
  Future<List<DisputeCaseModel>> getDisputes() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/disputes'));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body) as List;
        return list
            .map((json) => _disputeFromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('ApiService.getDisputes error: $e');
    }
    return [];
  }

  Future<bool> fileDispute({
    required String bookingId,
    required String itemTitle,
    required String ownerName,
    required String renterName,
    required String reason,
    required String description,
    required double amountInvolved,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/disputes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'bookingId': bookingId,
          'itemTitle': itemTitle,
          'ownerName': ownerName,
          'renterName': renterName,
          'reason': reason,
          'description': description,
          'amountInvolved': amountInvolved,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('ApiService.fileDispute error: $e');
      return false;
    }
  }

  Future<bool> resolveDispute(String disputeId, String resolution) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/disputes/$disputeId/resolve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'resolution': resolution}),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.resolveDispute error: $e');
      return false;
    }
  }

  // --- Notifications ---
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/notifications?userId=$userId'));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body) as List;
        return list
            .map((json) =>
                _notificationFromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('ApiService.getNotifications error: $e');
    }
    return [];
  }

  // ---------------------------------------------------------------
  // Model Deserializers (matched to actual ListingModel fields)
  // ---------------------------------------------------------------
  UserModel _userFromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? 'USER-1',
      name: json['name'] as String? ?? 'Alex Johnson',
      email: json['email'] as String? ?? 'alex@rentbox.io',
      phone: json['phone'] as String? ?? '+91 98765 43210',
      activeRole: _roleFromString(json['role'] as String?),
      avatarUrl: json['avatarUrl'] as String? ??
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
      location: json['location'] as String? ?? 'Bandra West, Mumbai',
      isVerified:
          json['isVerified'] == 1 || json['isVerified'] == true,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
      reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 14,
      joinedDate: DateTime.now(),
      favoriteListingIds:
          List<String>.from(json['favoriteListingIds'] as List? ?? []),
    );
  }

  UserRole _roleFromString(String? role) {
    switch (role) {
      case 'owner':
        return UserRole.owner;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.customer;
    }
  }

  ListingModel _listingFromJson(Map<String, dynamic> json) {
    // imageUrls may be stored as JSON string or already a list
    List<String> parseList(dynamic val) {
      if (val == null) return [];
      if (val is List) return List<String>.from(val);
      if (val is String) {
        try {
          return List<String>.from(jsonDecode(val) as List);
        } catch (_) {
          return [];
        }
      }
      return [];
    }

    final status = _listingStatusFromString(json['status'] as String?);

    return ListingModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      pricePerDay:
          (json['pricePerDay'] as num?)?.toDouble() ?? 0.0,
      securityDeposit:
          (json['securityDeposit'] as num?)?.toDouble() ?? 0.0,
      brand: json['brand'] as String? ?? 'Unknown',
      modelName: json['modelName'] as String? ?? '',
      condition: json['condition'] as String? ?? 'Good',
      description: json['description'] as String? ?? '',
      includedItems: parseList(json['includedAccessories']),
      imageUrls: parseList(json['imageUrls']),
      location: json['location'] as String? ?? 'Mumbai',
      ownerId: json['ownerId'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? '',
      ownerAvatar: json['ownerAvatar'] as String? ?? '',
      ownerRating:
          (json['ownerRating'] as num?)?.toDouble() ?? 4.9,
      status: status,
      rejectionReason: json['rejectionReason'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviewsCount:
          (json['ownerReviewsCount'] as num?)?.toInt() ?? 10,
      deliveryCharge:
          (json['deliveryCharge'] as num?)?.toDouble() ?? 0.0,
      isDeliveryAvailable:
          json['isInstantBooking'] == 1 || json['isInstantBooking'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ListingStatus _listingStatusFromString(String? status) {
    switch (status) {
      case 'pendingApproval':
        return ListingStatus.pendingApproval;
      case 'rejected':
        return ListingStatus.rejected;
      case 'paused':
        return ListingStatus.paused;
      default:
        return ListingStatus.active;
    }
  }

  BookingModel _bookingFromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String? ?? '',
      listingId: json['listingId'] as String? ?? '',
      listingTitle: json['listingTitle'] as String? ?? '',
      listingImage: json['listingImage'] as String? ?? '',
      renterId: json['renterId'] as String? ?? '',
      renterName: json['renterName'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? '',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 1,
      fulfillmentMethod: json['fulfillmentMethod'] == 'ownerDelivery'
          ? FulfillmentMethod.ownerDelivery
          : FulfillmentMethod.selfPickup,
      protectionPlan: _planFromString(json['protectionPlan'] as String?),
      dailyRate: (json['dailyRate'] as num?)?.toDouble() ?? 0.0,
      rentalFee: (json['rentalFee'] as num?)?.toDouble() ?? 0.0,
      securityDeposit:
          (json['securityDeposit'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      protectionFee:
          (json['protectionFee'] as num?)?.toDouble() ?? 0.0,
      taxes: (json['taxes'] as num?)?.toDouble() ?? 0.0,
      totalPayable: (json['totalPayable'] as num?)?.toDouble() ?? 0.0,
      status: _bookingStatusFromString(json['status'] as String?),
      pickupCode: json['pickupCode'] as String? ?? 'RB-0000',
      paymentMethod: json['paymentMethod'] as String? ?? 'UPI',
      paymentStatus: json['paymentStatus'] as String? ?? 'Paid',
      location: json['location'] as String? ?? 'Mumbai',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ProtectionPlan _planFromString(String? plan) {
    switch (plan) {
      case 'basic':
        return ProtectionPlan.basic;
      case 'none':
        return ProtectionPlan.none;
      default:
        return ProtectionPlan.standard;
    }
  }

  // BookingStatus uses 'active' not 'ongoing' (from the model enum)
  BookingStatus _bookingStatusFromString(String? status) {
    switch (status) {
      case 'ongoing':
      case 'active':
        return BookingStatus.active;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.upcoming;
    }
  }

  DisputeCaseModel _disputeFromJson(Map<String, dynamic> json) {
    DisputeStatus dstatus;
    switch (json['status'] as String?) {
      case 'resolved':
        dstatus = DisputeStatus.resolved;
        break;
      case 'underReview':
        dstatus = DisputeStatus.underReview;
        break;
      default:
        dstatus = DisputeStatus.open;
    }
    return DisputeCaseModel(
      id: json['id'] as String? ?? '',
      caseId: json['caseId'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      itemTitle: json['itemTitle'] as String? ?? '',
      renterName: json['renterName'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amountInvolved:
          (json['amountInvolved'] as num?)?.toDouble() ?? 0.0,
      status: dstatus,
      resolution: json['resolution'] as String?,
      adminNotes: json['adminNotes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  NotificationModel _notificationFromJson(Map<String, dynamic> json) {
    NotificationType type;
    switch (json['type'] as String?) {
      case 'booking':
        type = NotificationType.booking;
        break;
      case 'security':
        type = NotificationType.security;
        break;
      default:
        type = NotificationType.listingApproval;
    }
    return NotificationModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: type,
      isRead: json['isRead'] == 1 || json['isRead'] == true,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
