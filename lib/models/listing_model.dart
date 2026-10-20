enum ListingStatus { pendingApproval, active, rejected, paused }

class ListingModel {
  final String id;
  final String title;
  final String category; // Cameras, Gaming, Projectors, Audio, Tech, Outdoor
  final double pricePerDay;
  final double securityDeposit;
  final String brand;
  final String modelName;
  final String condition; // Like New, Excellent, Good
  final String description;
  final Map<String, String> specifications;
  final List<String> includedItems;
  final List<String> imageUrls;
  final String location;
  final double distanceKm;
  final String ownerId;
  final String ownerName;
  final String ownerAvatar;
  final double ownerRating;
  final String ownerResponseTime;
  final bool isOwnerVerified;
  final ListingStatus status;
  final String? rejectionReason;
  final bool hasBill;
  final bool hasSerialVerified;
  final bool hasIdVerified;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final double rating;
  final int reviewsCount;
  final double deliveryCharge;
  final bool isDeliveryAvailable;

  const ListingModel({
    required this.id,
    required this.title,
    required this.category,
    required this.pricePerDay,
    required this.securityDeposit,
    required this.brand,
    required this.modelName,
    required this.condition,
    required this.description,
    this.specifications = const {},
    this.includedItems = const [],
    required this.imageUrls,
    required this.location,
    this.distanceKm = 2.0,
    required this.ownerId,
    required this.ownerName,
    required this.ownerAvatar,
    this.ownerRating = 4.9,
    this.ownerResponseTime = 'Replies in 15 mins',
    this.isOwnerVerified = true,
    this.status = ListingStatus.active,
    this.rejectionReason,
    this.hasBill = true,
    this.hasSerialVerified = true,
    this.hasIdVerified = true,
    this.latitude = 19.0760,
    this.longitude = 72.8777,
    required this.createdAt,
    this.rating = 4.8,
    this.reviewsCount = 24,
    this.deliveryCharge = 150.0,
    this.isDeliveryAvailable = true,
  });

  String get priceDisplay => '₹${pricePerDay.toStringAsFixed(0)}';

  ListingModel copyWith({
    String? id,
    String? title,
    String? category,
    double? pricePerDay,
    double? securityDeposit,
    String? brand,
    String? modelName,
    String? condition,
    String? description,
    Map<String, String>? specifications,
    List<String>? includedItems,
    List<String>? imageUrls,
    String? location,
    double? distanceKm,
    String? ownerId,
    String? ownerName,
    String? ownerAvatar,
    double? ownerRating,
    String? ownerResponseTime,
    bool? isOwnerVerified,
    ListingStatus? status,
    String? rejectionReason,
    bool? hasBill,
    bool? hasSerialVerified,
    bool? hasIdVerified,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    double? rating,
    int? reviewsCount,
    double? deliveryCharge,
    bool? isDeliveryAvailable,
  }) {
    return ListingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      brand: brand ?? this.brand,
      modelName: modelName ?? this.modelName,
      condition: condition ?? this.condition,
      description: description ?? this.description,
      specifications: specifications ?? this.specifications,
      includedItems: includedItems ?? this.includedItems,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      distanceKm: distanceKm ?? this.distanceKm,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerAvatar: ownerAvatar ?? this.ownerAvatar,
      ownerRating: ownerRating ?? this.ownerRating,
      ownerResponseTime: ownerResponseTime ?? this.ownerResponseTime,
      isOwnerVerified: isOwnerVerified ?? this.isOwnerVerified,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      hasBill: hasBill ?? this.hasBill,
      hasSerialVerified: hasSerialVerified ?? this.hasSerialVerified,
      hasIdVerified: hasIdVerified ?? this.hasIdVerified,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      isDeliveryAvailable: isDeliveryAvailable ?? this.isDeliveryAvailable,
    );
  }
}
