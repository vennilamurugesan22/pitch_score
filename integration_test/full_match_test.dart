// End-to-end: Setup → Toss → 1st innings → Innings break → 2nd innings →
// Result → History. Runs the real app on a device / emulator:
//
//   flutter test integration_test/full_match_test.dart -d emulator-5554

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pitch_score/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Slow emulators: keep pumping until the widget shows up (max 20s)
  Future<void> waitFor(WidgetTester t, Finder f) async {
    for (var i = 0; i < 80 && f.evaluate().isEmpty; i++) {
      await t.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> tapText(WidgetTester t, String text) async {
    final f = find.text(text);
    await waitFor(t, f);
    await t.ensureVisible(f.last);
    await t.pumpAndSettle();
    await t.tap(f.last);
    await t.pumpAndSettle();
  }

  Future<void> pad(WidgetTester t, String label) async {
    await t.tap(find.byKey(ValueKey('pad-$label')));
    // let celebration flash timers finish
    await t.pumpAndSettle(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 800));
    await t.pumpAndSettle();
  }

  // Pick the first bowler who didn't bowl the last over
  Future<void> pickNextBowler(WidgetTester t, List<String> bowlers) async {
    expect(find.text('Over complete! Next bowler'), findsOneWidget);
    for (final b in bowlers) {
      final row = find.text(b);
      await t.tap(row.last);
      await t.pumpAndSettle();
      final start = t.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Start next over'));
      if (start.onPressed != null) break;
    }
    await tapText(t, 'Start next over');
  }

  testWidgets('full match flow', (t) async {
    app.main();
    await t.pump(const Duration(seconds: 1));
    // start from a clean slate
    if (Hive.isBoxOpen('active_match')) await Hive.box('active_match').clear();
    await t.pump(const Duration(seconds: 3)); // splash
    await t.pumpAndSettle();

    // ── Setup ───────────────────────────────────────────────────
    await tapText(t, 'New Match');
    final fields = find.byType(TextField);
    await t.enterText(fields.at(0), 'Chennai XI');
    await t.enterText(fields.at(1), 'Mumbai Kings');
    await tapText(t, '4 ov');
    await tapText(t, '3 wkts');

    Future<void> addPlayer(String name) async {
      await t.enterText(find.byType(TextField).at(2), name);
      await t.tap(find.byIcon(Icons.add).last);
      await t.pumpAndSettle();
      expect(find.text(name), findsOneWidget);
    }

    for (final p in ['Ravi', 'Arun', 'Karthik']) {
      await addPlayer(p);
    }
    await tapText(t, 'Mumbai Kings'); // team tab
    for (final p in ['Vijay', 'Kumar', 'Suresh']) {
      await addPlayer(p);
    }
    expect(find.text('Chennai XI: 3 players'), findsOneWidget);
    expect(find.text('Mumbai Kings: 3 players'), findsOneWidget);
    await tapText(t, 'Proceed to Toss 🏏');

    // ── Toss ────────────────────────────────────────────────────
    await tapText(t, 'Chennai XI'); // calling team
    await tapText(t, 'Heads');
    await t.tap(find.text('?'));
    await t.pumpAndSettle(const Duration(seconds: 2));
    expect(find.textContaining('wins the toss!'), findsOneWidget);
    await tapText(t, '🏏  BAT');
    await tapText(t, 'Start Match! 🏏');

    // Who bats first depends on the coin
    final chennaiBat =
        find.text('Chennai XI bat · Mumbai Kings bowl').evaluate().isNotEmpty;
    final batFirst = chennaiBat ? ['Ravi', 'Arun', 'Karthik'] : ['Vijay', 'Kumar', 'Suresh'];
    final bowlFirst = chennaiBat ? ['Vijay', 'Kumar', 'Suresh'] : ['Ravi', 'Arun', 'Karthik'];

    // ── Openers ─────────────────────────────────────────────────
    await tapText(t, "Let's play 🏏");
    expect(find.text('0/0'), findsOneWidget);

    // ── 1st innings ─────────────────────────────────────────────
    // Over 1: 4, 6, 1, Wd, •, 2, W  (6 legal + 1 wide)
    await pad(t, '4');
    expect(find.text('4/0'), findsOneWidget);
    await pad(t, '6');
    await pad(t, '1');
    await pad(t, 'Wd');
    await tapText(t, 'Wd'); // plain wide in the sheet
    await pad(t, '•');
    await pad(t, '2');
    expect(find.text('14/0'), findsOneWidget);
    await pad(t, 'W');
    expect(find.text('Wicket! How out?'), findsOneWidget);
    await tapText(t, 'Confirm wicket'); // only one batter left → auto-picked
    expect(find.text('14/1'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 600));
    await t.pumpAndSettle();
    await pickNextBowler(t, bowlFirst);

    // Undo works and can be redone
    await pad(t, '4');
    expect(find.text('18/1'), findsOneWidget);
    await pad(t, '↩');
    await tapText(t, 'Undo');
    expect(find.text('14/1'), findsOneWidget);

    // Over 2: NB+4 then 6 dots
    await pad(t, 'NB');
    await tapText(t, 'NB +4');
    expect(find.text('19/1'), findsOneWidget);
    expect(find.text('FREE HIT'), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      await pad(t, '•');
    }
    await pickNextBowler(t, bowlFirst);

    // Overs 3 & 4: singles and leg byes
    for (var over = 0; over < 2; over++) {
      for (var i = 0; i < 5; i++) {
        await pad(t, '1');
      }
      await pad(t, 'LB');
      await tapText(t, '2 LB');
      if (over == 0) await pickNextBowler(t, bowlFirst);
    }
    // 19 + 2*(5+2) = 33 → innings over after 4 overs
    expect(find.text('33/1'), findsOneWidget);

    // ── Innings break ───────────────────────────────────────────
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
    expect(find.text('TARGET'), findsOneWidget);
    expect(find.text('34'), findsOneWidget);
    await tapText(t, 'Start 2nd Innings');

    // ── 2nd innings ─────────────────────────────────────────────
    expect(find.text('Chase openers'), findsOneWidget);
    await tapText(t, "Let's play 🏏");
    expect(find.text('Need 34 runs from 24 balls'), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      await pad(t, '6'); // 36 off 6 balls — chased in the 1st over
    }
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
    expect(find.text('Match over! 🏆'), findsOneWidget);
    final winner = chennaiBat ? 'Mumbai Kings' : 'Chennai XI';
    expect(find.text('$winner won by 2 wickets'), findsWidgets);
    await tapText(t, 'See result');

    // ── Result ──────────────────────────────────────────────────
    expect(find.text('Match Result'), findsOneWidget);
    expect(find.text('$winner won by 2 wickets'), findsWidgets);
    expect(find.textContaining('Player of the match'), findsOneWidget);
    expect(find.textContaining(batFirst.first), findsWidgets);

    // ── Share: renders the scorecard PNG and opens the share sheet
    await t.tap(find.text('Share'));
    await t.pump(const Duration(seconds: 3));
    expect(find.textContaining('Could not share'), findsNothing);

    // ── Home → History ──────────────────────────────────────────
    // The OS share sheet stays open (its spinner never settles), so tap
    // Done directly instead of waiting for the screen to settle
    await t.tap(find.text('Done'));
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(milliseconds: 250));
    }
    await waitFor(t, find.text('Recent match'));
    expect(find.text('Recent match'), findsOneWidget);
    await tapText(t, 'History');
    expect(find.text('$winner won by 2 wickets'), findsOneWidget);
  });
}
