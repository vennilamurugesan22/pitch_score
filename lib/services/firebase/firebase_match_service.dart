import 'package:firebase_database/firebase_database.dart';
import 'package:pitch_score/bloc/scoring/scoring_state.dart';
import 'package:pitch_score/models/ball_model.dart';

// This service handles ALL Firebase communication
// ScoringBloc calls these methods — it never touches Firebase directly
// Clean separation: BLoC handles logic, this service handles network

class FirebaseMatchService {
  // Get reference to Firebase Realtime Database
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // ── Create Match ─────────────────────────────────────────────────
  // Called once when scorer starts a live match
  // Creates the match entry on Firebase under the match code
  Future<void> createMatch({
    required String matchCode,
    required String teamOneName,
    required String teamTwoName,
    required int totalOvers,
    required int maxWickets,
  }) async {
    try {
      await _db.child('matches/$matchCode/meta').set({
        'teamOneName': teamOneName,
        'teamTwoName': teamTwoName,
        'totalOvers': totalOvers,
        'maxWickets': maxWickets,
        'status': 'live', // live / completed
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Firebase failed — app still works offline
      // We never crash the app because of Firebase failure
      print('Firebase createMatch error: $e');
    }
  }

  // ── Sync Ball ────────────────────────────────────────────────────
  // Called every time scorer taps a button
  // Writes the new ball AND updated score summary to Firebase
  // Spectators read this summary to show live score
  Future<void> syncBall({
    required String matchCode,
    required Ball ball,
    required ScoringState state,
  }) async {
    try {
      // Write the ball to the innings ball list
      final inningsPath = 'matches/$matchCode/innings/${state.currentInnings}/balls';
      await _db.child(inningsPath).push().set(ball.toMap());

      // Also update the live state summary
      // Spectators read THIS — not the full ball list
      // Much faster to read one object than hundreds of balls
      await _db.child('matches/$matchCode/state').set({
        'totalRuns': state.totalRuns,
        'wickets': state.wickets,
        'overNumber': state.overNumber,
        'ballsInCurrentOver': state.ballsInCurrentOver,
        'currentInnings': state.currentInnings,
        'strikerId': state.strikerId,
        'nonStrikerId': state.nonStrikerId,
        'currentBowlerId': state.currentBowlerId,
        'extras': state.extras,
        'firstInningsScore': state.firstInningsScore,
        'isMatchComplete': state.isMatchComplete,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silent fail — scoring continues even if Firebase is down
      print('Firebase syncBall error: $e');
    }
  }

  // ── Watch Match ──────────────────────────────────────────────────
  // Called by spectators — returns a Stream
  // Every time scorer taps a button, this stream gets a new event
  // StreamBuilder in UI listens to this and redraws automatically
  Stream<Map<String, dynamic>?> watchMatch(String matchCode) {
    return _db
        .child('matches/$matchCode/state')
        .onValue
        .map((event) {
          // If match not found — return null
          if (!event.snapshot.exists) return null;

          // Convert Firebase snapshot to a Map
          return Map<String, dynamic>.from(
            event.snapshot.value as Map,
          );
        });
  }

  // ── Watch Match Meta ─────────────────────────────────────────────
  // Spectator reads team names and overs when they join
  Future<Map<String, dynamic>?> getMatchMeta(String matchCode) async {
    try {
      final snapshot = await _db.child('matches/$matchCode/meta').get();
      if (!snapshot.exists) return null;
      return Map<String, dynamic>.from(snapshot.value as Map);
    } catch (e) {
      print('Firebase getMatchMeta error: $e');
      return null;
    }
  }

  // ── Match Exists Check ───────────────────────────────────────────
  // Before creating a match, check if code is already taken
  // If taken — generate a new code
  Future<bool> matchExists(String matchCode) async {
    try {
      final snapshot = await _db.child('matches/$matchCode/meta').get();
      return snapshot.exists;
    } catch (e) {
      return false;
    }
  }

  // ── Complete Match ───────────────────────────────────────────────
  // Called when match ends — update status so spectators know
  Future<void> completeMatch(String matchCode, String result) async {
    try {
      await _db.child('matches/$matchCode/meta').update({
        'status': 'completed',
        'result': result,
        'completedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Firebase completeMatch error: $e');
    }
  }

  // ── Viewers Count ────────────────────────────────────────────────
  // Track how many people are watching live
  // Increment when spectator joins, decrement when they leave
  Future<void> incrementViewers(String matchCode) async {
    try {
      final ref = _db.child('matches/$matchCode/viewers');
      await ref.runTransaction((value) {
        return Transaction.success((value as int? ?? 0) + 1);
      });
    } catch (e) {
      print('Firebase incrementViewers error: $e');
    }
  }

  Future<void> decrementViewers(String matchCode) async {
    try {
      final ref = _db.child('matches/$matchCode/viewers');
      await ref.runTransaction((value) {
        final current = value as int? ?? 0;
        return Transaction.success(current > 0 ? current - 1 : 0);
      });
    } catch (e) {
      print('Firebase decrementViewers error: $e');
    }
  }

  // ── Watch Viewers Count ──────────────────────────────────────────
  // Stream of viewer count — updates live on spectator screen
  Stream<int> watchViewers(String matchCode) {
    return _db
        .child('matches/$matchCode/viewers')
        .onValue
        .map((event) => (event.snapshot.value as int?) ?? 0);
  }
}