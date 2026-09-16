// ignore_for_file: constant_identifier_names

enum PaymentMethod { CASH, BANK_TRANSFER }

enum ContributionStatus {
  PENDING_VERIFICATION,
  VERIFIED,
  REJECTED,
}

class Contribution {
  final String id;
  final String campaignId;
  final String pledgeId;
  final String userId;

  // Payment Details
  final double amount;
  final PaymentMethod paymentMethod;
  final DateTime paymentDate;
  final String? note;
  final String? receivedBy; // Full name of person cash was given to

  // Bank transfer extras
  final String? bankName;
  final String? transferReference;
  final String? proofUrl; // Firebase Storage URL

  // Verification
  final ContributionStatus status;
  final String? verifiedBy; // Admin UID
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final String? receiptId;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Contribution({
    required this.id,
    required this.campaignId,
    required this.pledgeId,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    this.note,
    this.receivedBy,
    this.bankName,
    this.transferReference,
    this.proofUrl,
    required this.status,
    this.verifiedBy,
    this.verifiedAt,
    this.rejectionReason,
    this.receiptId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == ContributionStatus.PENDING_VERIFICATION;
  bool get isVerified => status == ContributionStatus.VERIFIED;
  bool get isRejected => status == ContributionStatus.REJECTED;

  factory Contribution.fromMap(Map<String, dynamic> map, String id) {
    return Contribution(
      id: id,
      campaignId: map['campaignId'] as String? ?? '',
      pledgeId: map['pledgeId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.CASH,
      ),
      paymentDate: map['paymentDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['paymentDate'] as int)
          : DateTime.now(),
      note: map['note'] as String?,
      receivedBy: map['receivedBy'] as String?,
      bankName: map['bankName'] as String?,
      transferReference: map['transferReference'] as String?,
      proofUrl: map['proofUrl'] as String?,
      status: ContributionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ContributionStatus.PENDING_VERIFICATION,
      ),
      verifiedBy: map['verifiedBy'] as String?,
      verifiedAt: map['verifiedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['verifiedAt'] as int)
          : null,
      rejectionReason: map['rejectionReason'] as String?,
      receiptId: map['receiptId'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'campaignId': campaignId,
      'pledgeId': pledgeId,
      'userId': userId,
      'amount': amount,
      'paymentMethod': paymentMethod.name,
      'paymentDate': paymentDate.millisecondsSinceEpoch,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };

    if (note != null && note!.isNotEmpty) map['note'] = note;
    if (receivedBy != null && receivedBy!.isNotEmpty) {
      map['receivedBy'] = receivedBy;
    }
    if (bankName != null && bankName!.isNotEmpty) map['bankName'] = bankName;
    if (transferReference != null && transferReference!.isNotEmpty) {
      map['transferReference'] = transferReference;
    }
    if (proofUrl != null && proofUrl!.isNotEmpty) map['proofUrl'] = proofUrl;
    if (verifiedBy != null) map['verifiedBy'] = verifiedBy;
    if (verifiedAt != null) map['verifiedAt'] = verifiedAt!.millisecondsSinceEpoch;
    if (rejectionReason != null && rejectionReason!.isNotEmpty) {
      map['rejectionReason'] = rejectionReason;
    }
    if (receiptId != null && receiptId!.isNotEmpty) map['receiptId'] = receiptId;

    return map;
  }

  Contribution copyWith({
    ContributionStatus? status,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? rejectionReason,
    String? receiptId,
    String? proofUrl,
    String? receivedBy,
    DateTime? updatedAt,
  }) {
    return Contribution(
      id: id,
      campaignId: campaignId,
      pledgeId: pledgeId,
      userId: userId,
      amount: amount,
      paymentMethod: paymentMethod,
      paymentDate: paymentDate,
      note: note,
      receivedBy: receivedBy ?? this.receivedBy,
      bankName: bankName,
      transferReference: transferReference,
      proofUrl: proofUrl ?? this.proofUrl,
      status: status ?? this.status,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      receiptId: receiptId ?? this.receiptId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
