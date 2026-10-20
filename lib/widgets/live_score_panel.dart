import 'package:flutter/material.dart';
import '../bloc/scoring/scoring_state.dart';
import '../theme/app_colors.dart';
import 'ball_circle.dart';

// Score header + chase bar + this over + batsmen + bowler.
// Shared by the scorer's ScoringScreen and the spectator's WatchLiveScreen,
// so both always look identical. Purely presentational.
class LiveScorePanel extends StatelessWidget {
  final ScoringState state;
  final VoidCallback? onSwapStrike; // null = spectator, no button

  const LiveScorePanel({super.key, required this.state, this.onSwapStrike});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScoreHeader(state: state),
        if (state.currentInnings == 2 && state.target != null) ...[
          const SizedBox(height: 10),
          ChaseBar(state: state),
        ],
        const SizedBox(height: 10),
        ThisOverRow(state: state),
        const SizedBox(height: 10),
        BatsmenCard(state: state, onSwapStrike: onSwapStrike),
        const SizedBox(height: 8),
        BowlerCard(state: state),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _Card({required this.child, this.padding = const EdgeInsets.all(12)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

// ── Big score ────────────────────────────────────────────────────
class ScoreHeader extends StatelessWidget {
  final ScoringState state;
  const ScoreHeader({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Text(
            '${state.battingTeamName} · ${state.currentInnings == 1 ? '1st' : '2nd'} innings',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  // Score pops when it changes
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, a) => ScaleTransition(
                      scale: Tween(begin: 1.25, end: 1.0).animate(a),
                      child: FadeTransition(opacity: a, child: child),
                    ),
                    child: Text(
                      state.scoreDisplay,
                      key: ValueKey(state.scoreDisplay),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '(${state.oversDisplay}/${state.totalOvers})',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            children: [
              _mini('CRR', state.currentRunRate.toStringAsFixed(2)),
              _mini('Extras', '${state.extras}'),
              _mini('P\'ship', '${state.partnershipRuns} (${state.partnershipBalls})'),
            ],
          ),
          if (state.isFreeHit && state.canScore) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.amberDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.amber),
              ),
              child: const Text(
                'FREE HIT',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _mini(String label, String value) => Text.rich(
        TextSpan(children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),
      );
}

// ── Target / RRR — 2nd innings only ──────────────────────────────
class ChaseBar extends StatelessWidget {
  final ScoringState state;
  const ChaseBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        children: [
          Text(
            state.runsNeeded == 0
                ? 'Target reached!'
                : 'Need ${state.runsNeeded} run${state.runsNeeded == 1 ? '' : 's'} from ${state.ballsRemaining} ball${state.ballsRemaining == 1 ? '' : 's'}',
            style: const TextStyle(
              color: AppColors.amber,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _rateItem('TARGET', '${state.target}', AppColors.amber),
              _rateItem('CRR', state.currentRunRate.toStringAsFixed(2), AppColors.green),
              _rateItem('RRR', state.requiredRunRate.toStringAsFixed(2), AppColors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rateItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ── This over ────────────────────────────────────────────────────
class ThisOverRow extends StatelessWidget {
  final ScoringState state;
  const ThisOverRow({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final summary = state.summary;
    // While waiting for a new bowler, keep showing the over just finished
    final showLast = state.needsNewBowler || state.isInningsComplete;
    final balls = showLast && summary.currentOverBalls.isEmpty
        ? summary.lastCompletedOver
        : summary.currentOverBalls;
    final legal = balls.where((b) => b.isLegalDelivery).length;
    final overRuns = balls.fold(0, (sum, b) => sum + b.totalRuns);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                showLast && balls.isNotEmpty ? 'Last over' : 'This over',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              const Spacer(),
              Text(
                '$overRuns run${overRuns == 1 ? '' : 's'}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              children: [
                ...balls.map((b) => BallCircle(ball: b)),
                ...List.generate(
                  (6 - legal).clamp(0, 6),
                  (_) => const BallCircle(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Batsmen ──────────────────────────────────────────────────────
class BatsmenCard extends StatelessWidget {
  final ScoringState state;
  final VoidCallback? onSwapStrike;
  const BatsmenCard({super.key, required this.state, this.onSwapStrike});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Batter',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ),
              _head('R'),
              _head('B'),
              _head('4s'),
              _head('6s'),
              _head('SR', width: 44),
            ],
          ),
          const SizedBox(height: 6),
          _row(state.strikerId, true),
          const Divider(color: AppColors.border, height: 14),
          _row(state.nonStrikerId, false),
          if (onSwapStrike != null && state.canScore) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onSwapStrike,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.textSecondary,
                ),
                icon: const Icon(Icons.swap_vert, size: 16),
                label: const Text('Swap strike', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _head(String t, {double width = 30}) => SizedBox(
        width: width,
        child: Text(t,
            textAlign: TextAlign.right,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      );

  Widget _row(String id, bool isStriker) {
    final row = state.summary.battingRowFor(id);
    final color = isStriker ? AppColors.textPrimary : AppColors.textSecondary;
    Widget cell(String t, {double width = 30, bool bold = false}) => SizedBox(
          width: width,
          child: Text(
            t,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: bold && isStriker ? AppColors.green : color,
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        );

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: isStriker ? AppColors.green : Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            id.isEmpty ? '—' : state.playerName(id),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: isStriker ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        cell('${row?.runs ?? 0}', bold: true),
        cell('${row?.balls ?? 0}'),
        cell('${row?.fours ?? 0}'),
        cell('${row?.sixes ?? 0}'),
        cell((row?.strikeRate ?? 0).toStringAsFixed(0), width: 44),
      ],
    );
  }
}

// ── Bowler ───────────────────────────────────────────────────────
class BowlerCard extends StatelessWidget {
  final ScoringState state;
  const BowlerCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final row = state.summary.bowlingRowFor(state.currentBowlerId);
    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.sports_baseball, color: AppColors.textSecondary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.currentBowlerId.isEmpty ? '—' : state.playerName(state.currentBowlerId),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // O-M-R-W  Econ
          Text(
            '${row?.oversText ?? '0.0'}-${row?.maidens ?? 0}-${row?.runs ?? 0}-${row?.wickets ?? 0}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Econ ${(row?.economy ?? 0).toStringAsFixed(2)}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
