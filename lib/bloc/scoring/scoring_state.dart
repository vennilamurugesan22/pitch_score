import 'package:equatable/equatable.dart';
import '../../models/ball_model.dart';

// ScoringState = a snapshot of the entire match at any moment
// Every time a ball is bowled, BLoC emits a NEW ScoringState
// UI reads this state and redraws itself automatically

class ScoringState extends Equatable {

  // THE MOST IMPORTANT FIELD
  // Every single ball bowled is stored here as a Ball object
  // ALL other fields (runs, wickets, stats) are COMPUTED from this list
  // This is called "event sourcing" — the log is the source of truth
  final List<Ball> ballLog;

  // ── Match progress ──────────────────────────────────────────────

  // Total runs scored so far in this innings
  final int totalRuns;

  // Total wickets fallen so far
  final int wickets;

  // Which over is currently being bowled (0-indexed)
  // Over 1 = overNumber 0, Over 2 = overNumber 1, etc.
  final int overNumber;

  // How many LEGAL balls bowled in the current over (0 to 5)
  // Wide and No Ball do NOT count here
  // When this reaches 6 → over is complete
  final int ballsInCurrentOver;

  // ── Players currently active ────────────────────────────────────

  // ID of the batsman currently facing the ball (on strike)
  final String strikerId;

  // ID of the batsman at the other end (not facing)
  final String nonStrikerId;

  // ID of the bowler currently bowling this over
  final String currentBowlerId;

  // ── Extras ──────────────────────────────────────────────────────

  // Total extras (wides + no balls + byes + leg byes)
  final int extras;

  // ── Match context ───────────────────────────────────────────────

  // 1 = first innings (Team 1 batting)
  // 2 = second innings (Team 2 chasing)
  final int currentInnings;

  // Score Team 1 set — Team 2 needs to beat this
  // Only has value during 2nd innings
  final int? firstInningsScore;

  // true = match is finished, show result screen
  final bool isMatchComplete;


  // true = over just completed, show select bowler popup
final bool isOverComplete;

// true = wicket just fell, show select batsman popup  
final bool isWicketJustFallen;

  // ── Constructor with default values ─────────────────────────────
  // Default values = fresh match, nothing happened yet
  const ScoringState({
    this.ballLog = const [],
    this.totalRuns = 0,
    this.wickets = 0,
    this.overNumber = 0,
    this.ballsInCurrentOver = 0,
    this.strikerId = '',
    this.nonStrikerId = '',
    this.currentBowlerId = '',
    this.extras = 0,
    this.currentInnings = 1,
    this.firstInningsScore,
    this.isMatchComplete = false,
    this.isOverComplete = false,
    this.isWicketJustFallen = false,
  });

  // ── Computed properties ─────────────────────────────────────────
  // These are not stored — calculated fresh every time state is read
  // UI uses these directly — no extra calculation needed in widgets

  // Display string for the scoreboard e.g. "147 / 4"
  String get scoreDisplay => '$totalRuns / $wickets';

  // Display string for overs e.g. "13.4" means Over 14, Ball 4
  String get oversDisplay => '$overNumber.$ballsInCurrentOver';

  // Current Run Rate = runs scored per over
  // Guard: avoid divide by zero when match just started
  double get currentRunRate {
    if (overNumber == 0 && ballsInCurrentOver == 0) return 0.0;
    final totalBalls = (overNumber * 6) + ballsInCurrentOver;
    return totalRuns / (totalBalls / 6);
  }

  // Required Run Rate = how fast Team 2 needs to score to win
  // Only meaningful in 2nd innings
  double get requiredRunRate {
    if (currentInnings != 2 || firstInningsScore == null) return 0.0;
    final runsNeeded = firstInningsScore! + 1 - totalRuns;
    // total balls in match - balls already bowled
    final ballsBowled = (overNumber * 6) + ballsInCurrentOver;
    // We need totalOvers to calculate this properly
    // Will be passed in when we build the full logic — placeholder for now
    return runsNeeded.toDouble();
  }

  // Runs needed to win — shown in 2nd innings
  int get runsNeeded {
    if (currentInnings != 2 || firstInningsScore == null) return 0;
    return firstInningsScore! + 1 - totalRuns;
  }

  // ── copyWith ────────────────────────────────────────────────────
  // In Flutter BLoC, state is IMMUTABLE — you never modify existing state
  // Instead you create a NEW state copying old values + your changes
  // Example: emit(state.copyWith(totalRuns: state.totalRuns + 4))
  // This creates a new ScoringState with everything same except totalRuns
  ScoringState copyWith({
    List<Ball>? ballLog,
    int? totalRuns,
    int? wickets,
    int? overNumber,
    int? ballsInCurrentOver,
    String? strikerId,
    String? nonStrikerId,
    String? currentBowlerId,
    int? extras,
    int? currentInnings,
    int? firstInningsScore,
    bool? isMatchComplete,
    bool? isOverComplete,
    bool? isWicketJustFallen,
  }) {
    return ScoringState(
      ballLog: ballLog ?? this.ballLog,
      totalRuns: totalRuns ?? this.totalRuns,
      wickets: wickets ?? this.wickets,
      overNumber: overNumber ?? this.overNumber,
      ballsInCurrentOver: ballsInCurrentOver ?? this.ballsInCurrentOver,
      strikerId: strikerId ?? this.strikerId,
      nonStrikerId: nonStrikerId ?? this.nonStrikerId,
      currentBowlerId: currentBowlerId ?? this.currentBowlerId,
      extras: extras ?? this.extras,
      currentInnings: currentInnings ?? this.currentInnings,
      firstInningsScore: firstInningsScore ?? this.firstInningsScore,
      isMatchComplete: isMatchComplete ?? this.isMatchComplete,
      isOverComplete: isOverComplete ?? this.isOverComplete,
      isWicketJustFallen: isWicketJustFallen ?? this.isWicketJustFallen,
    );
  }

  // props = fields Equatable uses to check if state actually changed
  // BLoC only rebuilds UI if state actually changed
  // If you forget to add a field here — UI won't update when that field changes!
  @override
  List<Object?> get props => [
        ballLog,
        totalRuns,
        wickets,
        overNumber,
        ballsInCurrentOver,
        strikerId,
        nonStrikerId,
        currentBowlerId,
        extras,
        currentInnings,
        firstInningsScore,
        isMatchComplete,
        isOverComplete,
        isWicketJustFallen,
      ];
}