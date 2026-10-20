enum BookingStatus { upcoming, active, completed, cancelled }
enum FulfillmentMethod { selfPickup, ownerDelivery }
enum ProtectionPlan { standard, basic, none }

class BookingModel {
  final String id;
  final String listingId;
  final String listingTitle;
  final String listingImage;
  final String renterId;
  final String renterName;
  final String ownerId;
  final String ownerName;
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;
  final FulfillmentMethod fulfillmentMethod;
  final ProtectionPlan protectionPlan;
  final double dailyRate;
  final double rentalFee;
  final double securityDeposit;
  final double deliveryFee;
  final double protectionFee;
  final double taxes;
  final double totalPayable;
  final BookingStatus status;
  final String pickupCode;
  final String paymentMethod;
  final String paymentStatus;
  final String location;
  final DateTime createdAt;
  final bool isReviewed;

  const BookingModel({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.listingImage,
    required this.renterId,
    required this.renterName,
    required this.ownerId,
    required this.ownerName,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    this.fulfillmentMethod = FulfillmentMethod.selfPickup,
    this.protectionPlan = ProtectionPlan.standard,
    required this.dailyRate,
    required this.rentalFee,
    required this.securityDeposit,
    this.deliveryFee = 0.0,
    this.protectionFee = 99.0,
    this.taxes = 0.0,
    required this.totalPayable,
    this.status = BookingStatus.upcoming,
    required this.pickupCode,
    this.paymentMethod = 'UPI / GPay',
    this.paymentStatus = 'Paid',
    required this.location,
    required this.createdAt,
    this.isReviewed = false,
  });

  BookingModel copyWith({
    String? id,
    String? listingId,
    String? listingTitle,
    String? listingImage,
    String? renterId,
    String? renterName,
    String? ownerId,
    String? ownerName,
    DateTime? startDate,
    DateTime? endDate,
    int? durationDays,
    FulfillmentMethod? fulfillmentMethod,
    ProtectionPlan? protectionPlan,
    double? dailyRate,
    double? rentalFee,
    double? securityDeposit,
    double? deliveryFee,
    double? protectionFee,
    double? taxes,
    double? totalPayable,
    BookingStatus? status,
    String? pickupCode,
    String? paymentMethod,
    String? paymentStatus,
    String? location,
    DateTime? createdAt,
    bool? isReviewed,
  }) {
    return BookingModel(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
      listingImage: listingImage ?? this.listingImage,
      renterId: renterId ?? this.renterId,
      renterName: renterName ?? this.renterName,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationDays: durationDays ?? this.durationDays,
      fulfillmentMethod: fulfillmentMethod ?? this.fulfillmentMethod,
      protectionPlan: protectionPlan ?? this.protectionPlan,
      dailyRate: dailyRate ?? this.dailyRate,
      rentalFee: rentalFee ?? this.rentalFee,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      protectionFee: protectionFee ?? this.protectionFee,
      taxes: taxes ?? this.taxes,
      totalPayable: totalPayable ?? this.totalPayable,
      status: status ?? this.status,
      pickupCode: pickupCode ?? this.pickupCode,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      isReviewed: isReviewed ?? this.isReviewed,
    );
  }
}
