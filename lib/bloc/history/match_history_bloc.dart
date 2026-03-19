// match_history_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../../models/match_model.dart';
import 'match_history_event.dart';
import 'match_history_state.dart';

class MatchHistoryBloc extends Bloc<MatchHistoryEvent, MatchHistoryState> {
  // All matches stored under this Hive box name
  static const String _boxName = 'matches';

  MatchHistoryBloc() : super(MatchHistoryInitial()) {
    on<LoadHistoryEvent>(_onLoad);
    on<SaveMatchEvent>(_onSave);
    on<DeleteMatchEvent>(_onDelete);
  }

  Future<void> _onLoad(
      LoadHistoryEvent event, Emitter<MatchHistoryState> emit) async {
    emit(MatchHistoryLoading());
    // Open the Hive box — if already open, returns existing box
    final box = await Hive.openBox<Match>(_boxName);
    // .values gives all stored matches
    // .reversed shows newest match first
    emit(MatchHistoryLoaded(box.values.toList().reversed.toList()));
  }

  Future<void> _onSave(
      SaveMatchEvent event, Emitter<MatchHistoryState> emit) async {
    final box = await Hive.openBox<Match>(_boxName);
    // .put(key, value) — we use match.id as key so we can find it later
    await box.put(event.match.id, event.match);
    // Reload the list so UI updates immediately
    add(const LoadHistoryEvent());
  }

  Future<void> _onDelete(
      DeleteMatchEvent event, Emitter<MatchHistoryState> emit) async {
    final box = await Hive.openBox<Match>(_boxName);
    await box.delete(event.matchId);
    add(const LoadHistoryEvent());
  }
}