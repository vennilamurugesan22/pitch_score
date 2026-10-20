import '../../models/ball_model.dart';
import '../../models/player_model.dart';

// Everything about ONE innings, computed from its ball log.
// Nothing here is stored — the ball log is the single source of truth.
// Used by the scoring screen, scorecard, result, history and watch-live.

class BattingRow {
  final Player player;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final bool isOut;
  final String howOut; // "b Ravi", "run out", "not out"

  const BattingRow({
    required this.player,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.isOut,
    required this.howOut,
  });

  double get strikeRate => balls == 0 ? 0 : runs * 100 / balls;
}

class BowlingRow {
  final Player player;
  final int legalBalls;
  final int maidens;
  final int runs;
  final int wickets;
  final int wides;
  final int noBalls;

  const BowlingRow({
    required this.player,
    required this.legalBalls,
    required this.maidens,
    required this.runs,
    required this.wickets,
    required this.wides,
    required this.noBalls,
  });

  // "3.4" = 3 overs 4 balls
  String get oversText => '${legalBalls ~/ 6}.${legalBalls % 6}';

  double get economy => legalBalls == 0 ? 0 : runs / (legalBalls / 6);
}

class FallOfWicket {
  final int wicketNumber;
  final int score;
  final String batsmanName;
  final String overText;

  const FallOfWicket({
    required this.wicketNumber,
    required this.score,
    required this.batsmanName,
    required this.overText,
  });
}

class OverSummary {
  final int overNumber; // 1-based
  final String bowlerName;
  final List<Ball> balls;
  final int runs;
  final int scoreAtEnd;
  final int wicketsAtEnd;

  const OverSummary({
    required this.overNumber,
    required this.bowlerName,
    required this.balls,
    required this.runs,
    required this.scoreAtEnd,
    required this.wicketsAtEnd,
  });
}

class InningsSummary {
  final List<Ball> balls;
  final List<Player> battingPlayers;
  final List<Player> bowlingPlayers;

  // Batsmen currently at the crease — so a new batsman who has not faced yet
  // still appears in the scorecard
  final List<String> atCrease;

  InningsSummary({
    required this.balls,
    required this.battingPlayers,
    required this.bowlingPlayers,
    this.atCrease = const [],
  });

  // ── Totals ──────────────────────────────────────────────────────
  int get totalRuns => balls.fold(0, (sum, b) => sum + b.totalRuns);
  int get wickets => balls.where((b) => b.isWicket).length;
  int get legalBalls => balls.where((b) => b.isLegalDelivery).length;

  String get oversText => '${legalBalls ~/ 6}.${legalBalls % 6}';
  String get scoreText => '$totalRuns/$wickets';

  double get runRate => legalBalls == 0 ? 0 : totalRuns / (legalBalls / 6);

  // ── Extras breakdown ────────────────────────────────────────────
  int get wides =>
      balls.where((b) => b.isWide).fold(0, (sum, b) => sum + b.totalRuns);
  int get noBalls => balls.where((b) => b.isNoBall).length;
  int get byes => balls
      .where((b) => b.isBye && !b.isWide)
      .fold(0, (sum, b) => sum + b.runs);
  int get legByes =>
      balls.where((b) => b.isLegBye).fold(0, (sum, b) => sum + b.runs);
  int get extras => balls.fold(0, (sum, b) => sum + b.extraRuns);

  // ── Batting ─────────────────────────────────────────────────────
  // Order of appearance at the crease
  List<String> get battingOrder {
    final order = <String>[];
    void add(String id) {
      if (id.isNotEmpty && !order.contains(id)) order.add(id);
    }

    for (final b in balls) {
      add(b.strikerNameBefore);
      add(b.nonStrikerNameBefore);
    }
    atCrease.forEach(add);
    return order;
  }

  Set<String> get dismissedIds =>
      balls.map((b) => b.outBatsmanId).whereType<String>().toSet();

  List<BattingRow> get battingRows {
    return battingOrder.map((id) {
      final player = _find(battingPlayers, id);
      final faced = balls.where((b) => b.batsmanId == id);
      final outBall = balls.where((b) => b.outBatsmanId == id).firstOrNull;
      return BattingRow(
        player: player,
        runs: faced.fold(0, (sum, b) => sum + b.batsmanRuns),
        balls: faced.where((b) => b.isFacedByBatsman).length,
        fours: faced.where((b) => b.isFour).length,
        sixes: faced.where((b) => b.isSix).length,
        isOut: outBall != null,
        howOut: outBall == null ? 'not out' : _howOut(outBall),
      );
    }).toList();
  }

  // Players who never came in
  List<Player> get didNotBat {
    final order = battingOrder;
    return battingPlayers.where((p) => !order.contains(p.id)).toList();
  }

  BattingRow? battingRowFor(String id) =>
      battingRows.where((r) => r.player.id == id).firstOrNull;

