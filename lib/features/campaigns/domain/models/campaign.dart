// ignore_for_file: constant_identifier_names

enum CampaignStatus { DRAFT, ACTIVE, PAUSED, COMPLETED, ARCHIVED }

class Campaign {
  final String id;
  final String name;
  final String description;
  final double targetAmount;
  final DateTime startDate;
  final DateTime endDate;
  final CampaignStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Denormalized stats for fast querying
  final double totalPledged;
  final double totalVerified;
  final int participantsCount;

  const Campaign({
    required this.id,
    required this.name,
    required this.description,
    required this.targetAmount,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.totalPledged = 0.0,
    this.totalVerified = 0.0,
    this.participantsCount = 0,
  });

  factory Campaign.fromMap(Map<String, dynamic> map, String id) {
    return Campaign(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0.0,
      startDate: map['startDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int)
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endDate'] as int)
          : DateTime.now().add(const Duration(days: 30)),
      status: CampaignStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CampaignStatus.DRAFT,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : DateTime.now(),
      totalPledged: (map['totalPledged'] as num?)?.toDouble() ?? 0.0,
      totalVerified: (map['totalVerified'] as num?)?.toDouble() ?? 0.0,
      participantsCount: (map['participantsCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'targetAmount': targetAmount,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'totalPledged': totalPledged,
      'totalVerified': totalVerified,
      'participantsCount': participantsCount,
    };
  }

  Campaign copyWith({
    String? name,
    String? description,
    double? targetAmount,
    DateTime? startDate,
    DateTime? endDate,
    CampaignStatus? status,
    DateTime? updatedAt,
    double? totalPledged,
    double? totalVerified,
    int? participantsCount,
  }) {
    return Campaign(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalPledged: totalPledged ?? this.totalPledged,
      totalVerified: totalVerified ?? this.totalVerified,
      participantsCount: participantsCount ?? this.participantsCount,
    );
  }

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return (totalVerified / targetAmount).clamp(0.0, 1.0);
  }
}
