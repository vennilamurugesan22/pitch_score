import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../bloc/history/match_history_bloc.dart';
import '../../bloc/history/match_history_event.dart';
import '../../bloc/history/match_history_state.dart';
import '../../bloc/scoring/scoring_state.dart';
import '../../models/match_model.dart';
import '../../theme/app_colors.dart';

class MatchHistoryScreen extends StatelessWidget {
  const MatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Match History')),
      body: BlocBuilder<MatchHistoryBloc, MatchHistoryState>(
        builder: (context, state) {
          if (state is MatchHistoryError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: AppColors.red),
              ),
            );
          }
          if (state is! MatchHistoryLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.green),
            );
          }
          if (state.matches.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sports_cricket,
                      color: AppColors.textHint,
                      size: 56,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No matches yet',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Finished matches are saved here automatically',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.matches.length + 1,
            itemBuilder: (context, i) {
              if (i == state.matches.length) {
                return const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Swipe a match left to delete it',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textHint, fontSize: 11),
                  ),
                );
              }
              final m = state.matches[i];
              return Dismissible(
                key: ValueKey(m.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.only(right: 20),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: AppColors.redDark,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.delete_outline, color: AppColors.red),
                ),
                confirmDismiss: (_) => showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text(
                      'Delete match?',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: AppColors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                onDismissed: (_) => context.read<MatchHistoryBloc>().add(
                  DeleteMatchEvent(m.id),
                ),
                child: MatchCard(match: m),
              );
            },
          );
        },
      ),
    );
  }
}

// Summary card — used here and on the home screen
class MatchCard extends StatelessWidget {
  final Match match;
  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final s = ScoringState.fromMatch(match);
    final first = s.firstInningsSummary;
    final second = s.secondInningsSummary;

    Widget teamLine(String teamId, String score, String overs) => Row(
      children: [
        Expanded(
          child: Text(
            s.teamName(teamId),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: s.winnerTeamId == teamId
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          score,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '($overs)',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/scorecard', extra: s),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      DateFormat('d MMM yyyy · h:mm a').format(match.matchDate),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${match.totalOvers} overs',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                teamLine(s.battingFirstId, first.scoreText, first.oversText),
                const SizedBox(height: 4),
                teamLine(
                  s.bowlingFirstId,
                  second?.scoreText ?? '—',
                  second?.oversText ?? '-',
                ),
                const SizedBox(height: 10),
                Text(
                  match.result ?? s.resultText,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
