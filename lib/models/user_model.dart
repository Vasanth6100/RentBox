enum UserRole { customer, owner, admin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final String location;
  final bool isVerified;
  final bool isKycApproved;
  final UserRole activeRole;
  final DateTime joinedDate;
  final double rating;
  final int reviewsCount;
  final List<String> favoriteListingIds;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.location,
    this.isVerified = true,
    this.isKycApproved = true,
    this.activeRole = UserRole.customer,
    required this.joinedDate,
    this.rating = 4.9,
    this.reviewsCount = 42,
    this.favoriteListingIds = const [],
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? location,
    bool? isVerified,
    bool? isKycApproved,
    UserRole? activeRole,
    DateTime? joinedDate,
    double? rating,
    int? reviewsCount,
    List<String>? favoriteListingIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      location: location ?? this.location,
      isVerified: isVerified ?? this.isVerified,
      isKycApproved: isKycApproved ?? this.isKycApproved,
      activeRole: activeRole ?? this.activeRole,
      joinedDate: joinedDate ?? this.joinedDate,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      favoriteListingIds: favoriteListingIds ?? this.favoriteListingIds,
    );
  }
}
