import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:pitch_score/bloc/scoring/scoring_state.dart';
import 'package:pitch_score/bloc/setup/match_setup_state.dart';

// This service handles ALL Firebase communication
// ScoringBloc calls these methods — it never touches Firebase directly
// Clean separation: BLoC handles logic, this service handles network
//
// Firebase layout:
//   /matches/{code}/meta            team names, overs, status
//   /matches/{code}/players         [{id, name, teamId}]
//   /matches/{code}/innings/{n}/balls   ball list for each innings
//   /matches/{code}/state           full snapshot — spectators read THIS
//   /matches/{code}/viewers/{id}    one entry per spectator (presence)

class FirebaseMatchService {
  // Lazy — so the app still works if Firebase failed to initialise
  DatabaseReference? get _db {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseDatabase.instance.ref();
  }

  static bool get isAvailable => Firebase.apps.isNotEmpty;

  // ── Create Match ─────────────────────────────────────────────────
  // Called once when scorer starts a live match
  Future<void> createMatch(String matchCode, MatchSetupState setup) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.child('matches/$matchCode').update({
        'meta': {
          'teamOneName': setup.teamOneName,
          'teamTwoName': setup.teamTwoName,
          'totalOvers': setup.totalOvers,
          'maxWickets': setup.maxWickets,
          'status': 'live', // live / completed
          'createdAt': DateTime.now().toIso8601String(),
        },
        'players': setup.players.map((p) => p.toMap()).toList(),
      });
    } catch (e) {
      // Firebase failed — app still works offline
      debugPrint('Firebase createMatch error: $e');
    }
  }

  // Same as createMatch, for a match that started offline
  Future<void> createMatchFromState(String matchCode, ScoringState s) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.child('matches/$matchCode').update({
        'meta': {
          'teamOneName': s.teamOneName,
          'teamTwoName': s.teamTwoName,
          'totalOvers': s.totalOvers,
          'maxWickets': s.maxWickets,
          'status': 'live',
          'createdAt': DateTime.now().toIso8601String(),
        },
        'players': s.players.map((p) => p.toMap()).toList(),
      });
    } catch (e) {
      debugPrint('Firebase createMatchFromState error: $e');
    }
  }

  // Random 6-digit code not already used on Firebase
  Future<String> newMatchCode() async {
    final random = Random.secure();
    String code() => List.generate(6, (_) => random.nextInt(10)).join();
    var c = code();
    for (var i = 0; i < 3 && await matchExists(c); i++) {
      c = code();
    }
    return c;
  }

  // ── Sync State ───────────────────────────────────────────────────
  // Called on every state change (ball, undo, new bowler...)
  // One multi-path update = one network round trip.
  // With offline persistence on, writes queue up and send when back online.
  Future<void> syncState(String matchCode, ScoringState state) async {
    final db = _db;
    if (db == null) return;
    try {
      final inningsBalls = state.ballLog.map((b) => b.toMap()).toList();
      await db.child('matches/$matchCode').update({
        'state': {
          ...state.toMap(),
          'lastUpdated': ServerValue.timestamp,
        },
        'innings/${state.currentInnings}/balls': inningsBalls,
      });
    } catch (e) {
      // Silent fail — scoring continues even if Firebase is down
      debugPrint('Firebase syncState error: $e');
    }
  }

  // ── Watch Match ──────────────────────────────────────────────────
  // Spectators — new event every time the scorer taps a button
  // Emits null if the match code doesn't exist
  Stream<ScoringState?> watchMatch(String matchCode) {
    final db = _db;
    if (db == null) return Stream.error('Live scores need internet');
    return db.child('matches/$matchCode/state').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return null;
      return ScoringState.fromMap(value);
    });
  }

  // ── Match Exists Check ───────────────────────────────────────────
  Future<bool> matchExists(String matchCode) async {
    final db = _db;
    if (db == null) return false;
    try {
      final snapshot = await db
          .child('matches/$matchCode/meta')
          .get()
          .timeout(const Duration(seconds: 8));
      return snapshot.exists;
    } catch (e) {
      return false;
    }
  }

  // ── Complete Match ───────────────────────────────────────────────
  Future<void> completeMatch(String matchCode, String result) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.child('matches/$matchCode/meta').update({
        'status': 'completed',
        'result': result,
        'completedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Firebase completeMatch error: $e');
    }
  }

  // ── Viewers (presence) ───────────────────────────────────────────
  // Each spectator writes /viewers/{viewerId}. onDisconnect removes it
  // automatically if the phone loses network or the app is killed —
  // so the count never gets stuck (a plain counter would).
  Future<void> incrementViewers(String matchCode, String viewerId) async {
    final db = _db;
    if (db == null) return;
    try {
      final ref = db.child('matches/$matchCode/viewers/$viewerId');
      await ref.onDisconnect().remove();
      await ref.set(true);
    } catch (e) {
      debugPrint('Firebase incrementViewers error: $e');
    }
  }

  Future<void> decrementViewers(String matchCode, String viewerId) async {
    final db = _db;
    if (db == null) return;
    try {
      final ref = db.child('matches/$matchCode/viewers/$viewerId');
      await ref.remove();
      await ref.onDisconnect().cancel();
    } catch (e) {
      debugPrint('Firebase decrementViewers error: $e');
    }
  }

  // ── Watch Viewers Count ──────────────────────────────────────────
  Stream<int> watchViewers(String matchCode) {
    final db = _db;
    if (db == null) return Stream.value(0);
    return db
        .child('matches/$matchCode/viewers')
        .onValue
        .map((event) => event.snapshot.children.length);
  }
}
