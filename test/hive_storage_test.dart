import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pitch_score/bloc/scoring/scoring_state.dart';
import 'package:pitch_score/models/ball_model.dart';
import 'package:pitch_score/models/match_model.dart';
import 'package:pitch_score/models/player_model.dart';

void main() {
  late Directory dir;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('pitch_score_hive');
    Hive.init(dir.path);
    Hive.registerAdapter(BallAdapter());
    Hive.registerAdapter(PlayerAdapter());
    Hive.registerAdapter(MatchAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  Ball ball({int runs = 4, bool wicket = false}) => Ball(
        runs: runs,
        isWicket: wicket,
        isWide: false,
        isNoBall: false,
        isBye: false,
        isLegBye: false,
        batsmanId: 'p1',
        bowlerId: 'p3',
        wicketType: wicket ? 'runout' : null,
        dismissedBatsmanId: wicket ? 'p2' : null,
        timestamp: DateTime(2026, 3, 19),
        strikerNameBefore: 'p1',
        nonStrikerNameBefore: 'p2',
      );

  test('save 1 Ball to Hive and read it back', () async {
    final box = await Hive.openBox<Ball>('test_balls');
    await box.put('test', ball(wicket: true));
    await box.close();

    final reopened = await Hive.openBox<Ball>('test_balls');
    final b = reopened.get('test')!;
    expect(b.runs, 4);
    expect(b.isWicket, true);
    expect(b.dismissedBatsmanId, 'p2');
    expect(b.timestamp, DateTime(2026, 3, 19));
  });

  test('finished match round trips through Hive into a scorecard', () async {
    final players = [
      Player(id: 'p1', name: 'Ravi', teamId: 'team1'),
      Player(id: 'p2', name: 'Arun', teamId: 'team1'),
      Player(id: 'p3', name: 'Kumar', teamId: 'team2'),
      Player(id: 'p4', name: 'Vijay', teamId: 'team2'),
    ];
    final state = ScoringState(
      matchId: 'm1',
      teamOneName: 'Chennai XI',
      teamTwoName: 'Mumbai Kings',
      players: players,
      battingFirstId: 'team1',
      ballLog: [ball(), ball(runs: 6)],
      isInningsComplete: true,
      startedAt: DateTime(2026, 3, 19),
    );

    final box = await Hive.openBox<Match>('matches_test');
    await box.put('m1', state.toMatch());
    await box.close();

    final m = (await Hive.openBox<Match>('matches_test')).get('m1')!;
    expect(m.teamOneName, 'Chennai XI');
    expect(m.battingFirstTeamId, 'team1');
    final back = ScoringState.fromMatch(m);
    expect(back.firstInningsSummary.totalRuns, 10);
    expect(back.firstInningsSummary.battingRowFor('p1')!.runs, 10);
    expect(back.firstInningsSummary.battingRowFor('p1')!.player.name, 'Ravi');
  });
}
