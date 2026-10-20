import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitch_score/bloc/history/match_history_bloc.dart';
import 'package:pitch_score/bloc/scoring/scoring_state.dart';
import 'package:pitch_score/models/player_model.dart';
import 'package:pitch_score/screens/scoring/scoring_screen.dart';

void main() {
  testWidgets('hitting a six shows the SIX! celebration', (t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 2.625;
    addTearDown(t.view.reset);

    final state = ScoringState(
      players: [
        Player(id: 'a1', name: 'A1', teamId: 'team1'),
        Player(id: 'a2', name: 'A2', teamId: 'team1'),
        Player(id: 'b1', name: 'B1', teamId: 'team2'),
        Player(id: 'b2', name: 'B2', teamId: 'team2'),
      ],
      strikerId: 'a1',
      nonStrikerId: 'a2',
      currentBowlerId: 'b1',
    );
    await t.pumpWidget(BlocProvider(
      create: (_) => MatchHistoryBloc(),
      child: MaterialApp(home: ScoringScreen(initialState: state)),
    ));
    await t.pump();

    await t.tap(find.byKey(const ValueKey('pad-6')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('6/0'), findsOneWidget);
    expect(find.text('SIX!'), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('share button on a live match shows code + link', (t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 2.625;
    addTearDown(t.view.reset);
    final state = ScoringState(
      isLiveMode: true,
      matchCode: '651813',
      teamOneName: 'Super Kings',
      teamTwoName: 'Royal Strikers',
      players: [
        Player(id: 'a1', name: 'A1', teamId: 'team1'),
        Player(id: 'a2', name: 'A2', teamId: 'team1'),
        Player(id: 'b1', name: 'B1', teamId: 'team2'),
      ],
      strikerId: 'a1',
      nonStrikerId: 'a2',
      currentBowlerId: 'b1',
    );
    await t.pumpWidget(BlocProvider(
      create: (_) => MatchHistoryBloc(),
      child: MaterialApp(home: ScoringScreen(initialState: state)),
    ));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('share-live')));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Share the live score'), findsOneWidget);
    expect(find.text('651813'), findsOneWidget);
    expect(find.text('https://pitchscore-d15a6.web.app/watch/651813'),
        findsOneWidget);
    expect(find.text('Share link'), findsOneWidget);
    expect(find.text('Copy link'), findsOneWidget);
    // dispose the forever-pulsing LIVE badge before the test ends
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
  });
}
