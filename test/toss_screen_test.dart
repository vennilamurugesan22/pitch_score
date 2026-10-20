import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitch_score/bloc/setup/match_setup_state.dart';
import 'package:pitch_score/screens/toss/toss_screen.dart';

void main() {
  testWidgets('toss gives both heads and tails, coin face matches result',
      (t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 2.625;
    addTearDown(t.view.reset);

    await t.pumpWidget(const MaterialApp(
      home: TossScreen(
        matchSetup: MatchSetupState(teamOneName: 'A', teamTwoName: 'B'),
      ),
    ));

    final results = <String>[];
    for (var i = 0; i < 30; i++) {
      // Coin shows H before the flip; tap it
      await t.tap(find.byType(GestureDetector).at(4));
      await t.pumpAndSettle();
      final heads = find.text('HEADS').evaluate().isNotEmpty;
      final tails = find.text('TAILS').evaluate().isNotEmpty;
      expect(heads ^ tails, isTrue, reason: 'exactly one result shown');
      // The coin must land on the same face the result says
      expect(find.text(heads ? 'H' : 'T'), findsOneWidget);
      results.add(heads ? 'H' : 'T');
      await t.tap(find.text('Flip again'));
      await t.pumpAndSettle();
    }
    debugPrint('Toss results: ${results.join()}  heads=${results.where((r) => r == 'H').length} tails=${results.where((r) => r == 'T').length}');
    // 30 fair flips all landing the same way has odds of ~1 in 500 million
    expect(results.toSet(), {'H', 'T'}, reason: 'got $results');
  });

  testWidgets('first flip on a fresh toss screen is random', (t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 2.625;
    addTearDown(t.view.reset);
    final results = <String>[];
    for (var i = 0; i < 30; i++) {
      await t.pumpWidget(MaterialApp(
        key: ValueKey(i),
        home: const TossScreen(
          matchSetup: MatchSetupState(teamOneName: 'A', teamTwoName: 'B'),
        ),
      ));
      await t.tap(find.text('?'));
      await t.pumpAndSettle();
      results.add(find.text('HEADS').evaluate().isNotEmpty ? 'H' : 'T');
    }
    debugPrint('First flips: ${results.join()}');
    expect(results.toSet(), {'H', 'T'});
  });
}
