class ReviewModel {
  final String id;
  final String listingId;
  final String bookingId;
  final String authorName;
  final String authorAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.listingId,
    required this.bookingId,
    required this.authorName,
    required this.authorAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  ReviewModel copyWith({
    String? id,
    String? listingId,
    String? bookingId,
    String? authorName,
    String? authorAvatar,
    double? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      bookingId: bookingId ?? this.bookingId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
