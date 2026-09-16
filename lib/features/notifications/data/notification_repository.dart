import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../domain/models/app_notification.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('notifications');

  // Fetch user-specific notifications (simple query, no composite index needed)
  Stream<List<AppNotification>> _userStream(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AppNotification.fromMap(d.data(), d.id)).toList());
  }

  // Fetch broadcast notifications (simple query, no composite index needed)
  Stream<List<AppNotification>> _broadcastStream() {
    return _collection
        .where('userId', isEqualTo: 'ALL')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AppNotification.fromMap(d.data(), d.id)).toList());
  }

  /// Merges user-specific + broadcast notifications client-side.
  /// No composite index required — each sub-query only uses a single field.
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return Rx.combineLatest2(
      _userStream(userId),
      _broadcastStream(),
      (List<AppNotification> user, List<AppNotification> broadcast) {
        final merged = {...user, ...broadcast}.toList();
        merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return merged.take(50).toList();
      },
    );
  }

  // Keep old name as alias for backwards compatibility
  Stream<List<AppNotification>> watchUserNotifications(String userId) =>
      watchNotifications(userId);

  Future<void> markAsRead(String notificationId) async {
    await _collection.doc(notificationId).update({'isRead': true});
  }
  
  Future<void> markAllAsRead(String userId) async {
    final snap = await _collection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
        
    final batch = _firestore.batch();
    for (var doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> sendAnnouncement({
    required String title,
    required String body,
    required String targetType, // 'ALL', 'CAMPAIGN', 'GROUP'
    String? targetId,
  }) async {
    // If targetType is ALL, we can write one notification with userId='ALL'.
    // Or we could trigger a Cloud Function to fan-out.
    // Here we'll just write the doc and let the client read it via `whereIn: [uid, 'ALL']`.
    
    if (targetType == 'ALL') {
      await _collection.add(AppNotification(
        id: '',
        userId: 'ALL',
        title: title,
        body: body,
        type: NotificationType.ANNOUNCEMENT,
        isRead: false,
        createdAt: DateTime.now(),
      ).toMap());
    } else if (targetType == 'CAMPAIGN') {
      // Stored with userId='CAMPAIGN_<id>' so queries can target campaign participants.
      await _collection.add(AppNotification(
        id: '',
        userId: 'CAMPAIGN_$targetId',
        title: title,
        body: body,
        type: NotificationType.ANNOUNCEMENT,
        isRead: false,
        createdAt: DateTime.now(),
      ).toMap());
    } else if (targetType == 'GROUP' && targetId != null) {
      // Stored with userId='GROUP_<id>' for custom group targeting.
      await _collection.add(AppNotification(
        id: '',
        userId: 'GROUP_$targetId',
        title: title,
        body: body,
        type: NotificationType.ANNOUNCEMENT,
        isRead: false,
        createdAt: DateTime.now(),
      ).toMap());
    }
  }

  // Admin function to send a specific notification
  Future<void> sendNotification(AppNotification notification) async {
    await _collection.add(notification.toMap());
  }
}
