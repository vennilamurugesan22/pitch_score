import 'dart:math';

import 'package:flutter/material.dart';

// PitchScore logo — drawn in code so it is sharp at every size.
// The same painter generates the launcher icon PNGs
// (tool/generate_icons.dart → assets/logo/).
//
//   dark tile · green stadium ring · bat · red ball breaking out · live arcs

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.23),
      child: CustomPaint(
        size: Size.square(size),
        painter: const LogoPainter(),
      ),
    );
  }
}

class LogoPainter extends CustomPainter {
  // background = false → transparent (Android adaptive-icon foreground)
  final bool background;
  // Shrinks the artwork towards the centre (adaptive icons need padding)
  final double scale;

  const LogoPainter({this.background = true, this.scale = 0.9});

  static const green = Color(0xFF00C853);
  static const greenLight = Color(0xFF69F0AE);
  static const ballRed = Color(0xFFE53935);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    if (background) _paintBackground(canvas, s);

    canvas.save();
    canvas.translate(s / 2, s / 2);
    canvas.scale(scale);
    canvas.translate(-s / 2, -s / 2);

    final c = Offset(s * 0.5, s * 0.5);
    final ringR = s * 0.33;

    // ── Stadium ring with a gap top-right where the ball breaks out
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.045
      ..strokeCap = StrokeCap.round;
    // glow
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: ringR),
      -pi * 0.18,
      pi * 1.62,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.09
        ..strokeCap = StrokeCap.round
        ..color = green.withValues(alpha: 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.03),
    );
    ring.shader = const SweepGradient(
      colors: [greenLight, green, Color(0xFF009624), green, greenLight],
    ).createShader(Rect.fromCircle(center: c, radius: ringR));
    canvas.drawArc(Rect.fromCircle(center: c, radius: ringR), -pi * 0.18,
        pi * 1.62, false, ring);

    // ── Bat — handle bottom-left, blade up towards the ball
    _paintBat(canvas, s);

    // ── Ball breaking out of the ring (top-right gap)
    final ballC = c + Offset(cos(-pi * 0.33), sin(-pi * 0.33)) * ringR;
    final ballR = s * 0.085;
    // speed streaks behind the ball (towards the bat)
    final streak = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.022;
    for (var i = 0; i < 3; i++) {
      final off = (i - 1) * s * 0.045;
      final dir = Offset(-0.62, 0.78);
      final perp = Offset(dir.dy, -dir.dx);
      final start = ballC + dir * (ballR * 1.25) + perp * off;
      final end = start + dir * (s * (0.10 - i.abs() * 0.0));
      streak.color = Colors.white.withValues(alpha: 0.55 - (i - 1).abs() * 0.2);
      canvas.drawLine(start, end, streak);
    }
    canvas.drawCircle(
      ballC,
      ballR * 1.5,
      Paint()
        ..color = ballRed.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.03),
    );
    canvas.drawCircle(
      ballC,
      ballR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: const [Color(0xFFFF8A80), ballRed, Color(0xFF8E1B1B)],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: ballC, radius: ballR)),
    );
    // seam
    canvas.save();
    canvas.translate(ballC.dx, ballC.dy);
    canvas.rotate(-0.6);
    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.008
      ..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawArc(Rect.fromCircle(center: Offset(-ballR * 1.25, 0), radius: ballR * 1.1),
        -0.75, 1.5, false, seam);
    canvas.drawArc(Rect.fromCircle(center: Offset(ballR * 1.25, 0), radius: ballR * 1.1),
        pi - 0.75, 1.5, false, seam);
    canvas.restore();

    // ── "Live" signal arcs off the ball
    final live = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.022;
    for (var i = 0; i < 2; i++) {
      final r = ballR * (1.65 + i * 0.6);
      live.color = greenLight.withValues(alpha: 0.9 - i * 0.35);
      canvas.drawArc(Rect.fromCircle(center: ballC, radius: r), -pi * 0.62,
          pi * 0.55, false, live);
    }

    canvas.restore();
  }

  void _paintBackground(Canvas canvas, double s) {
    final rect = Rect.fromLTWH(0, 0, s, s);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2A3A), Color(0xFF0F0F1A)],
        ).createShader(rect),
    );
    // soft green glow from below
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.6),
          radius: 0.8,
          colors: [green.withValues(alpha: 0.22), Colors.transparent],
        ).createShader(rect),
    );
  }

  void _paintBat(Canvas canvas, double s) {
    canvas.save();
    // handle bottom-left, blade swinging up-right towards the ball
    canvas.translate(s * 0.24, s * 0.80);
    canvas.rotate(pi * 1.22);
    final len = s * 0.54;
    final handleLen = len * 0.30;
    final bladeW = s * 0.115;

    // handle
    final handle = RRect.fromRectAndRadius(
      Rect.fromLTWH(-s * 0.022, -handleLen * 0.15, s * 0.044, handleLen),
      Radius.circular(s * 0.02),
    );
    // rubber grip: green with dark wraps and a light edge
    canvas.drawRRect(handle, Paint()..color = green);
    final wrap = Paint()
      ..color = const Color(0xFF00701A)
      ..strokeWidth = s * 0.009
      ..strokeCap = StrokeCap.round;
    for (var y = 0.0; y < handleLen * 0.8; y += s * 0.026) {
      canvas.drawLine(Offset(-s * 0.02, y), Offset(s * 0.02, y + s * 0.012), wrap);
    }
    canvas.drawRRect(
      handle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.004
        ..color = Colors.white.withValues(alpha: 0.5),
    );

    // blade
    final blade = RRect.fromRectAndCorners(
      Rect.fromLTWH(-bladeW / 2, handleLen * 0.8, bladeW, len - handleLen * 0.8),
      topLeft: Radius.circular(s * 0.03),
      topRight: Radius.circular(s * 0.03),
      bottomLeft: Radius.circular(s * 0.05),
      bottomRight: Radius.circular(s * 0.05),
    );
    canvas.drawRRect(
      blade.shift(Offset(s * 0.012, s * 0.012)),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    canvas.drawRRect(
      blade,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFC8954F), Color(0xFFF7D9A0), Color(0xFFD9A862)],
          stops: [0, 0.45, 1],
        ).createShader(blade.outerRect),
    );
    // ridge line down the blade
    canvas.drawLine(
      Offset(0, handleLen * 0.95),
      Offset(0, len * 0.93),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = s * 0.006,
    );
    // green sticker
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-bladeW * 0.32, handleLen * 0.95, bladeW * 0.64, len * 0.14),
        Radius.circular(s * 0.012),
      ),
      Paint()..color = const Color(0xFF1A1A2E),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(LogoPainter old) =>
      old.background != background || old.scale != scale;
}
