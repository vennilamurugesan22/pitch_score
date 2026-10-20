import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pitch_score/services/firebase/firebase_match_service.dart';
import 'package:pitch_score/services/local/match_storage.dart';
import 'scoring_event.dart';
import 'scoring_rules.dart';
import 'scoring_state.dart';

// ScoringBloc = the brain of the entire match
// It receives events (user actions) and emits new states (updated match data)
// UI never calculates anything — it only reads state and fires events
// The actual cricket rules live in ScoringRules (pure + unit tested)

class ScoringBloc extends Bloc<ScoringEvent, ScoringState> {

  // Both optional so unit tests can run without Firebase / Hive
  final FirebaseMatchService? _firebaseService;
  final MatchStorage? _storage;

  ScoringBloc(
    super.initialState, {
    FirebaseMatchService? firebaseService,
    MatchStorage? storage,
  })  : _firebaseService = firebaseService,
        _storage = storage {
    on<AddBallEvent>(_onAddBall);
    on<UndoBallEvent>(_onUndo);
    on<SetOpenersEvent>(_onSetOpeners);
    on<NewBowlerSelectedEvent>(_onNewBowlerSelected);
    on<SwapStrikeEvent>(_onSwapStrike);
    on<EndInningsEvent>(_onEndInnings);
    on<StartSecondInningsEvent>(_onStartSecondInnings);
    on<FinishMatchEvent>(_onFinishMatch);
    on<EnableLiveSharingEvent>(_onEnableLiveSharing);
  }

  void _onAddBall(AddBallEvent event, Emitter<ScoringState> emit) {
    emit(ScoringRules.addBall(state, event.ball,
        newBatsmanId: event.newBatsmanId));
  }

  void _onUndo(UndoBallEvent event, Emitter<ScoringState> emit) {
    emit(ScoringRules.undo(state));
  }

  void _onSetOpeners(SetOpenersEvent event, Emitter<ScoringState> emit) {
    if (event.strikerId == event.nonStrikerId) return;
    emit(state.copyWith(
      strikerId: event.strikerId,
      nonStrikerId: event.nonStrikerId,
      currentBowlerId: event.bowlerId,
    ));
  }

  void _onNewBowlerSelected(
      NewBowlerSelectedEvent event, Emitter<ScoringState> emit) {
    emit(state.copyWith(
      currentBowlerId: event.bowlerId,
      needsNewBowler: false,
    ));
  }

  void _onSwapStrike(SwapStrikeEvent event, Emitter<ScoringState> emit) {
    emit(state.copyWith(
      strikerId: state.nonStrikerId,
      nonStrikerId: state.strikerId,
    ));
  }

  void _onEndInnings(EndInningsEvent event, Emitter<ScoringState> emit) {
    emit(state.copyWith(isInningsComplete: true, needsNewBowler: false));
  }

  void _onStartSecondInnings(
      StartSecondInningsEvent event, Emitter<ScoringState> emit) {
    emit(ScoringRules.startSecondInnings(state));
  }

  void _onFinishMatch(FinishMatchEvent event, Emitter<ScoringState> emit) {
    if (state.currentInnings != 2) return;
    emit(state.copyWith(isInningsComplete: true, isMatchComplete: true));
  }

  void _onEnableLiveSharing(
      EnableLiveSharingEvent event, Emitter<ScoringState> emit) {
    if (state.isLiveMode) return;
    final next = state.copyWith(matchCode: event.matchCode, isLiveMode: true);
    // Not awaited: offline, a write only completes when it reaches the
    // server. Firebase sends queued writes in order, so meta still lands
    // before the first state sync from onChange.
    _firebaseService?.createMatchFromState(event.matchCode, next);
    emit(next);
  }

  // ── Side effects on every state change ─────────────────────────
  // Fire and forget — don't await, don't block the UI.
  // Even if Firebase / Hive fail, scoring continues perfectly.
  @override
  void onChange(Change<ScoringState> change) {
    super.onChange(change);
    final next = change.nextState;

    // Save in-progress match so it can be resumed if the app is killed
    if (next.isMatchComplete) {
      _storage?.clearActiveMatch();
    } else {
      _storage?.saveActiveMatch(next);
    }

    // Live mode — push the full snapshot for spectators
    if (next.isLiveMode && next.matchCode.isNotEmpty) {
      _firebaseService?.syncState(next.matchCode, next);
      if (next.isMatchComplete && !change.currentState.isMatchComplete) {
        _firebaseService?.completeMatch(next.matchCode, next.resultText);
      }
    }
  }
}
