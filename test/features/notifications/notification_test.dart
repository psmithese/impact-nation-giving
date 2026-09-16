import 'package:flutter_test/flutter_test.dart';
import 'package:impact_nation_fund_raising/features/notifications/domain/models/app_notification.dart';

void main() {
  group('AppNotification', () {
    final now = DateTime(2026, 9, 1, 12, 0, 0);

    final notification = AppNotification(
      id: 'notif-1',
      userId: 'user-abc',
      title: 'Payment Verified',
      body: 'Your payment has been verified.',
      type: NotificationType.PAYMENT_VERIFIED,
      isRead: false,
      createdAt: now,
    );

    test('toMap serializes all fields correctly', () {
      final map = notification.toMap();
      expect(map['userId'], 'user-abc');
      expect(map['title'], 'Payment Verified');
      expect(map['body'], 'Your payment has been verified.');
      expect(map['type'], 'PAYMENT_VERIFIED');
      expect(map['isRead'], false);
      expect(map['createdAt'], now.millisecondsSinceEpoch);
    });

    test('fromMap deserializes all fields correctly', () {
      final map = notification.toMap();
      final result = AppNotification.fromMap(map, 'notif-1');
      expect(result.id, 'notif-1');
      expect(result.userId, 'user-abc');
      expect(result.title, 'Payment Verified');
      expect(result.type, NotificationType.PAYMENT_VERIFIED);
      expect(result.isRead, false);
      expect(result.createdAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('fromMap falls back to ANNOUNCEMENT for unknown type', () {
      final map = {
        'userId': 'user-abc',
        'title': 'Test',
        'body': 'Body',
        'type': 'UNKNOWN_TYPE',
        'isRead': false,
        'createdAt': now.millisecondsSinceEpoch,
      };
      final result = AppNotification.fromMap(map, 'notif-2');
      expect(result.type, NotificationType.ANNOUNCEMENT);
    });

    test('fromMap handles missing createdAt gracefully', () {
      final map = {
        'userId': 'user-abc',
        'title': 'Test',
        'body': 'Body',
        'type': 'PLEDGE_CREATED',
        'isRead': true,
      };
      // Should not throw; falls back to DateTime.now()
      expect(() => AppNotification.fromMap(map, 'notif-3'), returnsNormally);
      final result = AppNotification.fromMap(map, 'notif-3');
      expect(result.isRead, true);
      expect(result.type, NotificationType.PLEDGE_CREATED);
    });

    test('copyWith updates isRead and preserves other fields', () {
      final updated = notification.copyWith(isRead: true);
      expect(updated.isRead, true);
      expect(updated.id, notification.id);
      expect(updated.title, notification.title);
      expect(updated.type, notification.type);
    });

    test('all NotificationType values are covered', () {
      // Ensures no type is accidentally missing from the enum
      expect(NotificationType.values.length, 8);
      expect(NotificationType.values, containsAll([
        NotificationType.PAYMENT_SUBMITTED,
        NotificationType.PAYMENT_VERIFIED,
        NotificationType.PAYMENT_REJECTED,
        NotificationType.PLEDGE_CREATED,
        NotificationType.PLEDGE_REMINDER,
        NotificationType.CAMPAIGN_MILESTONE,
        NotificationType.CAMPAIGN_COMPLETED,
        NotificationType.ANNOUNCEMENT,
      ]));
    });
  });
}
