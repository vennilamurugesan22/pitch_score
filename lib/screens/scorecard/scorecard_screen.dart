import 'package:flutter/material.dart';
import '../../bloc/scoring/innings_summary.dart';
import '../../bloc/scoring/scoring_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/scorecard_view.dart';

// Read-only full scorecard — one tab per innings.
// Used during a match, from history, and by spectators.
class ScorecardScreen extends StatelessWidget {
  final ScoringState state;
  const ScorecardScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final second = state.secondInningsSummary;
    final tabs = [
      Tab(text: state.teamName(state.battingFirstId)),
      if (second != null) Tab(text: state.teamName(state.bowlingFirstId)),
    ];

    return DefaultTabController(
      length: tabs.length,
      // Open on the innings in progress
      initialIndex: tabs.length - 1,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            '${state.teamOneName} vs ${state.teamTwoName}',
            overflow: TextOverflow.ellipsis,
          ),
          bottom: TabBar(
            tabs: tabs,
            indicatorColor: AppColors.green,
            labelColor: AppColors.green,
            unselectedLabelColor: AppColors.textSecondary,
          ),
        ),
        body: TabBarView(
          children: [
            _page(
              state.teamName(state.battingFirstId),
              state.firstInningsSummary,
            ),
            if (second != null)
              _page(state.teamName(state.bowlingFirstId), second),
          ],
        ),
      ),
    );
  }

  Widget _page(String team, InningsSummary summary) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      if (state.isMatchComplete || state.winnerTeamId != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            state.resultText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.amber,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      InningsScorecard(teamName: team, summary: summary),
    ],
  );
}
