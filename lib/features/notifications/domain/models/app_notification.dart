
enum NotificationType {
  PAYMENT_SUBMITTED,
  PAYMENT_VERIFIED,
  PAYMENT_REJECTED,
  PLEDGE_CREATED,
  PLEDGE_REMINDER,
  CAMPAIGN_MILESTONE,
  CAMPAIGN_COMPLETED,
  ANNOUNCEMENT,
}

class AppNotification {
  final String id;
  final String userId; // Or "ALL", "CAMPAIGN_ID" for group
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.data,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.ANNOUNCEMENT,
      ),
      isRead: map['isRead'] as bool? ?? false,
      data: map['data'] as Map<String, dynamic>?,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'isRead': isRead,
      'data': data,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  AppNotification copyWith({
    bool? isRead,
  }) {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      data: data,
      createdAt: createdAt,
    );
  }
}
