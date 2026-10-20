import 'package:equatable/equatable.dart';
import '../../models/ball_model.dart';
import '../../models/match_model.dart';
import '../../models/player_model.dart';
import '../setup/match_setup_state.dart';
import 'innings_summary.dart';

// ScoringState = a snapshot of the entire match at any moment
// Every time a ball is bowled, BLoC emits a NEW ScoringState
// UI reads this state and redraws itself automatically
//
// Only the ball logs + who is at the crease are stored.
// Runs, wickets, overs, stats are all COMPUTED from the ball log
// ("event sourcing") — so undo is just "remove the last ball".

class ScoringState extends Equatable {

  // ── Match info (fixed once the match starts) ────────────────────
  final String matchId;
  final String matchCode; // empty = offline match
  final bool isLiveMode;
  final String teamOneName;
  final String teamTwoName;
  final List<Player> players;
  final int totalOvers;
  final int maxWickets;
  final String tossWinnerId; // 'team1' / 'team2'
  final String tossChoice; // 'bat' / 'bowl'
  final String battingFirstId; // 'team1' / 'team2'
  final DateTime? startedAt;

  // ── Progress ────────────────────────────────────────────────────

  // 1 = first innings, 2 = second innings (chase)
  final int currentInnings;

  // Completed 1st innings balls — only filled during 2nd innings
  final List<Ball> firstInningsBalls;

  // THE MOST IMPORTANT FIELD — every ball of the CURRENT innings
  final List<Ball> ballLog;

  // ── Players currently active ────────────────────────────────────
  final String strikerId;
  final String nonStrikerId;
  final String currentBowlerId;

  // ── Flags ───────────────────────────────────────────────────────
  // true = over just completed, waiting for scorer to pick next bowler
  final bool needsNewBowler;

  // true = overs / wickets / target reached — waiting for scorer to confirm
  final bool isInningsComplete;

  // true = match is finished, show result screen
  final bool isMatchComplete;

  const ScoringState({
    this.matchId = '',
    this.matchCode = '',
    this.isLiveMode = false,
    this.teamOneName = 'Team 1',
    this.teamTwoName = 'Team 2',
    this.players = const [],
    this.totalOvers = 6,
    this.maxWickets = 10,
    this.tossWinnerId = '',
    this.tossChoice = '',
    this.battingFirstId = 'team1',
    this.startedAt,
    this.currentInnings = 1,
    this.firstInningsBalls = const [],
    this.ballLog = const [],
    this.strikerId = '',
    this.nonStrikerId = '',
    this.currentBowlerId = '',
    this.needsNewBowler = false,
    this.isInningsComplete = false,
    this.isMatchComplete = false,
  });

  // Fresh match straight out of setup + toss
  factory ScoringState.newMatch({
    required String matchId,
    required MatchSetupState setup,
    required String tossWinnerId,
    required String tossChoice,
  }) {
    final battingFirst = tossChoice == 'bat'
        ? tossWinnerId
        : (tossWinnerId == 'team1' ? 'team2' : 'team1');
    return ScoringState(
      matchId: matchId,
      matchCode: setup.isLiveMode ? setup.matchCode : '',
      isLiveMode: setup.isLiveMode,
      teamOneName: setup.teamOneName,
      teamTwoName: setup.teamTwoName,
      players: setup.players,
      totalOvers: setup.totalOvers,
      maxWickets: setup.maxWickets,
      tossWinnerId: tossWinnerId,
      tossChoice: tossChoice,
      battingFirstId: battingFirst,
      startedAt: DateTime.now(),
    );
  }

  // ── Teams ───────────────────────────────────────────────────────
  String teamName(String teamId) =>
      teamId == 'team1' ? teamOneName : teamTwoName;

  String get bowlingFirstId => battingFirstId == 'team1' ? 'team2' : 'team1';

  String get battingTeamId =>
      currentInnings == 1 ? battingFirstId : bowlingFirstId;
  String get bowlingTeamId =>
      currentInnings == 1 ? bowlingFirstId : battingFirstId;

  String get battingTeamName => teamName(battingTeamId);
  String get bowlingTeamName => teamName(bowlingTeamId);

  List<Player> teamPlayers(String teamId) =>
      players.where((p) => p.teamId == teamId).toList();

  List<Player> get battingPlayers => teamPlayers(battingTeamId);
  List<Player> get bowlingPlayers => teamPlayers(bowlingTeamId);

