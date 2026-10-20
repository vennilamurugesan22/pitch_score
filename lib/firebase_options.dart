// File generated from firebase config files.
// google-services.json  →  android values
// GoogleService-Info.plist  →  ios values

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── Android (from google-services.json) ──────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDPGemAwj_IrVXLoo_caT0I7DqkZqaVNwI',
    appId: '1:41090800972:android:044cea03ae0e07bac843e9',
    messagingSenderId: '41090800972',
    projectId: 'pitchscore-d15a6',
    storageBucket: 'pitchscore-d15a6.firebasestorage.app',
    databaseURL: 'https://pitchscore-d15a6-default-rtdb.firebaseio.com',
  );

  // ── iOS (from GoogleService-Info.plist) ───────────────────────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyClmArUR49GusDz2Vv6AFUYRrLijO8VmzY',
    appId: '1:41090800972:ios:23e6b7382e9f0dc9c843e9',
    messagingSenderId: '41090800972',
    projectId: 'pitchscore-d15a6',
    storageBucket: 'pitchscore-d15a6.firebasestorage.app',
    databaseURL: 'https://pitchscore-d15a6-default-rtdb.firebaseio.com',
    iosBundleId: 'com.example.pitchScore',
  );
}
