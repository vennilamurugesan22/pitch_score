import 'package:flutter_test/flutter_test.dart';
import 'package:pitch_score/bloc/scoring/scoring_bloc.dart';
import 'package:pitch_score/bloc/scoring/scoring_event.dart';
import 'package:pitch_score/bloc/scoring/scoring_rules.dart';
import 'package:pitch_score/bloc/scoring/scoring_state.dart';
import 'package:pitch_score/models/ball_model.dart';
import 'package:pitch_score/models/player_model.dart';

// Team 1 bats first: a1, a2, a3, a4   Team 2 bowls: b1, b2, b3, b4
final _players = [
  for (final id in ['a1', 'a2', 'a3', 'a4']) Player(id: id, name: id, teamId: 'team1'),
  for (final id in ['b1', 'b2', 'b3', 'b4']) Player(id: id, name: id, teamId: 'team2'),
];

ScoringState _start({int overs = 2, int maxWickets = 10}) => ScoringState(
      players: _players,
      totalOvers: overs,
      maxWickets: maxWickets,
      battingFirstId: 'team1',
      strikerId: 'a1',
      nonStrikerId: 'a2',
      currentBowlerId: 'b1',
    );

Ball _ball(
  ScoringState s, {
  int runs = 0,
  bool wide = false,
  bool noBall = false,
  bool bye = false,
  bool legBye = false,
  bool wicket = false,
  String? wicketType,
  String? dismissed,
}) =>
    Ball(
      runs: runs,
      isWicket: wicket,
      isWide: wide,
      isNoBall: noBall,
      isBye: bye,
      isLegBye: legBye,
      batsmanId: s.strikerId,
      bowlerId: s.currentBowlerId,
      wicketType: wicketType ?? (wicket ? 'bowled' : null),
      dismissedBatsmanId: dismissed,
      timestamp: DateTime(2026),
      strikerNameBefore: s.strikerId,
      nonStrikerNameBefore: s.nonStrikerId,
    );

// Shortcut: apply a ball built from the current state
ScoringState _add(ScoringState s,
        {int runs = 0,
        bool wide = false,
        bool noBall = false,
        bool bye = false,
        bool legBye = false,
        bool wicket = false,
        String? wicketType,
        String? dismissed,
        String? newBatsman}) =>
    ScoringRules.addBall(
      s,
      _ball(s,
          runs: runs,
          wide: wide,
          noBall: noBall,
          bye: bye,
          legBye: legBye,
          wicket: wicket,
          wicketType: wicketType,
          dismissed: dismissed),
      newBatsmanId: newBatsman,
    );

ScoringState _dots(ScoringState s, int n) {
  for (var i = 0; i < n; i++) {
    s = _add(s);
  }
  return s;
}

