import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

class FirebaseSetup {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase.initializeApp failed: $e');
    }

    // Initialize Google Sign-In safely — skip on web since we use signInWithPopup.
    // serverClientId is the Web OAuth 2.0 client (client_type 3) from
    // google-services.json. It is required on Android so that the Credential
    // Manager returns an idToken that Firebase can verify.
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.initialize(
          serverClientId:
              '421320065355-ku279k2snse49l6qlij1509af6kgtilh.apps.googleusercontent.com',
        );
      } catch (e) {
        debugPrint('GoogleSignIn.initialize failed: $e');
      }
    }

    // App Check - only activate for Android / iOS, not Web unless ReCaptcha is configured
    try {
      if (!kDebugMode && !kIsWeb) {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
        );
      }
    } catch (e) {
      debugPrint('Firebase App Check initialization failed: $e');
    }

    // Crashlytics and Analytics (non-web)
    if (!kIsWeb) {
      try {
        FlutterError.onError = (errorDetails) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        };
        
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
        
        FirebaseAnalytics.instance;
      } catch (e) {
        debugPrint('Crashlytics / Analytics failed: $e');
      }
    }
  }
}

