import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../security/data/audit_logger.dart';
import '../data/notification_repository.dart';
import '../domain/models/app_notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

// Provides the list of notifications for the currently logged in user
final userNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final authState = ref.watch(authStateChangesProvider).value;
  if (authState == null) {
    return Stream.value([]);
  }

  final repo = ref.watch(notificationRepositoryProvider);
  return repo.watchNotifications(authState.uid);
});

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    // Request permissions for iOS / Web
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    if (!kIsWeb) {
      // Background message handler must be a top-level function, usually set in main.dart
      // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
          'Message also contained a notification: ${message.notification}',
        );
      }
    });
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService();
});

class NotificationController extends AsyncNotifier<void> {
  late final NotificationRepository _repo;

  @override
  Future<void> build() async {
    _repo = ref.watch(notificationRepositoryProvider);
  }

  Future<void> sendAnnouncement(
    String title,
    String body,
    String targetType, {
    String? targetId,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.sendAnnouncement(
        title: title,
        body: body,
        targetType: targetType,
        targetId: targetId,
      );

      final user = ref.read(authStateChangesProvider).value;
      if (user != null) {
        await AuditLogger.logAction(
          adminId: user.uid,
          action: 'SEND_ANNOUNCEMENT',
          targetId: targetId ?? targetType,
          targetType: 'announcement',
          details: {'title': title, 'targetType': targetType},
        );
      }

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repo.markAsRead(id);
    } catch (e) {
      debugPrint('Failed to mark as read: $e');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _repo.markAllAsRead(userId);
    } catch (e) {
      debugPrint('Failed to mark all as read: $e');
    }
  }
}

final notificationControllerProvider =
    AsyncNotifierProvider<NotificationController, void>(
      NotificationController.new,
    );
