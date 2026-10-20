import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../bloc/history/match_history_bloc.dart';
import '../../bloc/history/match_history_state.dart';
import '../../services/local/match_storage.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/update_checker.dart';
import '../history/match_history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = MatchStorage();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Optional / force update dialog (once per launch)
            const UpdateChecker(),

            // ── App name + settings ───────────────────────────
            Row(
              children: [
                Hero(
                  tag: 'app-logo',
                  child: const AppLogo(size: 44),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'PitchScore',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Resume an unfinished match ────────────────────
            ValueListenableBuilder<Box>(
              valueListenable: storage.listenable(),
              builder: (context, _, _) {
                final active = storage.loadActiveMatch();
                if (active == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Material(
                    color: AppColors.amberDark,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.push('/scoring', extra: active),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.amber),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.play_circle_fill,
                              color: AppColors.amber,
                              size: 36,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Resume match',
                                    style: TextStyle(
                                      color: AppColors.amber,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${active.teamOneName} vs ${active.teamTwoName} · '
                                    '${active.battingTeamName} ${active.scoreDisplay} (${active.oversDisplay})',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.amber,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── Primary actions ───────────────────────────────
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/setup'),
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text(
                  'New Match',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _secondaryButton(
                    icon: Icons.wifi_tethering,
                    label: 'Watch Live',
                    iconColor: AppColors.green,
                    onTap: () => context.push('/watch'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _secondaryButton(
                    icon: Icons.history,
                    label: 'History',
                    iconColor: AppColors.textSecondary,
                    onTap: () => context.push('/history'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Recent match ──────────────────────────────────
            BlocBuilder<MatchHistoryBloc, MatchHistoryState>(
              builder: (context, state) {
                if (state is! MatchHistoryLoaded || state.matches.isEmpty) {
                  return _emptyHint();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent match',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    MatchCard(match: state.matches.first),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Score · Share · Celebrate',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: iconColor),
        label: Text(
          label,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _emptyHint() {
    Widget step(String n, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.greenDark,
            child: Text(
              n,
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How it works',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          step('1', 'Add both teams and players (from contacts or by name)'),
          step('2', 'Flip the coin, pick bat or bowl'),
          step('3', 'Tap one button per ball — stats are automatic'),
          step('4', 'Turn on Live Sharing so friends can watch with a code'),
        ],
      ),
    );
  }
}
