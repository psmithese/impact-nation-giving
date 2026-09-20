import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

/// Singleton that wires up Firebase Cloud Messaging for Android / iOS.
///
/// Call [FcmService.init] once after Firebase is initialised (in main.dart),
/// passing the [GoRouter] so the service can navigate on notification tap.
class FcmService {
  FcmService._();

  static final FcmService _instance = FcmService._();
  static FcmService get instance => _instance;

  static const _channelId = 'impact_nation_channel';
  static const _channelName = 'Impact Nation Notifications';
  static const _channelDesc = 'Announcements, payment updates, and reminders';

  final _localNotifications = FlutterLocalNotificationsPlugin();
  GoRouter? _router;

  // ── Public init ────────────────────────────────────────────────────────────

  static Future<void> init(GoRouter router) async {
    if (kIsWeb) return; // Local notifications N/A on web
    await _instance._setup(router);
  }

  // ── Private setup ──────────────────────────────────────────────────────────

  Future<void> _setup(GoRouter router) async {
    _router = router;

    // 1. Request permission (Android 13+ / iOS)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Initialise flutter_local_notifications with the app icon
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // 3. Create the Android notification channel.
    //    ID must match the manifest meta-data value "impact_nation_channel".
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // 4. FOREGROUND — show a local notification banner when FCM arrives.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 5. BACKGROUND TAP — app was backgrounded, user tapped the notification.
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // 6. TERMINATED TAP — app was force-closed, user tapped to re-open.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      // Small delay so the router auth redirect completes before we push.
      await Future.delayed(const Duration(milliseconds: 900));
      _navigateToNotifications();
    }

    // 7. iOS foreground presentation options
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      // Payload carried through so the tap handler can navigate.
      payload: 'notifications',
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    _navigateToNotifications();
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload == 'notifications') {
      _navigateToNotifications();
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _navigateToNotifications() {
    try {
      _router?.go('/home/notifications');
    } catch (e) {
      debugPrint('FcmService: navigation error — $e');
    }
  }
}
