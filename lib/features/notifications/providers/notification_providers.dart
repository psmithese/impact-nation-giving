import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  /// Initialise FCM. Pass [context] so we can navigate to the
  /// notifications screen when the user taps a push notification.
  Future<void> init(BuildContext context) async {
    // Request permissions for iOS / Web
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('FCM: User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('FCM: User granted provisional permission');
    } else {
      debugPrint('FCM: User declined or has not accepted permission');
    }

    // ── Foreground messages ────────────────────────────────────────────────
    // Show an in-app snackbar; tap navigates to the notifications screen.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM foreground: ${message.notification?.title}');
      if (!context.mounted) return;

      final title = message.notification?.title ?? 'New notification';
      final body = message.notification?.body ?? '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
              ),
              if (body.isNotEmpty)
                Text(
                  body,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => _navigateToNotifications(context),
          ),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    });

    // ── Background tap (app was in background) ─────────────────────────────
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM background tap: ${message.notification?.title}');
      if (context.mounted) {
        _navigateToNotifications(context);
      }
    });

    // ── Terminated tap (app was closed) ────────────────────────────────────
    // getInitialMessage returns the notification that launched the app.
    if (!kIsWeb) {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null && context.mounted) {
        debugPrint('FCM terminated tap: ${initial.notification?.title}');
        _navigateToNotifications(context);
      }
    }
  }

  /// Navigate to the appropriate notifications screen based on the user's role.
  void _navigateToNotifications(BuildContext context) {
    // Try member route first; if the user is an admin the router's redirect
    // will handle sending them to the right place.
    try {
      GoRouter.of(context).push('/home/notifications');
    } catch (_) {
      // If /home/notifications is not accessible (admin user), try admin route.
      try {
        GoRouter.of(context).push('/admin/dashboard/notifications');
      } catch (e) {
        debugPrint('FCM navigation failed: $e');
      }
    }
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
