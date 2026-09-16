class Receipt {
  final String id; // This is the receipt number (e.g., RCPT-XXXXXX)
  final String contributionId;
  final String campaignName;
  final String memberName;
  final double amount;
  final String paymentMethod;
  final String? transferReference;
  final String? receivedBy;
  final DateTime paymentDate;
  final DateTime verifiedAt;

  const Receipt({
    required this.id,
    required this.contributionId,
    required this.campaignName,
    required this.memberName,
    required this.amount,
    required this.paymentMethod,
    this.transferReference,
    this.receivedBy,
    required this.paymentDate,
    required this.verifiedAt,
  });

  factory Receipt.fromMap(Map<String, dynamic> map, String id) {
    return Receipt(
      id: id,
      contributionId: map['contributionId'] as String? ?? '',
      campaignName: map['campaignName'] as String? ?? '',
      memberName: map['memberName'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] as String? ?? '',
      transferReference: map['transferReference'] as String?,
      receivedBy: map['receivedBy'] as String?,
      paymentDate: map['paymentDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['paymentDate'] as int)
          : DateTime.now(),
      verifiedAt: map['verifiedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['verifiedAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contributionId': contributionId,
      'campaignName': campaignName,
      'memberName': memberName,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'transferReference': transferReference,
      'receivedBy': receivedBy,
      'paymentDate': paymentDate.millisecondsSinceEpoch,
      'verifiedAt': verifiedAt.millisecondsSinceEpoch,
    };
  }
}
