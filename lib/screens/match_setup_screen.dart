import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pitch_score/bloc/setup/match_setup_cubit.dart';
import 'package:pitch_score/bloc/setup/match_setup_state.dart';
import 'package:uuid/uuid.dart';
import '../../models/player_model.dart';
import '../../theme/app_colors.dart';

class MatchSetupScreen extends StatelessWidget {
  const MatchSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // MatchSetupCubit provided only for this screen
    return BlocProvider(
      create: (_) => MatchSetupCubit(),
      child: const _MatchSetupBody(),
    );
  }
}

class _MatchSetupBody extends StatefulWidget {
  const _MatchSetupBody();

  @override
  State<_MatchSetupBody> createState() => _MatchSetupBodyState();
}

class _MatchSetupBodyState extends State<_MatchSetupBody> {
  final _teamOneController = TextEditingController();
  final _teamTwoController = TextEditingController();
  final _playerNameController = TextEditingController();

  // Which team is being added to — 'team1' or 'team2'
  String _addingToTeam = 'team1';

  @override
  void dispose() {
    _teamOneController.dispose();
    _teamTwoController.dispose();
    _playerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Match Setup',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<MatchSetupCubit, MatchSetupState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Team Names ──────────────────────────────────
                _buildSectionTitle('Team Names'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _teamOneController,
                  hint: 'Team 1 name e.g. Chennai XI',
                  onChanged: (v) =>
                      context.read<MatchSetupCubit>().updateTeamOneName(v),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _teamTwoController,
                  hint: 'Team 2 name e.g. Mumbai Kings',
                  onChanged: (v) =>
                      context.read<MatchSetupCubit>().updateTeamTwoName(v),
                ),

                const SizedBox(height: 24),

                // ── Overs ───────────────────────────────────────
                _buildSectionTitle('Overs per innings'),
                const SizedBox(height: 8),
                _buildOversChips(context, state),

                const SizedBox(height: 24),

                // ── Max Wickets ─────────────────────────────────
                _buildSectionTitle('Max wickets'),
                const SizedBox(height: 8),
                _buildWicketsChips(context, state),

                const SizedBox(height: 24),

                // ── Add Players ─────────────────────────────────
                _buildSectionTitle('Add Players'),
                const SizedBox(height: 8),

                // Team selector for adding players
                _buildTeamSelector(context, state),
                const SizedBox(height: 8),

                // Manual player add
                _buildAddPlayerRow(context, state),
                const SizedBox(height: 12),

                // Players list
                if (state.players.isNotEmpty) ...[
                  _buildPlayersList(context, state),
                  const SizedBox(height: 12),
                ],

                // Team counts
                _buildTeamCounts(state),

                const SizedBox(height: 24),

                // ── Live Mode ───────────────────────────────────
                _buildLiveModeToggle(context, state),

                const SizedBox(height: 32),

                // ── Start Match Button ──────────────────────────
                _buildStartButton(context, state),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Section title ──────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // ── Text field ─────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
      ),
    );
  }

  // ── Overs chips ────────────────────────────────────────────────
  Widget _buildOversChips(BuildContext context, MatchSetupState state) {
    final overOptions = [4, 5, 6, 8, 10, 20];
    return Wrap(
      spacing: 8,
      children: overOptions.map((overs) {
        final isSelected = state.totalOvers == overs;
        return GestureDetector(
          onTap: () => context.read<MatchSetupCubit>().updateOvers(overs),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.greenDark : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.green : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              '$overs ov',
              style: TextStyle(
                color: isSelected ? AppColors.green : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Wickets chips ──────────────────────────────────────────────
  Widget _buildWicketsChips(BuildContext context, MatchSetupState state) {
    final wicketOptions = [3, 5, 6, 8, 10];
    return Wrap(
      spacing: 8,
      children: wicketOptions.map((w) {
        final isSelected = state.maxWickets == w;
        return GestureDetector(
          onTap: () => context.read<MatchSetupCubit>().updateMaxWickets(w),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.greenDark : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.green : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              '$w wkts',
              style: TextStyle(
                color: isSelected ? AppColors.green : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Team selector ──────────────────────────────────────────────
  Widget _buildTeamSelector(BuildContext context, MatchSetupState state) {
    return Row(
      children: [
        _teamTab(
          label: state.teamOneName.isEmpty ? 'Team 1' : state.teamOneName,
          isSelected: _addingToTeam == 'team1',
          onTap: () => setState(() => _addingToTeam = 'team1'),
        ),
        const SizedBox(width: 8),
        _teamTab(
          label: state.teamTwoName.isEmpty ? 'Team 2' : state.teamTwoName,
          isSelected: _addingToTeam == 'team2',
          onTap: () => setState(() => _addingToTeam = 'team2'),
        ),
      ],
    );
  }

  Widget _teamTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.greenDark : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.green : AppColors.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? AppColors.green : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ── Add player row ─────────────────────────────────────────────
  Widget _buildAddPlayerRow(BuildContext context, MatchSetupState state) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _playerNameController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Player name',
              hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.green),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            final name = _playerNameController.text.trim();
            if (name.isEmpty) return;

            // Create player and add to cubit
            final player = Player(
              id: const Uuid().v4(),
              name: name,
              teamId: _addingToTeam,
            );
            context.read<MatchSetupCubit>().addPlayer(player);
            _playerNameController.clear();
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add, color: Colors.black, size: 20),
          ),
        ),
      ],
    );
  }

  // ── Players list ───────────────────────────────────────────────
  Widget _buildPlayersList(BuildContext context, MatchSetupState state) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: state.players.asMap().entries.map((entry) {
          final index = entry.key;
          final player = entry.value;
          final isTeamOne = player.teamId == 'team1';
          final teamName = isTeamOne
              ? (state.teamOneName.isEmpty ? 'Team 1' : state.teamOneName)
              : (state.teamTwoName.isEmpty ? 'Team 2' : state.teamTwoName);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: index < state.players.length - 1
                  ? const Border(
                      bottom: BorderSide(color: AppColors.border))
                  : null,
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isTeamOne ? AppColors.greenDark : AppColors.blueDark,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      player.name[0].toUpperCase(),
                      style: TextStyle(
                        color: isTeamOne ? AppColors.green : AppColors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Name
                Expanded(
                  child: Text(
                    player.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),

                // Team badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        isTeamOne ? AppColors.greenDark : AppColors.blueDark,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    teamName,
                    style: TextStyle(
                      color: isTeamOne ? AppColors.green : AppColors.blue,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Delete
                GestureDetector(
                  onTap: () =>
                      context.read<MatchSetupCubit>().removePlayer(player.id),
                  child: const Icon(Icons.close,
                      color: AppColors.textSecondary, size: 16),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Team counts ────────────────────────────────────────────────
  Widget _buildTeamCounts(MatchSetupState state) {
    final team1Count =
        state.players.where((p) => p.teamId == 'team1').length;
    final team2Count =
        state.players.where((p) => p.teamId == 'team2').length;
    final team1Name =
        state.teamOneName.isEmpty ? 'Team 1' : state.teamOneName;
    final team2Name =
        state.teamTwoName.isEmpty ? 'Team 2' : state.teamTwoName;

    return Row(
      children: [
        _countChip(
          label: '$team1Name: $team1Count players',
          isEnough: team1Count >= 2,
        ),
        const SizedBox(width: 8),
        _countChip(
          label: '$team2Name: $team2Count players',
          isEnough: team2Count >= 2,
        ),
      ],
    );
  }

  Widget _countChip({required String label, required bool isEnough}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isEnough ? AppColors.greenDark : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEnough ? AppColors.green : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isEnough ? AppColors.green : AppColors.textSecondary,
          fontSize: 11,
        ),
      ),
    );
  }

  // ── Live mode toggle ───────────────────────────────────────────
  Widget _buildLiveModeToggle(BuildContext context, MatchSetupState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.wifi, color: AppColors.green, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Sharing',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Others can watch score live on their phone',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: state.isLiveMode,
                onChanged: (v) =>
                    context.read<MatchSetupCubit>().toggleLiveMode(v),
                activeColor: AppColors.green,
              ),
            ],
          ),

          // Show match code when live mode is on
          if (state.isLiveMode) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.green),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Match Code: ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    state.matchCode,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share this code on WhatsApp — anyone can watch live!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Start match button ─────────────────────────────────────────
  Widget _buildStartButton(BuildContext context, MatchSetupState state) {
    final team1Count =
        state.players.where((p) => p.teamId == 'team1').length;
    final team2Count =
        state.players.where((p) => p.teamId == 'team2').length;

    // Validation — both team names + min 2 players each
    final isValid = state.isValid && team1Count >= 2 && team2Count >= 2;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isValid
            ? () => context.push('/toss', extra: state)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          disabledBackgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          isValid ? 'Proceed to Toss 🏏' : 'Add team names + min 2 players each',
          style: TextStyle(
            color: isValid ? Colors.black : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}