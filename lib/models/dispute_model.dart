enum DisputeStatus { open, underReview, resolved, dismissed }

class DisputeCaseModel {
  final String id;
  final String caseId;
  final String bookingId;
  final String itemTitle;
  final String renterName;
  final String ownerName;
  final String reason;
  final String description;
  final DisputeStatus status;
  final double amountInvolved;
  final DateTime createdAt;
  final String? resolution;
  final String? adminNotes;

  const DisputeCaseModel({
    required this.id,
    required this.caseId,
    required this.bookingId,
    required this.itemTitle,
    required this.renterName,
    required this.ownerName,
    required this.reason,
    required this.description,
    this.status = DisputeStatus.open,
    this.amountInvolved = 0.0,
    required this.createdAt,
    this.resolution,
    this.adminNotes,
  });

  DisputeCaseModel copyWith({
    String? id,
    String? caseId,
    String? bookingId,
    String? itemTitle,
    String? renterName,
    String? ownerName,
    String? reason,
    String? description,
    DisputeStatus? status,
    double? amountInvolved,
    DateTime? createdAt,
    String? resolution,
    String? adminNotes,
  }) {
    return DisputeCaseModel(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      bookingId: bookingId ?? this.bookingId,
      itemTitle: itemTitle ?? this.itemTitle,
      renterName: renterName ?? this.renterName,
      ownerName: ownerName ?? this.ownerName,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      amountInvolved: amountInvolved ?? this.amountInvolved,
      createdAt: createdAt ?? this.createdAt,
      resolution: resolution ?? this.resolution,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }
}
