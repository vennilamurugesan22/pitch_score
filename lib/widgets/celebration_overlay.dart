import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ball_model.dart';
import '../theme/app_colors.dart';

// Full-screen pop animations drawn OVER the current screen:
//   SIX    → bat swings, ball flies out of the ground, confetti burst
//   FOUR   → ball races along the grass to the rope, burst at the boundary
//   WICKET → ball hits the stumps, bails fly, stumps scatter
//
// Usage: wrap a screen in CelebrationOverlay(key: _key, child: ...)
// and call _key.currentState?.playFor(ball).

enum Celebration { four, six, wicket }

class CelebrationOverlay extends StatefulWidget {
  final Widget child;
  const CelebrationOverlay({super.key, required this.child});

  @override
  CelebrationOverlayState createState() => CelebrationOverlayState();
}

class CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Celebration? _type;
  List<_Particle> _particles = const [];
  final _random = Random();

  static const _duration = Duration(milliseconds: 2000);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _type = null);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Plays the right animation for a delivery (no-op for ordinary balls)
  void playFor(Ball ball) {
    if (ball.isWicket) {
      play(Celebration.wicket);
    } else if (ball.isSix) {
      play(Celebration.six);
    } else if (ball.isFour) {
      play(Celebration.four);
    }
  }

  void play(Celebration type) {
    HapticFeedback.heavyImpact();
    final colors = switch (type) {
      Celebration.six => [
        AppColors.blue,
        Colors.white,
        AppColors.amber,
        AppColors.green,
      ],
      Celebration.four => [AppColors.green, Colors.white, AppColors.amber],
      Celebration.wicket => [AppColors.red, Colors.white, AppColors.amber],
    };
    setState(() {
      _type = type;
      _particles = List.generate(type == Celebration.six ? 70 : 45, (_) {
        final angle = _random.nextDouble() * 2 * pi;
        final speed = 250 + _random.nextDouble() * 550;
        return _Particle(
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 250,
          size: 4 + _random.nextDouble() * 7,
          color: colors[_random.nextInt(colors.length)],
          spin: (_random.nextDouble() - 0.5) * 12,
          isRect: _random.nextBool(),
        );
      });
    });
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_type != null)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => _buildFrame(_controller.value),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFrame(double t) {
    final type = _type!;
    final ms = t * _duration.inMilliseconds;
    final color = switch (type) {
      Celebration.six => AppColors.blue,
      Celebration.four => AppColors.green,
      Celebration.wicket => AppColors.red,
    };
    final label = switch (type) {
      Celebration.six => 'SIX!',
      Celebration.four => 'FOUR!',
      Celebration.wicket => 'OUT!',
    };
    // Text pops in at the moment of impact
    final impactMs = switch (type) {
      Celebration.six => 280.0,
      Celebration.four => 650.0,
      Celebration.wicket => 220.0,
    };

    // Background tint: fade in fast, hold, fade out at the end
    final fadeOut = ms > 1600 ? 1 - (ms - 1600) / 400 : 1.0;
    final tint = (ms < 150 ? ms / 150 : 1.0) * fadeOut;

    // Text: elastic pop after impact, then fade
    final textT = ((ms - impactMs) / 600).clamp(0.0, 1.0);
    final textScale = Curves.elasticOut.transform(textT) * 1.0;
    final shake =
        type == Celebration.wicket && ms > impactMs && ms < impactMs + 400
        ? sin((ms - impactMs) / 25) * 10
        : 0.0;

    return Stack(
      children: [
        // Radial glow tint over the screen
        Positioned.fill(
          child: Opacity(
            opacity: (tint * 0.85).clamp(0.0, 1.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.45),
                    AppColors.background.withValues(alpha: 0.75),
                  ],
                  radius: 0.9,
                ),
              ),
            ),
          ),
        ),
        // The scene: bat / ball / stumps / particles
        Positioned.fill(
          child: Opacity(
            opacity: fadeOut.clamp(0.0, 1.0),
            child: CustomPaint(
              painter: _ScenePainter(
                type: type,
                ms: ms,
                impactMs: impactMs,
                particles: _particles,
              ),
            ),
          ),
        ),
        // Big pop text
        Align(
          alignment: const Alignment(0, -0.42),
          child: Opacity(
            opacity: (textT > 0 ? 1.0 : 0.0) * fadeOut.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(shake, 0),
              child: Transform.scale(
                scale: textScale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 84,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 2,
                        color: color,
                        shadows: [
                          Shadow(color: color, blurRadius: 30),
                          const Shadow(
                            color: Colors.black54,
                            offset: Offset(3, 4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    if (type != Celebration.wicket)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          type == Celebration.six ? '+6 RUNS' : '+4 RUNS',
                          style: TextStyle(
                            color: AppColors.onAccent,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Particle {
  final double vx, vy, size, spin;
  final Color color;
  final bool isRect;
  const _Particle({
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.spin,
    required this.isRect,
  });
}

class _ScenePainter extends CustomPainter {
  final Celebration type;
  final double ms;
  final double impactMs;
  final List<_Particle> particles;

  _ScenePainter({
    required this.type,
    required this.ms,
    required this.impactMs,
    required this.particles,
  });

  static const _wood = Color(0xFFE8C07D);
  static const _woodDark = Color(0xFFB8894A);
  static const _ballRed = Color(0xFFD32F2F);

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case Celebration.six:
        _paintSix(canvas, size);
      case Celebration.four:
        _paintFour(canvas, size);
      case Celebration.wicket:
        _paintWicket(canvas, size);
    }
  }

  // ── SIX ──────────────────────────────────────────────────────
  void _paintSix(Canvas canvas, Size size) {
    final pivot = Offset(size.width * 0.30, size.height * 0.52);
    const batLen = 170.0;

    // Swing: raised behind (2.3 rad) → through the ball → follow-through
    final swingT = (ms / 420).clamp(0.0, 1.0);
    final angle = 2.3 - Curves.easeInCubic.transform(swingT) * 3.6;
    _paintBat(canvas, pivot, angle, batLen);

    // Contact point on the blade (where the bat is at impact)
    const contactAngle = -0.35;
    final contact =
        pivot + Offset(-sin(contactAngle), cos(contactAngle)) * (batLen * 0.72);

    if (ms < impactMs) {
      // Ball arriving from the bowler (right side, low)
      final p = (ms / impactMs).clamp(0.0, 1.0);
      final start = Offset(size.width * 1.05, size.height * 0.62);
      _paintBall(canvas, Offset.lerp(start, contact, p)!, 13, ms / 40);
      return;
    }

    // Impact flash
    final sinceImpact = ms - impactMs;
    if (sinceImpact < 160) {
      final r = 20 + sinceImpact / 160 * 60;
      canvas.drawCircle(
        contact,
        r,
        Paint()..color = Colors.white.withValues(alpha: 1 - sinceImpact / 160),
      );
    }

    // Ball flies high over the boundary with a trail
    final flight = (sinceImpact / 900).clamp(0.0, 1.0);
    Offset ballAt(double f) {
      final end = Offset(size.width * 1.1, -size.height * 0.15);
      final x = contact.dx + (end.dx - contact.dx) * f;
      final y =
          contact.dy +
          (end.dy - contact.dy) * f -
          sin(pi * f) * size.height * 0.12;
      return Offset(x, y);
    }

    for (var i = 1; i <= 6; i++) {
      final f = (flight - i * 0.035).clamp(0.0, 1.0);
      canvas.drawCircle(
        ballAt(f),
        11 * (1 - f * 0.6),
        Paint()..color = _ballRed.withValues(alpha: 0.25 - i * 0.035),
      );
    }
    if (flight < 1) {
      _paintBall(canvas, ballAt(flight), 13 * (1 - flight * 0.6), ms / 30);
    }

    _paintParticles(canvas, contact, sinceImpact);
  }

  void _paintBat(Canvas canvas, Offset pivot, double angle, double len) {
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    // Handle with grip stripes
    final handle = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-6, 0, 12, 52),
      const Radius.circular(5),
    );
    canvas.drawRRect(handle, Paint()..color = const Color(0xFF263238));
    final stripe = Paint()
      ..color = AppColors.green
      ..strokeWidth = 2;
    for (var y = 6.0; y < 50; y += 8) {
      canvas.drawLine(Offset(-6, y), Offset(6, y + 3), stripe);
    }
    // Blade
    final blade = RRect.fromRectAndRadius(
      Rect.fromLTWH(-18, 50, 36, len - 50),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      blade,
      Paint()
        ..shader = const LinearGradient(
          colors: [_woodDark, _wood, _woodDark],
        ).createShader(blade.outerRect),
    );
    // Sticker on the blade
    final sticker = Paint()..color = AppColors.green.withValues(alpha: 0.85);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-12, 62, 24, 26),
        const Radius.circular(4),
      ),
      sticker,
    );
    canvas.restore();
  }

  // ── FOUR ─────────────────────────────────────────────────────
  void _paintFour(Canvas canvas, Size size) {
    final groundY = size.height * 0.68;
    final ropeX = size.width * 0.9;

    // Grass strip + boundary rope
    canvas.drawRect(
      Rect.fromLTWH(0, groundY + 14, size.width, 6),
      Paint()..color = AppColors.green.withValues(alpha: 0.35),
    );
    final rope = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(ropeX - 20, groundY - 70)
      ..quadraticBezierTo(ropeX + 18, groundY - 10, ropeX - 10, groundY + 40);
    canvas.drawPath(path, rope);

    // Ball races along the ground and hits the rope at impactMs
    final p = Curves.easeIn.transform((ms / impactMs).clamp(0.0, 1.0));
    final x = size.width * 0.08 + (ropeX - 24 - size.width * 0.08) * p;
    final ball = Offset(x, groundY);
    // Speed lines
    for (var i = 1; i <= 5; i++) {
      final lx = x - i * 26;
      canvas.drawLine(
        Offset(lx, groundY - 6 + i * 2.0),
        Offset(lx - 30, groundY - 6 + i * 2.0),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35 - i * 0.05)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
    _paintBall(canvas, ball, 14, ms / 20);

    if (ms >= impactMs) {
      _paintParticles(canvas, Offset(ropeX - 10, groundY - 10), ms - impactMs);
    }
  }

  // ── WICKET ───────────────────────────────────────────────────
  void _paintWicket(Canvas canvas, Size size) {
    final base = Offset(size.width / 2, size.height * 0.72);
    const stumpH = 120.0;
    final hit = ms >= impactMs;
    final since = max(0.0, ms - impactMs);
    final fall = Curves.easeOutBack.transform((since / 450).clamp(0.0, 1.0));

    // Ball coming in from the left
    if (!hit) {
      final p = ms / impactMs;
      final start = Offset(-20, base.dy - 90);
      _paintBall(
        canvas,
        Offset.lerp(start, base + const Offset(-6, -55), p)!,
        13,
        ms / 30,
      );
    }

    // Three stumps, scattering after the hit
    final stump = Paint()..color = const Color(0xFFF5E6C8);
    final edge = Paint()
      ..color = _woodDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final tilts = [-0.55, 0.25, 0.7];
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(base.dx + (i - 1) * 22, base.dy);
      canvas.rotate(tilts[i] * fall);
      final r = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-5, -stumpH, 10, stumpH),
        const Radius.circular(4),
      );
      canvas.drawRRect(r, stump);
      canvas.drawRRect(r, edge);
      canvas.restore();
    }

    // Two bails flying off
    final bail = Paint()..color = AppColors.amber;
    for (var i = 0; i < 2; i++) {
      final dir = i == 0 ? -1.0 : 1.0;
      final s = since / 1000;
      final pos = Offset(
        base.dx + dir * 11 + dir * 260 * s,
        base.dy - stumpH - 4 - 420 * s + 0.5 * 900 * s * s,
      );
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(dir * since / 60);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-12, -3, 24, 6),
          const Radius.circular(3),
        ),
        bail,
      );
      canvas.restore();
    }

    if (hit) _paintParticles(canvas, base + const Offset(0, -stumpH), since);
  }

  // ── Shared pieces ────────────────────────────────────────────
  void _paintBall(Canvas canvas, Offset c, double r, double spin) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xFFFF6E6E), _ballRed, Color(0xFF8E1B1B)],
          center: const Alignment(-0.4, -0.4),
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // Rotating seam
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(spin);
    final seam = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.7),
      -pi / 3,
      2 * pi / 3,
      false,
      seam,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.7),
      2 * pi / 3,
      2 * pi / 3,
      false,
      seam,
    );
    canvas.restore();
  }

  void _paintParticles(Canvas canvas, Offset origin, double sinceMs) {
    final s = sinceMs / 1000;
    if (s > 1.4) return;
    final alpha = (1 - s / 1.4).clamp(0.0, 1.0);
    for (final p in particles) {
      final pos = origin + Offset(p.vx * s, p.vy * s + 0.5 * 700 * s * s);
      final paint = Paint()..color = p.color.withValues(alpha: alpha);
      if (p.isRect) {
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(p.spin * s);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.5,
          ),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(pos, p.size / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.ms != ms || old.type != type;
}