  String playerName(String id) =>
      players.where((p) => p.id == id).firstOrNull?.name ?? '—';

  // A team of 5 can lose at most 4 wickets, whatever maxWickets says
  int wicketLimitFor(String teamId) {
    final squad = teamPlayers(teamId).length;
    final limit = squad - 1;
    return limit < maxWickets ? (limit < 1 ? 1 : limit) : maxWickets;
  }

  int get wicketLimit => wicketLimitFor(battingTeamId);

  // ── Innings summaries ───────────────────────────────────────────
  InningsSummary get summary => InningsSummary(
        balls: ballLog,
        battingPlayers: battingPlayers,
        bowlingPlayers: bowlingPlayers,
        atCrease: [strikerId, nonStrikerId],
      );

  InningsSummary get firstInningsSummary => currentInnings == 1
      ? summary
      : InningsSummary(
          balls: firstInningsBalls,
          battingPlayers: teamPlayers(battingFirstId),
          bowlingPlayers: teamPlayers(bowlingFirstId),
        );

  // null until the 2nd innings starts
  InningsSummary? get secondInningsSummary =>
      currentInnings == 2 ? summary : null;

  // ── Match progress (computed) ───────────────────────────────────
  int get totalRuns => ballLog.fold(0, (sum, b) => sum + b.totalRuns);
  int get wickets => ballLog.where((b) => b.isWicket).length;
  int get extras => ballLog.fold(0, (sum, b) => sum + b.extraRuns);
  int get legalBalls => ballLog.where((b) => b.isLegalDelivery).length;

  // Which over is being bowled (0-indexed) and legal balls in it (0-5)
  int get overNumber => legalBalls ~/ 6;
  int get ballsInCurrentOver => legalBalls % 6;

  // Display string for the scoreboard e.g. "147/4"
  String get scoreDisplay => '$totalRuns/$wickets';

  // Display string for overs e.g. "13.4" means Over 14, Ball 4
  String get oversDisplay => '$overNumber.$ballsInCurrentOver';

  // Current Run Rate = runs / overs
  double get currentRunRate =>
      legalBalls == 0 ? 0.0 : totalRuns / (legalBalls / 6);

  int? get firstInningsScore => currentInnings == 2
      ? firstInningsBalls.fold<int>(0, (sum, b) => sum + b.totalRuns)
      : null;

  // Target = 1st innings score + 1
  int? get target =>
      firstInningsScore == null ? null : firstInningsScore! + 1;

  // Runs needed to win — shown in 2nd innings
  int get runsNeeded {
    if (target == null) return 0;
    final n = target! - totalRuns;
    return n < 0 ? 0 : n;
  }

  int get ballsRemaining {
    final n = (totalOvers * 6) - legalBalls;
    return n < 0 ? 0 : n;
  }

  // Required Run Rate — only meaningful in 2nd innings
  double get requiredRunRate {
    if (target == null || ballsRemaining <= 0) return 0.0;
    return runsNeeded / (ballsRemaining / 6);
  }

  // Next legal ball is a free hit (previous non-wide ball was a no ball)
  bool get isFreeHit {
    for (var i = ballLog.length - 1; i >= 0; i--) {
      if (ballLog[i].isWide) continue;
      return ballLog[i].isNoBall;
    }
    return false;
  }

  // Scorer must pick openers before the first ball of an innings
  bool get needsOpeners =>
      !isInningsComplete &&
      (strikerId.isEmpty || nonStrikerId.isEmpty || currentBowlerId.isEmpty);

  // Scoring buttons enabled only when nothing is pending
  bool get canScore => !needsOpeners && !needsNewBowler && !isInningsComplete;

  // Batsmen who can still come in
  List<Player> get availableBatsmen {
    final out = summary.dismissedIds;
    return battingPlayers
        .where((p) =>
            !out.contains(p.id) && p.id != strikerId && p.id != nonStrikerId)
        .toList();
  }

  // Bowler of the over just finished — cannot bowl the next one
  String get lastOverBowlerId {
    final over = summary.lastCompletedOver;
    return over.isEmpty ? '' : over.first.bowlerId;
  }

  // ── Stats shortcuts (used by scoring screen widgets) ────────────
  int batsmanRuns(String id) => summary.battingRowFor(id)?.runs ?? 0;
  int batsmanBallsFaced(String id) => summary.battingRowFor(id)?.balls ?? 0;
  double batsmanStrikeRate(String id) =>
      summary.battingRowFor(id)?.strikeRate ?? 0;

