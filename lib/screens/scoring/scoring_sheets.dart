import 'package:flutter/material.dart';
import '../../bloc/scoring/scoring_state.dart';
import '../../models/player_model.dart';
import '../../theme/app_colors.dart';

// Bottom sheets used by the scoring screen.
// They only COLLECT input and return it — the ScoringBloc does the logic.

const dismissalTypes = {
  'bowled': 'Bowled',
  'caught': 'Caught',
  'lbw': 'LBW',
  'runout': 'Run out',
  'stumped': 'Stumped',
  'hitwicket': 'Hit wicket',
};

class WicketInput {
  final String dismissalType;
  final String dismissedId;
  final int runs; // runs completed before a run out
  final String? newBatsmanId;

  const WicketInput({
    required this.dismissalType,
    required this.dismissedId,
    required this.runs,
    this.newBatsmanId,
  });
}

Widget _sheetTitle(String text) => Text(
  text,
  style: const TextStyle(
    color: AppColors.textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w700,
  ),
);

Widget _label(String text) => Padding(
  padding: const EdgeInsets.only(top: 16, bottom: 8),
  child: Text(
    text,
    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
  ),
);

Widget _chip({
  required String label,
  required bool selected,
  required VoidCallback? onTap,
  Color color = AppColors.green,
  Color darkColor = AppColors.greenDark,
}) {
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? darkColor : AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? color : AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: onTap == null
              ? AppColors.textHint
              : selected
              ? color
              : AppColors.textPrimary,
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    ),
  );
}

Widget _primaryButton(String label, VoidCallback? onPressed) => SizedBox(
  width: double.infinity,
  height: 52,
  child: ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.green,
      disabledBackgroundColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: onPressed == null ? AppColors.textSecondary : Colors.black,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
    ),
  ),
);

Future<T?> _showSheet<T>(
  BuildContext context,
  Widget child, {
  bool dismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => PopScope(
      canPop: dismissible,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: child,
        ),
      ),
    ),
  );
}

// ── Wicket ───────────────────────────────────────────────────────
Future<WicketInput?> showWicketSheet(BuildContext context, ScoringState state) {
  final freeHit = state.isFreeHit;
  String type = freeHit ? 'runout' : 'bowled';
  String dismissedId = state.strikerId;
  int runs = 0;
  final available = state.availableBatsmen;
  // Last wicket of the innings → nobody needs to walk in
  final lastWicket =
      state.wickets + 1 >= state.wicketLimit || available.isEmpty;
  String? newBatsmanId = available.length == 1 ? available.first.id : null;

  return _showSheet<WicketInput>(
    context,
    StatefulBuilder(
      builder: (ctx, setSheet) {
        final ready = lastWicket || newBatsmanId != null;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.close_rounded, color: AppColors.red),
                const SizedBox(width: 6),
                _sheetTitle('Wicket! How out?'),
              ],
            ),
            if (freeHit)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Free hit — only a run out is allowed',
                  style: TextStyle(color: AppColors.amber, fontSize: 12),
                ),
              ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: dismissalTypes.entries.map((e) {
                final allowed = !freeHit || e.key == 'runout';
                return _chip(
                  label: e.value,
                  selected: type == e.key,
                  color: AppColors.red,
                  darkColor: AppColors.redDark,
                  onTap: allowed
                      ? () => setSheet(() {
                          type = e.key;
                          if (type != 'runout') {
                            dismissedId = state.strikerId;
                            runs = 0;
                          }
                        })
                      : null,
                );
              }).toList(),
            ),

            // Run out — which end, and runs completed
            if (type == 'runout') ...[
              _label('Who is out?'),
              Wrap(
                spacing: 8,
                children: [
                  for (final id in [state.strikerId, state.nonStrikerId])
                    _chip(
                      label:
                          state.playerName(id) +
                          (id == state.strikerId ? ' (striker)' : ''),
                      selected: dismissedId == id,
                      color: AppColors.red,
                      darkColor: AppColors.redDark,
                      onTap: () => setSheet(() => dismissedId = id),
                    ),
                ],
              ),
              _label('Runs completed before the run out'),
              Wrap(
                spacing: 8,
                children: [
                  for (final r in [0, 1, 2, 3])
                    _chip(
                      label: '$r',
                      selected: runs == r,
                      onTap: () => setSheet(() => runs = r),
                    ),
                ],
              ),
            ],

            // New batsman
            if (!lastWicket) ...[
              _label('Next batter'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: available
                    .map(
                      (p) => _chip(
                        label: p.name,
                        selected: newBatsmanId == p.id,
                        onTap: () => setSheet(() => newBatsmanId = p.id),
                      ),
                    )
                    .toList(),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Last wicket — this ends the innings',
                  style: TextStyle(color: AppColors.amber, fontSize: 13),
                ),
              ),
            const SizedBox(height: 20),
            _primaryButton(
              ready ? 'Confirm wicket' : 'Pick the next batter',
              ready
                  ? () => Navigator.pop(
                      ctx,
                      WicketInput(
                        dismissalType: type,
                        dismissedId: dismissedId,
                        runs: runs,
                        newBatsmanId: lastWicket ? null : newBatsmanId,
                      ),
                    )
                  : null,
            ),
          ],
        );
      },
    ),
  );
}

