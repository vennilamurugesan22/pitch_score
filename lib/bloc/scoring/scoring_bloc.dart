import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pitch_score/models/ball_model.dart';
import 'package:pitch_score/services/firebase/firebase_match_service.dart';
import 'scoring_event.dart';
import 'scoring_state.dart';

// ScoringBloc = the brain of the entire match
// It receives events (user actions) and emits new states (updated match data)
// UI never calculates anything — it only reads state and fires events

class ScoringBloc extends Bloc<ScoringEvent, ScoringState> {

  // Firebase service instance
  // ScoringBloc uses this to sync every ball
  final FirebaseMatchService _firebaseService = FirebaseMatchService();

   // Match code — set when match starts in live mode
  // Empty string = offline mode, no Firebase sync
  final String matchCode;
  final bool isLiveMode;

  // super(const ScoringState()) = set the initial state
  // When match starts, everything is 0 / empty
    ScoringBloc({
    required this.matchCode,
    required this.isLiveMode,
  }) : super(const ScoringState()) {

    // Register each event with its handler function
    // Think of this as: "when THIS event comes in, run THIS function"
    on<AddBallEvent>(_onAddBall);
    on<UndoBallEvent>(_onUndo);
    on<SelectBatsmanEvent>(_onSelectBatsman);
    on<SelectBowlerEvent>(_onSelectBowler);
    on<EndInningsEvent>(_onEndInnings);
    // Register in constructor
    on<WicketDetailEvent>(_onWicketDetail);
    on<NewBowlerSelectedEvent>(_onNewBowlerSelected);
  }

  // ── Handler: AddBallEvent ────────────────────────────────────────
  // This is called every time scorer taps a button
  // event = the Ball object with all delivery details
  // emit = function to push new state to UI
void _onAddBall(AddBallEvent event, Emitter<ScoringState> emit) {
  final ball = event.ball;

  // ── Step 1: Add ball to log ──────────────────────────────────────
  final newBallLog = [...state.ballLog, ball];

  // ── Step 2: Update runs ──────────────────────────────────────────
  final newRuns = state.totalRuns + ball.runs;

  // ── Step 3: Update extras ────────────────────────────────────────
  int newExtras = state.extras;
  if (ball.isWide || ball.isNoBall) newExtras += 1;
  if (ball.isBye || ball.isLegBye) newExtras += ball.runs;

  // ── Step 4: Update wickets ───────────────────────────────────────
  int newWickets = state.wickets;
  if (ball.isWicket) newWickets += 1;

  // ── Step 5: Over count ───────────────────────────────────────────
  // Wide and No Ball do NOT count in the over
  int newBallsInOver = state.ballsInCurrentOver;
  int newOverNumber = state.overNumber;
  bool overJustCompleted = false;

  if (ball.isLegalDelivery) {
    newBallsInOver += 1;

    if (newBallsInOver == 6) {
      // Over complete!
      newOverNumber += 1;
      newBallsInOver = 0;
      overJustCompleted = true;
    }
  }

  // ── Step 6: Striker swap ─────────────────────────────────────────
  // We use a simple boolean to track swap
  // Two swaps = back to same position (cancels out)
  String newStriker = state.strikerId;
  String newNonStriker = state.nonStrikerId;

  // Tell UI to show popups if needed
final needsNewBowler = overJustCompleted;
final needsNewBatsman = ball.isWicket;

  bool shouldSwap = false;

  if (!ball.isWicket) {
    // Swap condition 1 — odd runs (and not a wide)
    // Wide: batsmen didn't actually run — no swap
    if (!ball.isWide && ball.runs % 2 != 0) {
      shouldSwap = !shouldSwap; // flip
    }

    // Swap condition 2 — end of over (always swap)
    if (overJustCompleted) {
      shouldSwap = !shouldSwap; // flip again
    }

    // Example: Ball 6 scores 1 run
    // Swap 1 → shouldSwap = true  (odd run)
    // Swap 2 → shouldSwap = false (over complete cancels it)
    // Result: no swap — same striker faces next over
    if (shouldSwap) {
      final temp = newStriker;
      newStriker = newNonStriker;
      newNonStriker = temp;
    }
  }

  // ── Step 7: Emit new state ───────────────────────────────────────
  emit(state.copyWith(
    ballLog: newBallLog,
    totalRuns: newRuns,
    wickets: newWickets,
    overNumber: newOverNumber,
    ballsInCurrentOver: newBallsInOver,
    extras: newExtras,
    strikerId: newStriker,
    nonStrikerId: newNonStriker,
    isOverComplete: needsNewBowler,       // UI shows bowler picker
    isWicketJustFallen: needsNewBatsman,  // UI shows batsman picker
  ));

  // ── Firebase sync ────────────────────────────────────────────────
  // Only sync if live mode is on
  // Fire and forget — don't await, don't block the UI
  // Even if Firebase fails, scoring continues perfectly
  if (isLiveMode && matchCode.isNotEmpty) {
    _firebaseService.syncBall(
      matchCode: matchCode,
      ball: ball,
      state: state, // new state after emit
    );
  }

  
}
  // ── Handler: UndoBallEvent ───────────────────────────────────────
void _onUndo(UndoBallEvent event, Emitter<ScoringState> emit) {
  // Nothing to undo
  if (state.ballLog.isEmpty) return;

  // Get the last ball
  final lastBall = state.ballLog.last;

  // Remove last ball from log
  final newBallLog = [...state.ballLog]..removeLast();

  // Reverse runs
  final newRuns = state.totalRuns - lastBall.runs;

  // Reverse wickets
  final newWickets = lastBall.isWicket
      ? state.wickets - 1
      : state.wickets;

  // Reverse extras
  int newExtras = state.extras;
  if (lastBall.isWide || lastBall.isNoBall) newExtras -= 1;
  if (lastBall.isBye || lastBall.isLegBye) newExtras -= lastBall.runs;

  // Reverse over count
  int newBallsInOver = state.ballsInCurrentOver;
  int newOverNumber = state.overNumber;

  if (lastBall.isLegalDelivery) {
    if (newBallsInOver == 0) {
      // We were at start of a new over
      // Means last ball COMPLETED the previous over — go back
      newOverNumber -= 1;
      newBallsInOver = 5; // back to 5th ball of previous over
    } else {
      newBallsInOver -= 1;
    }
  }

  // Restore striker and non-striker from the ball itself
  // This is why we added those 2 fields to Ball model!
  final restoredStriker = lastBall.strikerNameBefore;
  final restoredNonStriker = lastBall.nonStrikerNameBefore;

  emit(state.copyWith(
    ballLog: newBallLog,
    totalRuns: newRuns,
    wickets: newWickets,
    overNumber: newOverNumber,
    ballsInCurrentOver: newBallsInOver,
    extras: newExtras,
    strikerId: restoredStriker,
    nonStrikerId: restoredNonStriker,
  ));
}
  // ── Handler: SelectBatsmanEvent ──────────────────────────────────
  // Called when wicket falls and scorer picks the new batsman
  // The new batsman always comes in at the striker's end
  void _onSelectBatsman(SelectBatsmanEvent event, Emitter<ScoringState> emit) {
    emit(state.copyWith(strikerId: event.batsmanId));
  }

