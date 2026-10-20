import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:pitch_score/firebase_options.dart';

/// Background message handler — must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('🔔 [BG] FCM message received: ${message.messageId}');
}

// FCM setup, moved out of main() so it never delays app start
// (getToken can hang for a long time with no network / no APNs token).
class PushNotificationService {
  static Future<void> init() async {
    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request notification permission (iOS / Android 13+)
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('🔔 FCM permission status: ${settings.authorizationStatus}');

      final token = await _getFcmToken(messaging);
      debugPrint('🔑 FCM TOKEN: $token');

      messaging.onTokenRefresh.listen((t) => debugPrint('🔄 FCM token refreshed: $t'));
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 [FG] ${message.notification?.title}: ${message.notification?.body}');
      });
    } catch (e) {
      debugPrint('FCM setup skipped: $e');
    }
  }

  /// On iOS, APNs token delivery is async — poll until it's ready
  /// (up to [maxRetries] × 1 second) before calling getToken().
  static Future<String?> _getFcmToken(FirebaseMessaging messaging) async {
    if (Platform.isIOS) {
      const maxRetries = 10;
      for (int i = 0; i < maxRetries; i++) {
        final apnsToken = await messaging.getAPNSToken();
        if (apnsToken != null) break;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return messaging.getToken().timeout(const Duration(seconds: 15));
  }
}
