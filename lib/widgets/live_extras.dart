import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../bloc/scoring/scoring_state.dart';
import '../models/ball_model.dart';
import '../theme/app_colors.dart';
import 'ball_circle.dart';

// ── Pulsing red LIVE badge ───────────────────────────────────────
class LiveBadge extends StatelessWidget {
  final String? code;
  const LiveBadge({super.key, this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.red,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.red.withValues(alpha: 0.5),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fade(begin: 1, end: 0.2, duration: 700.ms)
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(0.6, 0.6),
                  ),
              const SizedBox(width: 6),
              Text(
                code == null ? 'LIVE' : 'LIVE · $code',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 1,
          end: 1.06,
          duration: 900.ms,
          curve: Curves.easeInOut,
        );
  }
}

// ── Quick insights strip ─────────────────────────────────────────
class MatchInsights extends StatelessWidget {
  final ScoringState state;
  const MatchInsights({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final balls = state.ballLog;
    final fours = balls.where((b) => b.isFour).length;
    final sixes = balls.where((b) => b.isSix).length;
    final legal = balls.where((b) => b.isLegalDelivery).toList();
    final dots = legal.where((b) => b.totalRuns == 0 && !b.isWicket).length;
    final dotPct = legal.isEmpty ? 0 : (dots * 100 / legal.length).round();
    final projected = (state.currentRunRate * state.totalOvers).round();

    final items = <(String, String, Color)>[
      if (state.currentInnings == 1)
        ('Projected', '$projected', AppColors.amber)
      else
        ('Need', '${state.runsNeeded}', AppColors.amber),
      ('4s', '$fours', AppColors.green),
      ('6s', '$sixes', AppColors.blue),
      ('Dots', '$dotPct%', AppColors.textSecondary),
    ];

    return Row(
      children: [
        for (final (label, value, color) in items)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, a) =>
                        ScaleTransition(scale: a, child: child),
                    child: Text(
                      value,
                      key: ValueKey(value),
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Ball-by-ball commentary ──────────────────────────────────────
class BallByBallFeed extends StatelessWidget {
  final ScoringState state;
  final int maxItems;
  const BallByBallFeed({super.key, required this.state, this.maxItems = 12});

  @override
  Widget build(BuildContext context) {
    // Over.ball label for each delivery ("2.3")
    final entries = <(String, Ball, int)>[];
    var legal = 0;
    for (var i = 0; i < state.ballLog.length; i++) {
      final b = state.ballLog[i];
      if (b.isLegalDelivery) legal++;
      final over = b.isLegalDelivery ? (legal - 1) ~/ 6 : legal ~/ 6;
      final ballNo = b.isLegalDelivery ? (legal - 1) % 6 + 1 : legal % 6;
      entries.add(('$over.$ballNo', b, i));
    }
    final recent = entries.reversed.take(maxItems).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mic_none, color: AppColors.textSecondary, size: 16),
              SizedBox(width: 6),
              Text(
                'Ball by ball',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Waiting for the first ball…',
                style: TextStyle(color: AppColors.textHint),
              ),
            ),
          for (var k = 0; k < recent.length; k++)
            _row(recent[k], isLatest: k == 0),
        ],
      ),
    );
  }

  Widget _row((String, Ball, int) e, {required bool isLatest}) {
    final (over, ball, index) = e;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Text(
              over,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          BallCircle(ball: ball, size: 26),
          const SizedBox(width: 4),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text:
                        '${state.playerName(ball.bowlerId)} to ${state.playerName(ball.batsmanId)}: ',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  TextSpan(
                    text: commentaryFor(ball, index),
                    style: TextStyle(
                      color: ball.isWicket
                          ? AppColors.red
                          : ball.isSix
                          ? AppColors.blue
                          : ball.isFour
                          ? AppColors.green
                          : AppColors.textPrimary,
                      fontWeight: (ball.isWicket || ball.isFour || ball.isSix)
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
    // Newest line slides in
    return isLatest
        ? row
              .animate(key: ValueKey(index))
              .fadeIn(duration: 300.ms)
              .slideX(begin: -0.1)
        : row;
  }

  // Short, varied commentary line
  String commentaryFor(Ball b, int i) {
    String pick(List<String> options) => options[i % options.length];
    if (b.isWicket) {
      final who = state.playerName(b.outBatsmanId ?? b.batsmanId);
      return switch (b.wicketType) {
        'bowled' => pick([
          'OUT! Clean bowled — $who has to go!',
          'OUT! Timber! $who bowled',
        ]),
        'caught' => pick([
          'OUT! Caught — $who holes out',
          'OUT! Taken! $who is caught',
        ]),
        'lbw' => 'OUT! Plumb in front — $who LBW',
        'runout' => 'OUT! Run out — $who short of the crease',
        'stumped' => 'OUT! Stumped — $who caught out of the crease',
        'hitwicket' => 'OUT! Hit wicket — $who knocks the bails off',
        _ => 'OUT! $who departs',
      };
    }
    if (b.isWide)
      return b.runs > 0 ? 'Wide, and they run ${b.runs}' : 'Wide ball';
    if (b.isNoBall) {
      return b.runs > 0
          ? 'No ball! ${b.runs} off the bat — FREE HIT next'
          : 'No ball — FREE HIT next';
    }
    if (b.isLegBye) return '${b.runs} leg bye${b.runs == 1 ? '' : 's'}';
    if (b.isBye) return '${b.runs} bye${b.runs == 1 ? '' : 's'}';
    return switch (b.runs) {
      6 => pick([
        'SIX! Huge hit into the crowd 🚀',
        'SIX! That\'s out of the ground!',
        'SIX! Massive!',
      ]),
      4 => pick([
        'FOUR! Races to the boundary',
        'FOUR! Beautiful shot',
        'FOUR! Finds the gap',
      ]),
      0 => pick(['Dot ball, well bowled', 'No run', 'Defended']),
      1 => pick(['Single taken', 'Pushed for one', 'Quick single']),
      2 => pick(['Two runs', 'Good running, two']),
      3 => 'Three runs — great running!',
      _ => '${b.runs} runs',
    };
  }
}