  int get partnershipRuns => summary.partnershipRuns;
  int get partnershipBalls => summary.partnershipBalls;

  // ── Result ──────────────────────────────────────────────────────
  // 'team1' / 'team2' / 'tie' / null (not decided yet)
  String? get winnerTeamId {
    if (currentInnings != 2 || target == null) return null;
    if (totalRuns >= target!) return battingTeamId;
    if (!isInningsComplete && !isMatchComplete) return null;
    if (totalRuns == target! - 1) return 'tie';
    return bowlingTeamId;
  }

  String get resultText {
    final winner = winnerTeamId;
    if (winner == null) return 'Match in progress';
    if (winner == 'tie') return 'Match tied!';
    if (winner == battingTeamId) {
      final left = wicketLimit - wickets;
      return '${teamName(winner)} won by $left wicket${left == 1 ? '' : 's'}';
    }
    final margin = target! - 1 - totalRuns;
    return '${teamName(winner)} won by $margin run${margin == 1 ? '' : 's'}';
  }

  // Player of the match — simple points: 1 per run, 20 per wicket
  Player? get playerOfTheMatch {
    final points = <String, int>{};
    for (final innings in [firstInningsSummary, ?secondInningsSummary]) {
      for (final r in innings.battingRows) {
        points[r.player.id] = (points[r.player.id] ?? 0) + r.runs;
      }
      for (final r in innings.bowlingRows) {
        points[r.player.id] = (points[r.player.id] ?? 0) + r.wickets * 20;
      }
    }
    if (points.isEmpty) return null;
    final best = points.entries.reduce((a, b) => b.value > a.value ? b : a);
    return players.where((p) => p.id == best.key).firstOrNull;
  }

  // ── Conversion: Hive history ────────────────────────────────────
  Match toMatch() => Match(
        id: matchId,
        matchCode: matchCode,
        teamOneName: teamOneName,
        teamTwoName: teamTwoName,
        totalOvers: totalOvers,
        maxWickets: maxWickets,
        players: players,
        firstInningsBalls: currentInnings == 1 ? ballLog : firstInningsBalls,
        secondInningsBalls: currentInnings == 2 ? ballLog : const [],
        result: resultText,
        tossWinner: tossWinnerId,
        tossChoice: tossChoice,
        matchDate: startedAt ?? DateTime.now(),
        isLiveMode: isLiveMode,
        battingFirstTeamId: battingFirstId,
      );

  factory ScoringState.fromMatch(Match m) {
    final hasSecond = m.secondInningsBalls.isNotEmpty;
    return ScoringState(
      matchId: m.id,
      matchCode: m.matchCode,
      isLiveMode: m.isLiveMode,
      teamOneName: m.teamOneName,
      teamTwoName: m.teamTwoName,
      players: m.players,
      totalOvers: m.totalOvers,
      maxWickets: m.maxWickets,
      tossWinnerId: m.tossWinner ?? '',
      tossChoice: m.tossChoice ?? '',
      battingFirstId: m.battingFirstTeamId ?? 'team1',
      startedAt: m.matchDate,
      currentInnings: hasSecond ? 2 : 1,
      firstInningsBalls: hasSecond ? m.firstInningsBalls : const [],
      ballLog: hasSecond ? m.secondInningsBalls : m.firstInningsBalls,
      isInningsComplete: true,
      isMatchComplete: true,
    );
  }

  // ── Conversion: Firebase / resume (plain maps) ──────────────────
  Map<String, dynamic> toMap() => {
        'matchId': matchId,
        'matchCode': matchCode,
        'isLiveMode': isLiveMode,
        'teamOneName': teamOneName,
        'teamTwoName': teamTwoName,
        'players': players.map((p) => p.toMap()).toList(),
        'totalOvers': totalOvers,
        'maxWickets': maxWickets,
        'tossWinnerId': tossWinnerId,
        'tossChoice': tossChoice,
        'battingFirstId': battingFirstId,
        'startedAt': startedAt?.toIso8601String(),
        'currentInnings': currentInnings,
        'firstInningsBalls': firstInningsBalls.map((b) => b.toMap()).toList(),
        'ballLog': ballLog.map((b) => b.toMap()).toList(),
        'strikerId': strikerId,
        'nonStrikerId': nonStrikerId,
        'currentBowlerId': currentBowlerId,
        'needsNewBowler': needsNewBowler,
        'isInningsComplete': isInningsComplete,
        'isMatchComplete': isMatchComplete,
        // Handy for spectators who only want the headline
        'totalRuns': totalRuns,
        'wickets': wickets,
        'overs': oversDisplay,
      };

