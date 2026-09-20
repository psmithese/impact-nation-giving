import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/services/fcm_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/firebase_setup.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/providers/onboarding_provider.dart';

/// Top-level FCM background handler — runs in a separate isolate.
/// Actual UI navigation is handled by onMessageOpenedApp / getInitialMessage
/// in the main isolate via FcmService.init().
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase must be initialised before any Firebase call in this isolate.
  // FirebaseSetup.initialize() is idempotent.
  debugPrint('FCM background message: ${message.notification?.title}');
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register the background message handler before Firebase.initializeApp
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    await FirebaseSetup.initialize();
  } catch (e, st) {
    debugPrint('FirebaseSetup error: $e\n$st');
  }

  bool hasSeenOnboarding = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    hasSeenOnboarding = prefs.getBool(OnboardingNotifier.prefKey) ?? false;
  } catch (e) {
    debugPrint('SharedPreferences init error: $e');
  }
  
  runApp(
    ProviderScope(
      overrides: [
        onboardingCompletedProvider.overrideWith(
          () => OnboardingNotifier(hasSeenOnboarding),
        ),
      ],
      child: const ImpactNationApp(),
    ),
  );
}

class ImpactNationApp extends ConsumerWidget {
  const ImpactNationApp({super.key});

  static bool _fcmInitialised = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Initialise FCM exactly once after the first frame, when the router is ready.
    if (!_fcmInitialised) {
      _fcmInitialised = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FcmService.init(router);
      });
    }

    return MaterialApp.router(
      title: 'Impact Nation Giving',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
