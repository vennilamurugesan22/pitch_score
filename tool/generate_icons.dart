// Renders the PitchScore logo to PNGs for launcher icons / store listing.
//   flutter test tool/generate_icons.dart
//   dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitch_score/widgets/app_logo.dart';

Future<void> _render(String path, CustomPainter painter, int px) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), Size.square(px.toDouble()));
  final image = await recorder.endRecording().toImage(px, px);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  await File(path).writeAsBytes(bytes!.buffer.asUint8List());
}

void main() {
  test('generate logo PNGs', () async {
    // Full icon (iOS, legacy Android, Play Store 512 is scaled from this)
    await _render('assets/logo/app_icon.png', const LogoPainter(), 1024);
    // Android adaptive foreground: transparent, artwork in the safe zone
    await _render('assets/logo/adaptive_foreground.png',
        const LogoPainter(background: false, scale: 0.9), 1024);
    // Play Store hi-res icon
    await _render('assets/logo/play_store_512.png', const LogoPainter(), 512);
  });
}
