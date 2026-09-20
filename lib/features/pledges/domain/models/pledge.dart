// ignore_for_file: constant_identifier_names
import 'package:cloud_firestore/cloud_firestore.dart';

enum PledgeStatus {
  NO_PLEDGE,
  PLEDGED,
  PARTIAL_PAYMENT,
  FULLY_PAID,
  CANCELLED
}

class Pledge {
  final String id;
  final String campaignId;
  final String userId;
  final double pledgedAmount;
  final double amountPaid;
  final PledgeStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Pledge({
    required this.id,
    required this.campaignId,
    required this.userId,
    required this.pledgedAmount,
    required this.amountPaid,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  double get outstandingBalance => (pledgedAmount - amountPaid).clamp(0.0, double.infinity);

  /// Status computed securely based on amounts, overriding manual status 
  /// unless it's explicitly cancelled.
  PledgeStatus get computedStatus {
    if (status == PledgeStatus.CANCELLED) return PledgeStatus.CANCELLED;
    if (amountPaid >= pledgedAmount) return PledgeStatus.FULLY_PAID;
    if (amountPaid > 0) return PledgeStatus.PARTIAL_PAYMENT;
    return PledgeStatus.PLEDGED;
  }

  static DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is Timestamp) return val.toDate();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }

  factory Pledge.fromMap(Map<String, dynamic> map, String id) {
    return Pledge(
      id: id,
      campaignId: map['campaignId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      pledgedAmount: (map['pledgedAmount'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      status: PledgeStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PledgeStatus.PLEDGED,
      ),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'campaignId': campaignId,
      'userId': userId,
      'pledgedAmount': pledgedAmount,
      'amountPaid': amountPaid,
      'status': computedStatus.name, // Ensure status is correctly computed when saving
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  Pledge copyWith({
    String? campaignId,
    String? userId,
    double? pledgedAmount,
    double? amountPaid,
    PledgeStatus? status,
    DateTime? updatedAt,
  }) {
    return Pledge(
      id: id,
      campaignId: campaignId ?? this.campaignId,
      userId: userId ?? this.userId,
      pledgedAmount: pledgedAmount ?? this.pledgedAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
