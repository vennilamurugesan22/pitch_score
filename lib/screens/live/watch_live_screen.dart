import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../bloc/scoring/scoring_state.dart';
import '../../services/firebase/firebase_match_service.dart';
import '../../services/live_link.dart';
import '../../theme/app_colors.dart';
import '../../widgets/celebration_overlay.dart';
import '../../widgets/live_extras.dart';
import '../../widgets/live_score_panel.dart';

// Spectator view — enter a 6-digit code, watch the score update ball by
// ball. Same widgets as the scoring screen, but no buttons.
class WatchLiveScreen extends StatefulWidget {
  final String? initialCode;
  const WatchLiveScreen({super.key, this.initialCode});

  @override
  State<WatchLiveScreen> createState() => _WatchLiveScreenState();
}

class _WatchLiveScreenState extends State<WatchLiveScreen> {
  final _service = FirebaseMatchService();
  final _codeController = TextEditingController();
  final _viewerId = const Uuid().v4();

  String? _code; // code currently being watched
  // Created once per join — not in build(), or every rebuild resubscribes
  StreamSubscription<ScoringState?>? _matchSub;
  Stream<int>? _viewerStream;
  ScoringState? _live; // latest snapshot from Firebase
  bool _waiting = true;
  bool _streamError = false;
  final _celebration = GlobalKey<CelebrationOverlayState>();
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null && widget.initialCode!.length == 6) {
      _codeController.text = widget.initialCode!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _join());
    }
  }

  @override
  void dispose() {
    _leaveMatch();
    _codeController.dispose();
    super.dispose();
  }

  void _leaveMatch() {
    _matchSub?.cancel();
    _matchSub = null;
    final code = _code;
    if (code != null) _service.decrementViewers(code, _viewerId);
  }

  // New snapshot from the scorer — pop an animation for 4 / 6 / wicket
  void _onSnapshot(ScoringState? next) {
    final prev = _live;
    final newBall =
        prev != null &&
        next != null &&
        next.currentInnings == prev.currentInnings &&
        next.ballLog.length > prev.ballLog.length;
    setState(() {
      _live = next;
      _waiting = false;
      _streamError = false;
    });
    if (newBall) _celebration.currentState?.playFor(next.ballLog.last);
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Match code is 6 digits');
      return;
    }
    if (!FirebaseMatchService.isAvailable) {
      setState(() => _error = 'Live scores are not available on this device');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _checking = true;
      _error = null;
    });
    final exists = await _service.matchExists(code);
    if (!mounted) return;
    if (!exists) {
      setState(() {
        _checking = false;
        _error = 'No match found for $code. Check the code and your internet.';
      });
      return;
    }
    _leaveMatch();
    await _service.incrementViewers(code, _viewerId);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _code = code;
      _live = null;
      _waiting = true;
      _matchSub = _service
          .watchMatch(code)
          .listen(
            _onSnapshot,
            onError: (_) => setState(() => _streamError = true),
          );
      _viewerStream = _service.watchViewers(code);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _code == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          // Back from a match → back to code entry
          _leaveMatch();
          setState(() => _code = null);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: _code == null
              ? const Text('Watch Live')
              : Row(
                  children: [
                    const LiveBadge(),
                    const SizedBox(width: 10),
                    Text(_code!, style: const TextStyle(letterSpacing: 2)),
                  ],
                ),
          actions: [
            if (_code != null && _live != null)
              IconButton(
                tooltip: 'Share',
                icon: Icon(Icons.share, color: AppColors.green),
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text: LiveLink.shareText(
                      teamOne: _live!.teamOneName,
                      teamTwo: _live!.teamTwoName,
                      code: _code!,
                      score:
                          '${_live!.battingTeamName} ${_live!.scoreDisplay} (${_live!.oversDisplay} ov)',
                    ),
                  ),
                ),
              ),
            if (_viewerStream != null && _code != null)
              _ViewersChip(stream: _viewerStream!),
          ],
        ),
        body: SafeArea(
          child: _code == null
              ? _codeEntry()
              : CelebrationOverlay(key: _celebration, child: _liveView()),
        ),
      ),
    );
  }

  // ── Code entry ─────────────────────────────────────────────────
  Widget _codeEntry() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Icon(Icons.wifi_tethering, color: AppColors.green, size: 56),
        const SizedBox(height: 16),
        Text(
          'Enter the match code',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ask the scorer for the 6-digit code shown on their screen',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          textAlign: TextAlign.center,
          autofocus: widget.initialCode == null,
          onSubmitted: (_) => _join(),
          style: TextStyle(
            color: AppColors.green,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: 10,
          ),
          decoration: InputDecoration(
            hintText: '000000',
            hintStyle: TextStyle(color: AppColors.textHint, letterSpacing: 10),
            filled: true,
            fillColor: AppColors.surface,
            errorText: _error,
            errorMaxLines: 2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.green, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _checking ? null : _join,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _checking
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.onAccent,
                    ),
                  )
                : Text(
                    'Watch',
                    style: TextStyle(
                      color: AppColors.onAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ── Live score ─────────────────────────────────────────────────
  Widget _liveView() {
    if (_streamError) {
      return _message(
        Icons.cloud_off,
        'Connection problem',
        'Check your internet — the score will update when you\'re back online.',
      );
    }
    final s = _live;
    if (s == null) {
      return _waiting
          ? Center(child: CircularProgressIndicator(color: AppColors.green))
          : _message(
              Icons.hourglass_empty,
              'Waiting for the first ball',
              'The scorer hasn\'t started yet.',
            );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${s.teamOneName} vs ${s.teamTwoName}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _statusLine(s),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: s.isMatchComplete
                ? AppColors.amber
                : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: s.isMatchComplete ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 12),
        if (s.currentInnings == 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${s.teamName(s.battingFirstId)}: ${s.firstInningsSummary.scoreText} (${s.firstInningsSummary.oversText})',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        LiveScorePanel(state: s),
        const SizedBox(height: 10),
        MatchInsights(state: s),
        const SizedBox(height: 10),
        BallByBallFeed(state: s),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/scorecard', extra: s),
            icon: Icon(Icons.table_chart_outlined, color: AppColors.green),
            label: Text(
              'Full scorecard',
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
      ],
    );
  }

  String _statusLine(ScoringState s) {
    if (s.isMatchComplete) return s.resultText;
    if (s.isInningsComplete && s.currentInnings == 1) return 'Innings break';
    if (s.needsOpeners) return 'Waiting for openers...';
    if (s.needsNewBowler) return 'End of over';
    return 'Ball by ball, as it happens';
  }

  Widget _message(IconData icon, String title, String body) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 48),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}

class _ViewersChip extends StatelessWidget {
  final Stream<int> stream;
  const _ViewersChip({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snap) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Row(
          children: [
            Icon(Icons.visibility, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              '${snap.data ?? 1} watching',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