  // ── Handler: SelectBowlerEvent ───────────────────────────────────
  // Called when over is complete and scorer picks next bowler
  void _onSelectBowler(SelectBowlerEvent event, Emitter<ScoringState> emit) {
    emit(state.copyWith(currentBowlerId: event.bowlerId));
  }

  // ── Handler: EndInningsEvent ─────────────────────────────────────
  // Called when innings ends (all overs done or all wickets fallen)
  void _onEndInnings(EndInningsEvent event, Emitter<ScoringState> emit) {
    if (state.currentInnings == 1) {
      // Store 1st innings score as target for Team 2
      emit(state.copyWith(
        currentInnings: 2,
        firstInningsScore: state.totalRuns,
        // Reset scoring fields for 2nd innings
        totalRuns: 0,
        wickets: 0,
        overNumber: 0,
        ballsInCurrentOver: 0,
        extras: 0,
        strikerId: '',
        nonStrikerId: '',
        currentBowlerId: '',
        // Keep ballLog — it has 1st innings balls, new balls will be appended
      ));
    } else {
      // 2nd innings done — match over
      emit(state.copyWith(isMatchComplete: true));
    }
  }

  void _onWicketDetail(WicketDetailEvent event, Emitter<ScoringState> emit) {
  // New batsman always comes in at striker's end
  // The dismissed batsman was the striker
  // So new batsman replaces striker directly
  emit(state.copyWith(
    strikerId: event.newBatsmanId,
  ));
}


void _onNewBowlerSelected(
    NewBowlerSelectedEvent event, Emitter<ScoringState> emit) {
  emit(state.copyWith(
    currentBowlerId: event.bowlerId,
    isOverComplete: false, // dismiss the popup
  ));
}

}