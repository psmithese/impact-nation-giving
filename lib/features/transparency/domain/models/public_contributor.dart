class PublicContributor {
  final String id; // usually pledgeId
  final String userId;
  final String campaignId;
  final String searchableName; // lowercase name for prefix search

  // Dynamically populated fields based on VisibilitySettings
  final String? memberName;
  final String? photoUrl;
  final String? department;
  final double? pledgedAmount;
  final double? amountPaid;
  final double? outstandingBalance;
  final String? status; // NO_PLEDGE, PLEDGED, PARTIAL_PAYMENT, FULLY_PAID
  final DateTime? lastPaymentDate;
  final List<PublicPayment>? paymentHistory;

  const PublicContributor({
    required this.id,
    required this.userId,
    required this.campaignId,
    required this.searchableName,
    this.memberName,
    this.photoUrl,
    this.department,
    this.pledgedAmount,
    this.amountPaid,
    this.outstandingBalance,
    this.status,
    this.lastPaymentDate,
    this.paymentHistory,
  });

  factory PublicContributor.fromMap(Map<String, dynamic> map, String id) {
    return PublicContributor(
      id: id,
      userId: map['userId'] as String? ?? '',
      campaignId: map['campaignId'] as String? ?? '',
      searchableName: map['searchableName'] as String? ?? '',
      memberName: map['memberName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      department: map['department'] as String?,
      pledgedAmount: (map['pledgedAmount'] as num?)?.toDouble(),
      amountPaid: (map['amountPaid'] as num?)?.toDouble(),
      outstandingBalance: (map['outstandingBalance'] as num?)?.toDouble(),
      status: map['status'] as String?,
      lastPaymentDate: map['lastPaymentDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastPaymentDate'] as int)
          : null,
      paymentHistory: (map['paymentHistory'] as List?)
          ?.map((e) => PublicPayment.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'campaignId': campaignId,
      'searchableName': searchableName,
      if (memberName != null) 'memberName': memberName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (department != null) 'department': department,
      if (pledgedAmount != null) 'pledgedAmount': pledgedAmount,
      if (amountPaid != null) 'amountPaid': amountPaid,
      if (outstandingBalance != null) 'outstandingBalance': outstandingBalance,
      if (status != null) 'status': status,
      if (lastPaymentDate != null)
        'lastPaymentDate': lastPaymentDate!.millisecondsSinceEpoch,
      if (paymentHistory != null)
        'paymentHistory': paymentHistory!.map((e) => e.toMap()).toList(),
    };
  }
}

class PublicPayment {
  final double amount;
  final DateTime date;

  const PublicPayment({required this.amount, required this.date});

  factory PublicPayment.fromMap(Map<String, dynamic> map) {
    return PublicPayment(
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
    };
  }
}
