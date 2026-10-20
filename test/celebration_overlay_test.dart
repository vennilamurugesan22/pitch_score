import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitch_score/widgets/celebration_overlay.dart';

void main() {
  testWidgets('six / four / wicket animations play to the end', (t) async {
    final key = GlobalKey<CelebrationOverlayState>();
    await t.pumpWidget(MaterialApp(
      home: CelebrationOverlay(key: key, child: const Scaffold()),
    ));

    for (final type in Celebration.values) {
      key.currentState!.play(type);
      // step through every frame of the 2s animation
      for (var ms = 0; ms <= 2100; ms += 50) {
        await t.pump(const Duration(milliseconds: 50));
        if (ms == 900) {
          final label = switch (type) {
            Celebration.six => 'SIX!',
            Celebration.four => 'FOUR!',
            Celebration.wicket => 'OUT!',
          };
          expect(find.text(label), findsOneWidget);
        }
      }
      // overlay removes itself when done
      expect(find.byType(CustomPaint).evaluate().length, lessThan(3));
      expect(find.text('SIX!'), findsNothing);
    }
  });
}
