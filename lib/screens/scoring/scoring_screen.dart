import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../bloc/history/match_history_bloc.dart';
import '../../bloc/history/match_history_event.dart';
import '../../bloc/scoring/scoring_bloc.dart';
import '../../bloc/scoring/scoring_event.dart';
import '../../bloc/scoring/scoring_state.dart';
import '../../models/ball_model.dart';
import '../../services/firebase/firebase_match_service.dart';
import '../../services/live_link.dart';
import '../../services/local/match_storage.dart';
import '../../theme/app_colors.dart';
import '../../widgets/celebration_overlay.dart';
import '../../widgets/live_extras.dart';
import '../../widgets/live_score_panel.dart';
import 'scoring_sheets.dart';

class ScoringScreen extends StatelessWidget {
  // A brand-new match from the toss screen, or a saved one being resumed
  final ScoringState initialState;

  const ScoringScreen({super.key, required this.initialState});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScoringBloc(
        initialState,
        firebaseService: FirebaseMatchService(),
        storage: MatchStorage(),
      ),
      child: const _ScoringBody(),
    );
  }
}

class _ScoringBody extends StatefulWidget {
  const _ScoringBody();

  @override
  State<_ScoringBody> createState() => _ScoringBodyState();
}

class _ScoringBodyState extends State<_ScoringBody> {
  // Pop animation over the screen on 4 / 6 / wicket
  final _celebration = GlobalKey<CelebrationOverlayState>();

  // Previous state, captured in listenWhen so the listener can diff
  ScoringState? _prev;

  ScoringBloc get _bloc => context.read<ScoringBloc>();

