import '../../models/ball_model.dart';
import 'scoring_state.dart';

// Pure cricket rules — no Flutter, no Firebase, no Hive.
// ScoringBloc calls these; unit tests call them directly.

class ScoringRules {
  ScoringRules._();

  // Apply one delivery and return the next state.
  // [newBatsmanId] = who walks in if this ball is a wicket
  // (null when the wicket ends the innings).
  static ScoringState addBall(
    ScoringState state,
    Ball ball, {
    String? newBatsmanId,
  }) {
    if (!state.canScore) return state;

    final newLog = [...state.ballLog, ball];
    var striker = state.strikerId;
    var nonStriker = state.nonStrikerId;

    // ── Step 1: Batsmen crossed? ─────────────────────────────────
    // Odd runs actually RUN = batsmen swap ends.
    // A plain wide / no ball has runs 0 → no swap.
    // Wide + 1 run → they ran 1 → swap.
    if (ball.runs % 2 != 0) {
      final t = striker;
      striker = nonStriker;
      nonStriker = t;
    }

    // ── Step 2: Wicket — new batsman takes the dismissed man's place
    if (ball.isWicket) {
      final out = ball.outBatsmanId;
      final incoming = newBatsmanId ?? '';
      if (out == striker) {
        striker = incoming;
      } else if (out == nonStriker) {
        nonStriker = incoming;
      }
    }

    // ── Step 3: Over complete? Always swap ends ──────────────────
    final legal = newLog.where((b) => b.isLegalDelivery).length;
    final overJustCompleted = ball.isLegalDelivery && legal % 6 == 0;
    if (overJustCompleted) {
      final t = striker;
      striker = nonStriker;
      nonStriker = t;
    }

    var next = state.copyWith(
      ballLog: newLog,
      strikerId: striker,
      nonStrikerId: nonStriker,
    );

    // ── Step 4: Innings over? ────────────────────────────────────
    final inningsOver = isInningsOver(next);

    return next.copyWith(
      isInningsComplete: inningsOver,
      needsNewBowler: overJustCompleted && !inningsOver,
    );
  }

  // Innings ends when: all overs bowled, all out, or target chased
  static bool isInningsOver(ScoringState s) {
    if (s.wickets >= s.wicketLimit) return true;
    if (s.legalBalls >= s.totalOvers * 6) return true;
    if (s.target != null && s.totalRuns >= s.target!) return true;
    return false;
  }

  // Remove the last ball. Because every number is computed from the ball
  // log, we only need to put the players back where they were.
  static ScoringState undo(ScoringState state) {
    if (state.ballLog.isEmpty || state.isMatchComplete) return state;
    final last = state.ballLog.last;
    return state.copyWith(
      ballLog: [...state.ballLog]..removeLast(),
      strikerId: last.strikerNameBefore,
      nonStrikerId: last.nonStrikerNameBefore,
      currentBowlerId: last.bowlerId,
      needsNewBowler: false,
      isInningsComplete: false,
    );
  }

  static ScoringState startSecondInnings(ScoringState state) {
    if (state.currentInnings != 1) return state;
    return state.copyWith(
      currentInnings: 2,
      firstInningsBalls: state.ballLog,
      ballLog: const [],
      strikerId: '',
      nonStrikerId: '',
      currentBowlerId: '',
      needsNewBowler: false,
      isInningsComplete: false,
    );
  }
}