void main() {
  group('Runs and striker swap', () {
    test('dot ball — counts in over, no swap', () {
      final s = _add(_start());
      expect(s.totalRuns, 0);
      expect(s.legalBalls, 1);
      expect(s.strikerId, 'a1');
    });

    test('1 run — swap', () {
      final s = _add(_start(), runs: 1);
      expect(s.totalRuns, 1);
      expect(s.strikerId, 'a2');
      expect(s.nonStrikerId, 'a1');
    });

    test('2 runs — no swap', () {
      final s = _add(_start(), runs: 2);
      expect(s.strikerId, 'a1');
    });

    test('3 runs — swap', () {
      final s = _add(_start(), runs: 3);
      expect(s.strikerId, 'a2');
    });

    test('4 and 6 — no swap, boundaries counted', () {
      var s = _add(_start(), runs: 4);
      s = _add(s, runs: 6);
      expect(s.totalRuns, 10);
      expect(s.strikerId, 'a1');
      final row = s.summary.battingRowFor('a1')!;
      expect(row.fours, 1);
      expect(row.sixes, 1);
      expect(row.balls, 2);
    });

    test('single on last ball of over — same striker keeps strike', () {
      var s = _dots(_start(), 5);
      s = _add(s, runs: 1);
      // odd run swap + end of over swap cancel out
      expect(s.strikerId, 'a1');
      expect(s.overNumber, 1);
      expect(s.ballsInCurrentOver, 0);
    });

    test('dot on last ball — end of over swaps', () {
      final s = _dots(_start(), 6);
      expect(s.strikerId, 'a2');
      expect(s.needsNewBowler, true);
    });

    test('manual swap strike', () async {
      final bloc = ScoringBloc(_start());
      bloc.add(const SwapStrikeEvent());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.strikerId, 'a2');
      await bloc.close();
    });
  });

  group('Extras', () {
    test('plain wide — 1 extra, not counted in over, no swap', () {
      final s = _add(_start(), wide: true);
      expect(s.totalRuns, 1);
      expect(s.extras, 1);
      expect(s.legalBalls, 0);
      expect(s.strikerId, 'a1');
      expect(s.summary.battingRowFor('a1')!.balls, 0);
    });

    test('wide + 1 run — 2 extras, batsmen crossed', () {
      final s = _add(_start(), wide: true, runs: 1);
      expect(s.totalRuns, 2);
      expect(s.extras, 2);
      expect(s.strikerId, 'a2');
    });

    test('no ball — 1 extra, not in over, counts as ball faced, free hit', () {
      final s = _add(_start(), noBall: true);
      expect(s.totalRuns, 1);
      expect(s.legalBalls, 0);
      expect(s.summary.battingRowFor('a1')!.balls, 1);
      expect(s.isFreeHit, true);
      // free hit continues through a wide
      expect(_add(s, wide: true).isFreeHit, true);
      // and ends after a legal ball
      expect(_add(s).isFreeHit, false);
    });

    test('no ball hit for 4 — batsman gets 4, total 5', () {
      final s = _add(_start(), noBall: true, runs: 4);
      expect(s.totalRuns, 5);
      expect(s.extras, 1);
      expect(s.batsmanRuns('a1'), 4);
      expect(s.summary.bowlingRowFor('b1')!.runs, 5);
    });

    test('no ball + 1 run — swap', () {
      final s = _add(_start(), noBall: true, runs: 1);
      expect(s.strikerId, 'a2');
    });

    test('leg byes — extras, not batsman runs, not bowler runs, swap on odd', () {
      final s = _add(_start(), legBye: true, runs: 1);
      expect(s.totalRuns, 1);
      expect(s.extras, 1);
      expect(s.batsmanRuns('a1'), 0);
      expect(s.summary.bowlingRowFor('b1')!.runs, 0);
      expect(s.legalBalls, 1);
      expect(s.strikerId, 'a2');
    });

    test('byes', () {
      final s = _add(_start(), bye: true, runs: 4);
      expect(s.summary.byes, 4);
      expect(s.extras, 4);
      expect(s.strikerId, 'a1');
    });

    test('over has 6 legal balls even with wides', () {
      var s = _add(_start(), wide: true);
      s = _add(s, noBall: true);
      s = _dots(s, 5);
      expect(s.needsNewBowler, false);
      s = _add(s);
      expect(s.needsNewBowler, true);
      expect(s.ballLog.length, 8);
      expect(s.oversDisplay, '1.0');
    });
  });

  group('Wickets', () {
    test('bowled — new batsman takes strike', () {
      final s = _add(_start(), wicket: true, newBatsman: 'a3');
      expect(s.wickets, 1);
      expect(s.strikerId, 'a3');
      expect(s.nonStrikerId, 'a2');
      expect(s.summary.battingRowFor('a1')!.howOut, 'b b1');
      expect(s.summary.bowlingRowFor('b1')!.wickets, 1);
    });

    test('wicket on last ball — new batsman goes to non-striker end', () {
      var s = _dots(_start(), 5);
      s = _add(s, wicket: true, newBatsman: 'a3');
      expect(s.strikerId, 'a2');
      expect(s.nonStrikerId, 'a3');
      expect(s.needsNewBowler, true);
    });

    test('run out of non-striker — not a bowler wicket', () {
      final s = _add(_start(),
          wicket: true,
          wicketType: 'runout',
          dismissed: 'a2',
          runs: 1,
          newBatsman: 'a3');
      expect(s.totalRuns, 1);
      expect(s.batsmanRuns('a1'), 1);
      // ran 1 → a1 crossed to the other end; a2 out replaced by a3
      expect({s.strikerId, s.nonStrikerId}, {'a1', 'a3'});
      expect(s.summary.bowlingRowFor('b1')!.wickets, 0);
      expect(s.summary.battingRowFor('a2')!.howOut, 'run out');
    });

    test('available batsmen excludes out + at crease', () {
      final s = _add(_start(), wicket: true, newBatsman: 'a3');
      expect(s.availableBatsmen.map((p) => p.id), ['a4']);
    });

    test('all out — team of 4 is all out after 3 wickets', () {
      var s = _add(_start(), wicket: true, newBatsman: 'a3');
      s = _add(s, wicket: true, newBatsman: 'a4');
      expect(s.isInningsComplete, false);
      s = _add(s, wicket: true);
      expect(s.wickets, 3);
      expect(s.isInningsComplete, true);
      expect(s.canScore, false);
    });

    test('maxWickets smaller than squad', () {
      var s = _add(_start(maxWickets: 1), wicket: true);
      expect(s.isInningsComplete, true);
    });

    test('fall of wickets', () {
      var s = _add(_start(), runs: 4);
      s = _add(s, wicket: true, newBatsman: 'a3');
      final fow = s.summary.fallOfWickets.single;
      expect(fow.score, 4);
      expect(fow.overText, '0.2');
      expect(fow.batsmanName, 'a1');
    });
  });

  group('Overs and innings', () {
    test('all overs bowled ends innings, no bowler prompt', () {
      final s = _dots(_start(overs: 1), 6);
      expect(s.isInningsComplete, true);
      expect(s.needsNewBowler, false);
    });

    test('balls ignored once innings is complete', () {
      final s = _dots(_start(overs: 1), 6);
      expect(_add(s, runs: 4).totalRuns, 0);
    });

    test('scoring blocked until new bowler picked', () {
      final s = _dots(_start(), 6);
      expect(s.canScore, false);
      expect(_add(s, runs: 4).totalRuns, 0);
    });

    test('maiden over', () {
      final s = _dots(_start(), 6);
      expect(s.summary.bowlingRowFor('b1')!.maidens, 1);
      expect(s.summary.bowlingRowFor('b1')!.oversText, '1.0');
    });

    test('second innings — chase won by wickets', () {
      var s = _add(_start(overs: 1), runs: 6);
      s = _dots(s, 5); // 6/0 in 1 over
      expect(s.isInningsComplete, true);
      s = ScoringRules.startSecondInnings(s);
      expect(s.currentInnings, 2);
      expect(s.battingTeamId, 'team2');
      expect(s.target, 7);
      expect(s.needsOpeners, true);
      s = s.copyWith(strikerId: 'b1', nonStrikerId: 'b2', currentBowlerId: 'a1');
      expect(s.ballLog, isEmpty);
      s = _add(s, runs: 4);
      expect(s.runsNeeded, 3);
      expect(s.requiredRunRate, closeTo(3 / (5 / 6), 0.001));
      s = _add(s, runs: 4);
      expect(s.isInningsComplete, true);
      expect(s.winnerTeamId, 'team2');
      expect(s.resultText, 'Team 2 won by 3 wickets');
    });

    test('second innings — defended, won by runs', () {
      var s = _add(_start(overs: 1), runs: 6);
      s = _dots(s, 5);
      s = ScoringRules.startSecondInnings(s)
          .copyWith(strikerId: 'b1', nonStrikerId: 'b2', currentBowlerId: 'a1');
      s = _add(s, runs: 2);
      s = _dots(s, 5);
      expect(s.isInningsComplete, true);
      expect(s.resultText, 'Team 1 won by 4 runs');
    });

    test('tie', () {
      var s = _add(_start(overs: 1), runs: 4);
      s = _dots(s, 5);
      s = ScoringRules.startSecondInnings(s)
          .copyWith(strikerId: 'b1', nonStrikerId: 'b2', currentBowlerId: 'a1');
      s = _add(s, runs: 4);
      s = _dots(s, 5);
      expect(s.winnerTeamId, 'tie');
    });
  });

  group('Undo', () {
    test('undo restores score, strike and over', () {
      var s = _add(_start(), runs: 1);
      s = ScoringRules.undo(s);
      expect(s.totalRuns, 0);
      expect(s.legalBalls, 0);
      expect(s.strikerId, 'a1');
    });

    test('undo wicket brings batsman back', () {
      var s = _add(_start(), wicket: true, newBatsman: 'a3');
      s = ScoringRules.undo(s);
      expect(s.wickets, 0);
      expect(s.strikerId, 'a1');
      expect(s.nonStrikerId, 'a2');
    });

    test('undo across over boundary restores previous bowler', () {
      var s = _dots(_start(), 6);
      s = s.copyWith(currentBowlerId: 'b2', needsNewBowler: false);
      s = _add(s, runs: 2);
      expect(s.summary.bowlingRowFor('b2')!.runs, 2);
      s = ScoringRules.undo(s); // back to start of over 2, b2 bowling
      expect(s.currentBowlerId, 'b2');
      s = ScoringRules.undo(s); // back into over 1 — b1 again
      expect(s.currentBowlerId, 'b1');
      expect(s.oversDisplay, '0.5');
      expect(s.needsNewBowler, false);
    });

    test('undo the innings-ending ball reopens the innings', () {
      var s = _dots(_start(overs: 1), 6);
      expect(s.isInningsComplete, true);
      s = ScoringRules.undo(s);
      expect(s.isInningsComplete, false);
      expect(s.canScore, true);
    });

    test('undo with empty log does nothing', () {
      final s = _start();
      expect(ScoringRules.undo(s), s);
    });
  });

  group('Serialisation', () {
    test('toMap / fromMap round trip', () {
      var s = _add(_start(), runs: 4);
      s = _add(s, wide: true, runs: 1);
      s = _add(s, wicket: true, newBatsman: 'a3');
      final back = ScoringState.fromMap(s.toMap());
      expect(back.totalRuns, s.totalRuns);
      expect(back.wickets, 1);
      expect(back.strikerId, s.strikerId);
      expect(back.players.length, 8);
      expect(back.summary.battingRows.length, s.summary.battingRows.length);
    });

    test('fromMap accepts Firebase index maps for lists', () {
      final map = _add(_start(), runs: 2).toMap();
      map['ballLog'] = {'0': (map['ballLog'] as List).first};
      expect(ScoringState.fromMap(map).totalRuns, 2);
    });
  });
}