// ── Extras: how many runs on this wide / no ball / bye / leg bye ──
Future<int?> showExtraRunsSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required List<int> options,
  required String Function(int) labelFor,
}) {
  return _showSheet<int>(
    context,
    Builder(
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetTitle(title),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.8,
            children: options
                .map(
                  (r) => Material(
                    color: AppColors.amberDark,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(ctx, r),
                      child: Center(
                        child: Text(
                          labelFor(r),
                          style: const TextStyle(
                            color: AppColors.amber,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ),
  );
}

// ── Next bowler ──────────────────────────────────────────────────
Future<String?> showBowlerSheet(BuildContext context, ScoringState state) {
  final bowlers = state.bowlingPlayers;
  final lastBowler = state.lastOverBowlerId;
  // With only one bowler available the rule can't be applied
  final enforceRule = bowlers.length > 1;
  String? selected;

  return _showSheet<String>(
    context,
    dismissible: false,
    StatefulBuilder(
      builder: (ctx, setSheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetTitle('Over complete! Next bowler'),
          const SizedBox(height: 4),
          Text(
            '${state.scoreDisplay} after ${state.oversDisplay} overs',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          ...bowlers.map((p) {
            final isLast = p.id == lastBowler && enforceRule;
            final row = state.summary.bowlingRowFor(p.id);
            final isSelected = selected == p.id;
            return GestureDetector(
              onTap: isLast ? null : () => setSheet(() => selected = p.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.greenDark
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.green : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.name,
                        style: TextStyle(
                          color: isLast
                              ? AppColors.textHint
                              : isSelected
                              ? AppColors.green
                              : AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isLast)
                      const Text(
                        'Bowled last over',
                        style: TextStyle(color: AppColors.amber, fontSize: 11),
                      )
                    else if (row != null)
                      Text(
                        '${row.oversText}-${row.maidens}-${row.runs}-${row.wickets}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          _primaryButton(
            'Start next over',
            selected == null ? null : () => Navigator.pop(ctx, selected),
          ),
        ],
      ),
    ),
  );
}

// ── Openers — shown inline at the start of each innings ──────────
class OpenersCard extends StatefulWidget {
  final ScoringState state;
  final void Function(String striker, String nonStriker, String bowler)
  onConfirm;

  const OpenersCard({super.key, required this.state, required this.onConfirm});

  @override
  State<OpenersCard> createState() => _OpenersCardState();
}

class _OpenersCardState extends State<OpenersCard> {
  String? _striker;
  String? _nonStriker;
  String? _bowler;

  @override
  void initState() {
    super.initState();
    final bat = widget.state.battingPlayers;
    final bowl = widget.state.bowlingPlayers;
    // Sensible defaults — scorer can change them
    if (bat.length >= 2) {
      _striker = bat[0].id;
      _nonStriker = bat[1].id;
    }
    if (bowl.isNotEmpty) _bowler = bowl.first.id;
  }

  Widget _pickRow(
    String title,
    List<Player> players,
    String? value,
    ValueChanged<String> onPick, {
    String? exclude,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(title),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: players.map((p) {
            final disabled = p.id == exclude;
            return _chip(
              label: p.name,
              selected: value == p.id,
              onTap: disabled ? null : () => onPick(p.id),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final ready =
        _striker != null &&
        _nonStriker != null &&
        _bowler != null &&
        _striker != _nonStriker;

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
          _sheetTitle(s.currentInnings == 1 ? 'Openers' : 'Chase openers'),
          const SizedBox(height: 4),
          Text(
            '${s.battingTeamName} bat · ${s.bowlingTeamName} bowl',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          _pickRow(
            'Striker (faces first ball)',
            s.battingPlayers,
            _striker,
            (id) => setState(() {
              if (_nonStriker == id) _nonStriker = _striker;
              _striker = id;
            }),
          ),
          _pickRow(
            'Non-striker',
            s.battingPlayers,
            _nonStriker,
            (id) => setState(() => _nonStriker = id),
            exclude: _striker,
          ),
          _pickRow(
            'Opening bowler',
            s.bowlingPlayers,
            _bowler,
            (id) => setState(() => _bowler = id),
          ),
          const SizedBox(height: 20),
          _primaryButton(
            'Let\'s play 🏏',
            ready
                ? () => widget.onConfirm(_striker!, _nonStriker!, _bowler!)
                : null,
          ),
        ],
      ),
    );
  }
}