  String _howOut(Ball b) {
    final bowler = _find(bowlingPlayers, b.bowlerId).name;
    switch (b.wicketType) {
      case 'bowled':
        return 'b $bowler';
      case 'caught':
        return 'caught b $bowler';
      case 'lbw':
        return 'lbw b $bowler';
      case 'stumped':
        return 'st b $bowler';
      case 'hitwicket':
        return 'hit wkt b $bowler';
      case 'runout':
        return 'run out';
      default:
        return 'out';
    }
  }

  // ── Bowling ─────────────────────────────────────────────────────
  List<BowlingRow> get bowlingRows {
    final order = <String>[];
    for (final b in balls) {
      if (b.bowlerId.isNotEmpty && !order.contains(b.bowlerId)) {
        order.add(b.bowlerId);
      }
    }
    final allOvers = overs;
    return order.map((id) {
      final bowled = balls.where((b) => b.bowlerId == id);
      final maidens = allOvers
          .where((o) =>
              o.balls.first.bowlerId == id &&
              o.balls.where((b) => b.isLegalDelivery).length == 6 &&
              o.balls.every((b) => b.bowlerRuns == 0))
          .length;
      return BowlingRow(
        player: _find(bowlingPlayers, id),
        legalBalls: bowled.where((b) => b.isLegalDelivery).length,
        maidens: maidens,
        runs: bowled.fold(0, (sum, b) => sum + b.bowlerRuns),
        wickets: bowled.where((b) => b.isBowlerWicket).length,
        wides: bowled.where((b) => b.isWide).length,
        noBalls: bowled.where((b) => b.isNoBall).length,
      );
    }).toList();
  }

  BowlingRow? bowlingRowFor(String id) =>
      bowlingRows.where((r) => r.player.id == id).firstOrNull;

  // ── Overs ───────────────────────────────────────────────────────
  // Groups balls into overs — an over closes after 6 legal deliveries
  List<List<Ball>> get overGroups {
    final groups = <List<Ball>>[];
    var current = <Ball>[];
    var legal = 0;
    for (final b in balls) {
      current.add(b);
      if (b.isLegalDelivery) legal++;
      if (legal == 6) {
        groups.add(current);
        current = [];
        legal = 0;
      }
    }
    if (current.isNotEmpty) groups.add(current);
    return groups;
  }

  List<OverSummary> get overs {
    var score = 0;
    var wkts = 0;
    final result = <OverSummary>[];
    final groups = overGroups;
    for (var i = 0; i < groups.length; i++) {
      final g = groups[i];
      final runs = g.fold(0, (sum, b) => sum + b.totalRuns);
      score += runs;
      wkts += g.where((b) => b.isWicket).length;
      result.add(OverSummary(
        overNumber: i + 1,
        bowlerName: _find(bowlingPlayers, g.first.bowlerId).name,
        balls: g,
        runs: runs,
        scoreAtEnd: score,
        wicketsAtEnd: wkts,
      ));
    }
    return result;
  }

  // Balls of the over currently in progress (empty right after an over ends)
  List<Ball> get currentOverBalls {
    final groups = overGroups;
    if (groups.isEmpty) return const [];
    final last = groups.last;
    final complete = last.where((b) => b.isLegalDelivery).length == 6;
    return complete ? const [] : last;
  }

  // Balls of the last completed over
  List<Ball> get lastCompletedOver {
    final groups = overGroups;
    for (var i = groups.length - 1; i >= 0; i--) {
      if (groups[i].where((b) => b.isLegalDelivery).length == 6) {
        return groups[i];
      }
    }
    return const [];
  }

  // ── Fall of wickets ─────────────────────────────────────────────
  List<FallOfWicket> get fallOfWickets {
    final result = <FallOfWicket>[];
    var score = 0;
    var legal = 0;
    for (final b in balls) {
      score += b.totalRuns;
      if (b.isLegalDelivery) legal++;
      if (b.isWicket) {
        result.add(FallOfWicket(
          wicketNumber: result.length + 1,
          score: score,
          batsmanName: _find(battingPlayers, b.outBatsmanId!).name,
          overText: '${legal ~/ 6}.${legal % 6}',
        ));
      }
    }
    return result;
  }

  // ── Partnership ─────────────────────────────────────────────────
  List<Ball> get _sinceLastWicket {
    final i = balls.lastIndexWhere((b) => b.isWicket);
    return balls.sublist(i + 1);
  }

  int get partnershipRuns =>
      _sinceLastWicket.fold(0, (sum, b) => sum + b.totalRuns);
  int get partnershipBalls =>
      _sinceLastWicket.where((b) => b.isLegalDelivery).length;

  static Player _find(List<Player> players, String id) {
    return players.where((p) => p.id == id).firstOrNull ??
        Player(id: id, name: id.isEmpty ? '—' : 'Unknown', teamId: '');
  }
}
