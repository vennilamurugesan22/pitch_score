import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/scoring/scoring_bloc.dart';
import '../../bloc/scoring/scoring_event.dart';
import '../../bloc/scoring/scoring_state.dart';
import '../../theme/app_colors.dart';

// Shown between innings. Receives the live ScoringBloc from the scoring
// screen (which stays underneath in the navigation stack).
class InningsBreakScreen extends StatelessWidget {
  final ScoringBloc bloc;
  const InningsBreakScreen({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<ScoringBloc, ScoringState>(
        builder: (context, s) {
          final first = s.firstInningsSummary;
          final target = first.totalRuns + 1;
          final chasing = s.teamName(s.bowlingFirstId);
          final topBat = [...first.battingRows]
            ..sort((a, b) => b.runs.compareTo(a.runs));
          final topBowl = [...first.bowlingRows]
            ..sort(
              (a, b) => b.wickets != a.wickets
                  ? b.wickets.compareTo(a.wickets)
                  : a.runs.compareTo(b.runs),
            );

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Innings Break'),
              actions: [
                TextButton(
                  onPressed: () => context.push('/scorecard', extra: s),
                  child: const Text(
                    'Scorecard',
                    style: TextStyle(color: AppColors.green),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── 1st innings summary ─────────────────────
                  Text(
                    s.teamName(s.battingFirstId),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${first.scoreText}  (${first.oversText} ov)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── TARGET ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: AppColors.amberDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.amber),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'TARGET',
                          style: TextStyle(
                            color: AppColors.amber,
                            fontSize: 14,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                              '$target',
                              style: const TextStyle(
                                color: AppColors.amber,
                                fontSize: 80,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            )
                            .animate()
                            .scale(
                              begin: const Offset(0.4, 0.4),
                              duration: 600.ms,
                              curve: Curves.elasticOut,
                            )
                            .fadeIn(duration: 300.ms),
                        Text(
                          '$chasing need $target in ${s.totalOvers * 6} balls',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Required rate ${(target / s.totalOvers).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Top performers ──────────────────────────
                  if (topBat.isNotEmpty) ...[
                    _heading('Top batters'),
                    for (final r in topBat.take(3))
                      _line(r.player.name, '${r.runs} (${r.balls})'),
                  ],
                  if (topBowl.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _heading('Top bowlers'),
                    for (final r in topBowl.take(3))
                      _line(
                        r.player.name,
                        '${r.wickets}/${r.runs} (${r.oversText})',
                      ),
                  ],
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        bloc.add(const StartSecondInningsEvent());
                        context.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Start 2nd Innings',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      bloc.add(const UndoBallEvent());
                      context.pop();
                    },
                    child: const Text(
                      'Made a mistake? Undo last ball',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _heading(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      t,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _line(String name, String value) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.green,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
