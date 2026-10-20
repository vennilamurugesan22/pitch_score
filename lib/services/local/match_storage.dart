import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../bloc/scoring/scoring_state.dart';

// Keeps the match that is currently being scored in Hive,
// so a killed app / dead battery doesn't lose the match.
// Finished matches go to the 'matches' box via MatchHistoryBloc.

class MatchStorage {
  static const String _boxName = 'active_match';
  static const String _key = 'current';

  static Future<void> init() => Hive.openBox(_boxName);

  Box get _box => Hive.box(_boxName);

  Future<void> saveActiveMatch(ScoringState state) async {
    try {
      await _box.put(_key, state.toMap());
    } catch (e) {
      debugPrint('MatchStorage save error: $e');
    }
  }

  ScoringState? loadActiveMatch() {
    try {
      final map = _box.get(_key);
      if (map is! Map) return null;
      return ScoringState.fromMap(map);
    } catch (e) {
      debugPrint('MatchStorage load error: $e');
      return null;
    }
  }

  Future<void> clearActiveMatch() async {
    try {
      await _box.delete(_key);
    } catch (e) {
      debugPrint('MatchStorage clear error: $e');
    }
  }

  // Lets the home screen show / hide the "Resume match" card
  ValueListenable<Box> listenable() => _box.listenable(keys: [_key]);
}