  @override
  void initState() {
    super.initState();
    // Resumed a match that was waiting on a popup — reopen it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = _bloc.state;
      if (s.needsNewBowler) _pickBowler(s);
      if (s.isInningsComplete) _onInningsComplete(s);
    });
  }

  // ── Reacting to state changes (popups / navigation) ────────────
  void _listener(BuildContext context, ScoringState prev, ScoringState s) {
    final ballAdded =
        s.currentInnings == prev.currentInnings &&
        s.ballLog.length > prev.ballLog.length;
    if (ballAdded) _celebrate(s.ballLog.last);

    if (s.needsNewBowler && !prev.needsNewBowler) _pickBowler(s);

    if (s.isInningsComplete && !prev.isInningsComplete && !s.isMatchComplete) {
      // small delay so the scorer sees the last ball land
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _bloc.state.isInningsComplete) {
          _onInningsComplete(_bloc.state);
        }
      });
    }

    if (s.isMatchComplete && !prev.isMatchComplete) {
      context.read<MatchHistoryBloc>().add(SaveMatchEvent(s.toMatch()));
      context.go('/result', extra: s);
    }
  }

  void _celebrate(Ball ball) => _celebration.currentState?.playFor(ball);

  Future<void> _pickBowler(ScoringState s) async {
    final id = await showBowlerSheet(context, s);
    if (id != null && mounted) _bloc.add(NewBowlerSelectedEvent(id));
  }

  Future<void> _onInningsComplete(ScoringState s) async {
    if (s.currentInnings == 1) {
      await context.push('/innings-break', extra: _bloc);
      return;
    }
    // 2nd innings over — confirm before locking the result
    final undo = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Match over! 🏆',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          s.resultText,
          style: TextStyle(
            color: AppColors.green,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Undo last ball',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            child: Text(
              'See result',
              style: TextStyle(
                color: AppColors.onAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (!mounted || undo == null) return;
    _bloc.add(undo ? const UndoBallEvent() : const FinishMatchEvent());
  }

  // ── Building a ball from a button tap ──────────────────────────
  Ball _ball(
    ScoringState s, {
    int runs = 0,
    bool wide = false,
    bool noBall = false,
    bool bye = false,
    bool legBye = false,
    WicketInput? wicket,
  }) {
    return Ball(
      runs: wicket?.runs ?? runs,
      isWicket: wicket != null,
      isWide: wide,
      isNoBall: noBall,
      isBye: bye,
      isLegBye: legBye,
      batsmanId: s.strikerId,
      bowlerId: s.currentBowlerId,
      wicketType: wicket?.dismissalType,
      dismissedBatsmanId: wicket?.dismissedId,
      timestamp: DateTime.now(),
      strikerNameBefore: s.strikerId,
      nonStrikerNameBefore: s.nonStrikerId,
    );
  }

  void _addRuns(ScoringState s, int runs) {
    HapticFeedback.selectionClick();
    _bloc.add(AddBallEvent(_ball(s, runs: runs)));
  }

  Future<void> _addWicket(ScoringState s) async {
    final input = await showWicketSheet(context, s);
    if (input == null || !mounted) return;
    _bloc.add(
      AddBallEvent(_ball(s, wicket: input), newBatsmanId: input.newBatsmanId),
    );
  }

  Future<void> _addWide(ScoringState s) async {
    final runs = await showExtraRunsSheet(
      context,
      title: 'Wide',
      subtitle: '+1 extra. Did the batters run, or did it go for 4?',
      options: const [0, 1, 2, 3, 4],
      labelFor: (r) => r == 0 ? 'Wd' : 'Wd +$r',
    );
    if (runs == null || !mounted) return;
    _bloc.add(AddBallEvent(_ball(s, wide: true, runs: runs)));
  }

  Future<void> _addNoBall(ScoringState s) async {
    final runs = await showExtraRunsSheet(
      context,
      title: 'No ball',
      subtitle: '+1 extra and next ball is a FREE HIT. Runs off the bat?',
      options: const [0, 1, 2, 3, 4, 6],
      labelFor: (r) => r == 0 ? 'NB' : 'NB +$r',
    );
    if (runs == null || !mounted) return;
    _bloc.add(AddBallEvent(_ball(s, noBall: true, runs: runs)));
  }

  Future<void> _addByes(ScoringState s, {required bool legBye}) async {
    final runs = await showExtraRunsSheet(
      context,
      title: legBye ? 'Leg byes' : 'Byes',
      subtitle: legBye
          ? 'Runs off the pad / body — not credited to batter or bowler'
          : 'Ball missed everything — runs are extras',
      options: const [1, 2, 3, 4],
      labelFor: (r) => legBye ? '$r LB' : '$r B',
    );
    if (runs == null || !mounted) return;
    _bloc.add(AddBallEvent(_ball(s, runs: runs, bye: !legBye, legBye: legBye)));
  }

  Future<void> _undo(ScoringState s) async {
    if (s.ballLog.isEmpty) return;
    final last = s.ballLog.last;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Undo last ball?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '${last.label} — ${s.playerName(last.bowlerId)} to ${s.playerName(last.batsmanId)}',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Undo', style: TextStyle(color: AppColors.amber)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) _bloc.add(const UndoBallEvent());
  }

  // ── Share live link ────────────────────────────────────────────
  // Offline match → offer to go live first (generates a code)
  Future<void> _shareLive() async {
    var s = _bloc.state;
    if (!s.isLiveMode || s.matchCode.isEmpty) {
      final goLive = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Go live?',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Text(
            'Turn on live sharing so friends can watch this match ball by ball '
            'on their phones. Needs internet; scoring keeps working offline.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Not now',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
              child: Text(
                'Go live',
                style: TextStyle(
                  color: AppColors.onAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
      if (goLive != true || !mounted) return;
      if (!FirebaseMatchService.isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live sharing is not available on this device'),
          ),
        );
        return;
      }
      final code = await FirebaseMatchService().newMatchCode();
      if (!mounted) return;
      _bloc.add(EnableLiveSharingEvent(code));
      s = await _bloc.stream.firstWhere((x) => x.isLiveMode);
      if (!mounted) return;
    }
    await _showShareSheet(s);
  }

  Future<void> _showShareSheet(ScoringState s) {
    final link = LiveLink.forCode(s.matchCode);
    final text = LiveLink.shareText(
      teamOne: s.teamOneName,
      teamTwo: s.teamTwoName,
      code: s.matchCode,
      score: '${s.battingTeamName} ${s.scoreDisplay} (${s.oversDisplay} ov)',
    );
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LiveBadge(),
            const SizedBox(height: 14),
            Text(
              'Share the live score',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Anyone with the link or code can watch ball by ball',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Text(
              s.matchCode,
              style: TextStyle(
                color: AppColors.green,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(
              link,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.blue, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await Clipboard.setData(ClipboardData(text: link));
                        if (ctx.mounted) Navigator.pop(ctx);
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Link copied')),
                        );
                      },
                      icon: Icon(Icons.copy, color: AppColors.textPrimary),
                      label: Text(
                        'Copy link',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        SharePlus.instance.share(ShareParams(text: text));
                      },
                      icon: Icon(Icons.share, color: AppColors.onAccent),
                      label: Text(
                        'Share link',
                        style: TextStyle(
                          color: AppColors.onAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Menu actions ───────────────────────────────────────────────
  Future<void> _confirmEndInnings() async {
    final ok = await _confirm(
      'End innings now?',
      'Use this if the innings is cut short (rain, time, declared).',
      'End innings',
    );
    if (ok && mounted) _bloc.add(const EndInningsEvent());
  }

  Future<void> _leave() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Leave match?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'The match is saved on this phone — you can resume it from Home.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'abandon'),
            child: Text(
              'Abandon match',
              style: TextStyle(color: AppColors.red),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'leave'),
            child: Text(
              'Save & leave',
              style: TextStyle(color: AppColors.green),
            ),
          ),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'abandon') {
      final sure = await _confirm(
        'Abandon match?',
        'This match will be deleted and cannot be recovered.',
        'Abandon',
      );
      if (!sure) return;
      await MatchStorage().clearActiveMatch();
    }
    if (mounted) context.go('/');
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: TextStyle(color: AppColors.textPrimary)),
        content: Text(body, style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action, style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScoringBloc, ScoringState>(
      listenWhen: (prev, curr) {
        _prev = prev;
        return true;
      },
      listener: (context, s) => _listener(context, _prev ?? s, s),
      builder: (context, s) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _leave();
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: CelebrationOverlay(
              key: _celebration,
              child: SafeArea(
                child: Column(
                  children: [
                    _TopBar(
                      state: s,
                      onClose: _leave,
                      onEndInnings: _confirmEndInnings,
                      onScorecard: () => context.push('/scorecard', extra: s),
                      onShare: _shareLive,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: s.needsOpeners
                            ? OpenersCard(
                                key: ValueKey('openers-${s.currentInnings}'),
                                state: s,
                                onConfirm: (st, ns, bw) => _bloc.add(
                                  SetOpenersEvent(
                                    strikerId: st,
                                    nonStrikerId: ns,
                                    bowlerId: bw,
                                  ),
                                ),
                              )
                            : LiveScorePanel(
                                state: s,
                                onSwapStrike: () =>
                                    _bloc.add(const SwapStrikeEvent()),
                              ),
                      ),
                    ),
                    if (!s.needsOpeners) _bottomArea(s),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Bottom of screen: scoring pad, or the pending action
  Widget _bottomArea(ScoringState s) {
    if (s.isInningsComplete) {
      return _PendingBar(
        text: s.currentInnings == 1 ? 'Innings complete' : s.resultText,
        button: s.currentInnings == 1 ? 'Innings break' : 'Finish match',
        onPressed: () => _onInningsComplete(s),
        onUndo: () => _undo(s),
      );
    }
    if (s.needsNewBowler) {
      return _PendingBar(
        text: 'Over complete',
        button: 'Pick next bowler',
        onPressed: () => _pickBowler(s),
        onUndo: () => _undo(s),
      );
    }
    return _ScoringPad(
      onRuns: (r) => _addRuns(s, r),
      onWicket: () => _addWicket(s),
      onWide: () => _addWide(s),
      onNoBall: () => _addNoBall(s),
      onBye: () => _addByes(s, legBye: false),
      onLegBye: () => _addByes(s, legBye: true),
      onUndo: s.ballLog.isEmpty ? null : () => _undo(s),
    );
  }
}

// ── Top bar ──────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final ScoringState state;
  final VoidCallback onClose;
  final VoidCallback onEndInnings;
  final VoidCallback onScorecard;
  final VoidCallback onShare;

  const _TopBar({
    required this.state,
    required this.onClose,
    required this.onEndInnings,
    required this.onScorecard,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close, color: AppColors.textSecondary),
          ),
          Expanded(
            child: Text(
              '${state.teamOneName} vs ${state.teamTwoName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          if (state.isLiveMode && state.matchCode.isNotEmpty)
            GestureDetector(
              onTap: onShare,
              child: LiveBadge(code: state.matchCode),
            ),
          IconButton(
            key: const ValueKey('share-live'),
            onPressed: onShare,
            tooltip: 'Share live score',
            icon: Icon(Icons.share, color: AppColors.green),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
            color: AppColors.surface,
            onSelected: (v) {
              if (v == 'share') onShare();
              if (v == 'scorecard') onScorecard();
              if (v == 'end') onEndInnings();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'share',
                child: Text(
                  'Share live link',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
              PopupMenuItem(
                value: 'scorecard',
                child: Text(
                  'Full scorecard',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
              if (state.canScore && state.ballLog.isNotEmpty)
                PopupMenuItem(
                  value: 'end',
                  child: Text(
                    'End innings',
                    style: TextStyle(color: AppColors.red),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Pending action bar (pick bowler / go to innings break) ───────
class _PendingBar extends StatelessWidget {
  final String text;
  final String button;
  final VoidCallback onPressed;
  final VoidCallback onUndo;

  const _PendingBar({
    required this.text,
    required this.button,
    required this.onPressed,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: onUndo,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '↩ Undo',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        button,
                        style: TextStyle(
                          color: AppColors.onAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scoring buttons ──────────────────────────────────────────────
// Row 1: • 1 2 3
// Row 2: 4 6 W Wd
// Row 3: NB B LB Undo
class _ScoringPad extends StatelessWidget {
  final ValueChanged<int> onRuns;
  final VoidCallback onWicket;
  final VoidCallback onWide;
  final VoidCallback onNoBall;
  final VoidCallback onBye;
  final VoidCallback onLegBye;
  final VoidCallback? onUndo;

  const _ScoringPad({
    required this.onRuns,
    required this.onWicket,
    required this.onWide,
    required this.onNoBall,
    required this.onBye,
    required this.onLegBye,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 10, 9, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _btn('•', () => onRuns(0), sub: 'dot'),
                _btn('1', () => onRuns(1)),
                _btn('2', () => onRuns(2)),
                _btn('3', () => onRuns(3)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _btn(
                  '4',
                  () => onRuns(4),
                  bg: AppColors.greenDark,
                  fg: AppColors.green,
                  bold: true,
                ),
                _btn(
                  '6',
                  () => onRuns(6),
                  bg: AppColors.blueDark,
                  fg: AppColors.blue,
                  bold: true,
                ),
                _btn(
                  'W',
                  onWicket,
                  bg: AppColors.redDark,
                  fg: AppColors.red,
                  bold: true,
                ),
                _btn(
                  'Wd',
                  onWide,
                  bg: AppColors.amberDark,
                  fg: AppColors.amber,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _btn(
                  'NB',
                  onNoBall,
                  bg: AppColors.amberDark,
                  fg: AppColors.amber,
                ),
                _btn('B', onBye, fg: AppColors.textSecondary, sub: 'bye'),
                _btn(
                  'LB',
                  onLegBye,
                  fg: AppColors.textSecondary,
                  sub: 'leg bye',
                ),
                _btn('↩', onUndo, fg: AppColors.textSecondary, sub: 'undo'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(
    String label,
    VoidCallback? onTap, {
    Color? bg,
    Color? fg,
    bool bold = false,
    String? sub,
  }) {
    bg ??= AppColors.background;
    fg ??= AppColors.textPrimary;
    final enabled = onTap != null;
    return Expanded(
      child: Padding(
        key: ValueKey('pad-$label'),
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: bg == AppColors.background
                      ? AppColors.border
                      : fg.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: enabled ? fg : AppColors.textHint,
                      fontSize: bold ? 22 : 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (sub != null)
                    Text(
                      sub,
                      style: TextStyle(
                        color: enabled
                            ? AppColors.textSecondary
                            : AppColors.textHint,
                        fontSize: 9,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