  factory ScoringState.fromMap(Map<dynamic, dynamic> map) {
    // Firebase returns lists either as List or as {0: .., 1: ..} maps
    List<Map<dynamic, dynamic>> list(dynamic v) {
      if (v is List) return v.whereType<Map>().toList();
      if (v is Map) {
        final keys = v.keys.toList()
          ..sort((a, b) => int.parse('$a').compareTo(int.parse('$b')));
        return keys.map((k) => v[k]).whereType<Map>().toList();
      }
      return const [];
    }

    return ScoringState(
      matchId: map['matchId'] ?? '',
      matchCode: map['matchCode'] ?? '',
      isLiveMode: map['isLiveMode'] == true,
      teamOneName: map['teamOneName'] ?? 'Team 1',
      teamTwoName: map['teamTwoName'] ?? 'Team 2',
      players: list(map['players'])
          .map((p) => Player(
                id: p['id'] ?? '',
                name: p['name'] ?? '',
                teamId: p['teamId'] ?? '',
              ))
          .toList(),
      totalOvers: (map['totalOvers'] as num?)?.toInt() ?? 6,
      maxWickets: (map['maxWickets'] as num?)?.toInt() ?? 10,
      tossWinnerId: map['tossWinnerId'] ?? '',
      tossChoice: map['tossChoice'] ?? '',
      battingFirstId: map['battingFirstId'] ?? 'team1',
      startedAt: DateTime.tryParse(map['startedAt'] ?? ''),
      currentInnings: (map['currentInnings'] as num?)?.toInt() ?? 1,
      firstInningsBalls:
          list(map['firstInningsBalls']).map(Ball.fromMap).toList(),
      ballLog: list(map['ballLog']).map(Ball.fromMap).toList(),
      strikerId: map['strikerId'] ?? '',
      nonStrikerId: map['nonStrikerId'] ?? '',
      currentBowlerId: map['currentBowlerId'] ?? '',
      needsNewBowler: map['needsNewBowler'] == true,
      isInningsComplete: map['isInningsComplete'] == true,
      isMatchComplete: map['isMatchComplete'] == true,
    );
  }

  // ── copyWith ────────────────────────────────────────────────────
  // State is IMMUTABLE — create a NEW state copying old values + changes
  ScoringState copyWith({
    String? matchCode,
    bool? isLiveMode,
    int? currentInnings,
    List<Ball>? firstInningsBalls,
    List<Ball>? ballLog,
    String? strikerId,
    String? nonStrikerId,
    String? currentBowlerId,
    bool? needsNewBowler,
    bool? isInningsComplete,
    bool? isMatchComplete,
  }) {
    return ScoringState(
      matchId: matchId,
      matchCode: matchCode ?? this.matchCode,
      isLiveMode: isLiveMode ?? this.isLiveMode,
      teamOneName: teamOneName,
      teamTwoName: teamTwoName,
      players: players,
      totalOvers: totalOvers,
      maxWickets: maxWickets,
      tossWinnerId: tossWinnerId,
      tossChoice: tossChoice,
      battingFirstId: battingFirstId,
      startedAt: startedAt,
      currentInnings: currentInnings ?? this.currentInnings,
      firstInningsBalls: firstInningsBalls ?? this.firstInningsBalls,
      ballLog: ballLog ?? this.ballLog,
      strikerId: strikerId ?? this.strikerId,
      nonStrikerId: nonStrikerId ?? this.nonStrikerId,
      currentBowlerId: currentBowlerId ?? this.currentBowlerId,
      needsNewBowler: needsNewBowler ?? this.needsNewBowler,
      isInningsComplete: isInningsComplete ?? this.isInningsComplete,
      isMatchComplete: isMatchComplete ?? this.isMatchComplete,
    );
  }

  // props = fields Equatable uses to check if state actually changed
  @override
  List<Object?> get props => [
        matchId,
        matchCode,
        isLiveMode,
        teamOneName,
        teamTwoName,
        players,
        totalOvers,
        maxWickets,
        tossWinnerId,
        tossChoice,
        battingFirstId,
        startedAt,
        currentInnings,
        firstInningsBalls,
        ballLog,
        strikerId,
        nonStrikerId,
        currentBowlerId,
        needsNewBowler,
        isInningsComplete,
        isMatchComplete,
      ];
}
