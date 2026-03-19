import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pitch_score/models/ball_model.dart';
import 'scoring_event.dart';
import 'scoring_state.dart';

// ScoringBloc = the brain of the entire match
// It receives events (user actions) and emits new states (updated match data)
// UI never calculates anything — it only reads state and fires events

class ScoringBloc extends Bloc<ScoringEvent, ScoringState> {

  // super(const ScoringState()) = set the initial state
  // When match starts, everything is 0 / empty
  ScoringBloc() : super(const ScoringState()) {

    // Register each event with its handler function
    // Think of this as: "when THIS event comes in, run THIS function"
    on<AddBallEvent>(_onAddBall);
    on<UndoBallEvent>(_onUndo);
    on<SelectBatsmanEvent>(_onSelectBatsman);
    on<SelectBowlerEvent>(_onSelectBowler);
    on<EndInningsEvent>(_onEndInnings);
  }

  // ── Handler: AddBallEvent ────────────────────────────────────────
  // This is called every time scorer taps a button
  // event = the Ball object with all delivery details
  // emit = function to push new state to UI
  void _onAddBall(AddBallEvent event, Emitter<ScoringState> emit) {
    final ball = event.ball;

    // Step 1: Add ball to the log
    // We never modify existing list — create a new list with ball added
    final newBallLog = [...state.ballLog, ball];

    // Step 2: Update runs
    // Wide and No ball runs go to extras, not total? NO — they go to BOTH
    // total runs includes everything including extras
    final newRuns = state.totalRuns + ball.runs;

    // Step 3: Update extras
    // Only wides, no balls, byes, leg byes count as extras
    int newExtras = state.extras;
    if (ball.isWide || ball.isNoBall) {
      newExtras += 1; // the penalty run
    }
    if (ball.isBye || ball.isLegBye) {
      newExtras += ball.runs; // the runs they ran
    }

    // Step 4: Update wickets
    int newWickets = state.wickets;
    if (ball.isWicket) newWickets += 1;

    // Step 5: Update over count
    // CRITICAL: Wide and No Ball do NOT count as a ball in the over
    int newBallsInOver = state.ballsInCurrentOver;
    int newOverNumber = state.overNumber;

    if (ball.isLegalDelivery) {
      // Legal delivery = counts in the over
      newBallsInOver += 1;

      if (newBallsInOver == 6) {
        // Over is complete!
        newOverNumber += 1;
        newBallsInOver = 0;
        // Note: UI will show over-complete popup to select new bowler
        // Striker swap happens at end of over (handled below)
      }
    }

    // Step 6: Striker swap logic
    // Rule: if batsmen ran ODD number of runs → they swap ends
    // Rule: end of over → always swap
    // Wide/No ball with no runs = no swap
    String newStriker = state.strikerId;
    String newNonStriker = state.nonStrikerId;

    final overJustCompleted = ball.isLegalDelivery && newBallsInOver == 0;

    if (!ball.isWicket) {
      // Only swap if not a wicket (new batsman comes in, that's handled separately)
      final runsScored = ball.runs;
      final oddRuns = runsScored % 2 != 0;

      if (oddRuns && !ball.isWide) {
        // Swap — batsmen crossed while running
        final temp = newStriker;
        newStriker = newNonStriker;
        newNonStriker = temp;
      }

      // End of over — always swap regardless of runs
      if (overJustCompleted) {
        final temp = newStriker;
        newStriker = newNonStriker;
        newNonStriker = temp;
      }
    }

    // Step 7: Emit the new state
    // copyWith creates a new state with only changed fields updated
    emit(state.copyWith(
      ballLog: newBallLog,
      totalRuns: newRuns,
      wickets: newWickets,
      overNumber: newOverNumber,
      ballsInCurrentOver: newBallsInOver,
      extras: newExtras,
      strikerId: newStriker,
      nonStrikerId: newNonStriker,
    ));
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

}