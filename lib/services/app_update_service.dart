import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'firebase/firebase_match_service.dart';

// Optional / force update, driven from Firebase Realtime Database:
//
//   /config/app_update
//     latest_version: "1.1.0"   → below this: optional "Update available"
//     min_version:    "1.0.0"   → below this: force update, app is blocked
//     message:        "New: tournament mode!"
//     android_url:    "https://play.google.com/store/apps/details?id=..."
//     ios_url:        "https://apps.apple.com/app/id..."
//
// Change these values in the Firebase console — no app release needed.

enum UpdateType { none, optional, force }

class AppUpdateInfo {
  final UpdateType type;
  final String currentVersion;
  final String latestVersion;
  final String message;
  final String storeUrl;

  const AppUpdateInfo({
    required this.type,
    required this.currentVersion,
    required this.latestVersion,
    required this.message,
    required this.storeUrl,
  });
}

class AppUpdateService {
  static const _prefsBox = 'prefs';
  static const _skippedKey = 'skipped_update_version';

  static Future<void> init() => Hive.openBox(_prefsBox);

  // Compares "1.2.10" style versions; build numbers (+5) are ignored.
  // Returns <0 if a < b, 0 if equal, >0 if a > b.
  static int compareVersions(String a, String b) {
    List<int> parts(String v) => v
        .split('+')
        .first
        .split('.')
        .map((p) => int.tryParse(p.trim()) ?? 0)
        .toList();
    final pa = parts(a), pb = parts(b);
    for (var i = 0; i < 3; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x - y;
    }
    return 0;
  }

  // Pure decision — unit tested
  static UpdateType decide({
    required String current,
    required String latest,
    required String minimum,
    String? skipped,
  }) {
    if (minimum.isNotEmpty && compareVersions(current, minimum) < 0) {
      return UpdateType.force;
    }
    if (latest.isNotEmpty &&
        compareVersions(current, latest) < 0 &&
        skipped != latest) {
      return UpdateType.optional;
    }
    return UpdateType.none;
  }

  Future<AppUpdateInfo?> check() async {
    if (!FirebaseMatchService.isAvailable) return null;
    try {
      final info = await PackageInfo.fromPlatform();
      final snap = await FirebaseDatabase.instance
          .ref('config/app_update')
          .get()
          .timeout(const Duration(seconds: 6));
      final value = snap.value;
      if (value is! Map) return null;

      final latest = '${value['latest_version'] ?? ''}';
      final minimum = '${value['min_version'] ?? ''}';
      final url = '${value[Platform.isIOS ? 'ios_url' : 'android_url'] ?? ''}';
      final type = decide(
        current: info.version,
        latest: latest,
        minimum: minimum,
        skipped: Hive.box(_prefsBox).get(_skippedKey) as String?,
      );
      return AppUpdateInfo(
        type: type,
        currentVersion: info.version,
        latestVersion: latest,
        message: '${value['message'] ?? ''}',
        storeUrl: url,
      );
    } catch (e) {
      // Offline / slow network — never block the app over an update check
      debugPrint('Update check skipped: $e');
      return null;
    }
  }

  // "Later" on an optional update — don't ask again for this version
  Future<void> skip(String version) =>
      Hive.box(_prefsBox).put(_skippedKey, version);
}
