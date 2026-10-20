import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pitch_score/bloc/scoring/scoring_state.dart';
import 'package:pitch_score/bloc/setup/match_setup_state.dart';
import 'package:uuid/uuid.dart';
import '../../services/firebase/firebase_match_service.dart';
import '../../theme/app_colors.dart';

class TossScreen extends StatefulWidget {
  final MatchSetupState matchSetup;

  const TossScreen({super.key, required this.matchSetup});

  @override
  State<TossScreen> createState() => _TossScreenState();
}

class _TossScreenState extends State<TossScreen>
    with SingleTickerProviderStateMixin {
  // Animation controller — controls the coin flip speed and duration
  late AnimationController _controller;

  // Rotation animation — coin spins 3 full rounds (6π radians)
  late Animation<double> _rotationAnimation;

  // Track toss state
  bool _isFlipping = false; // coin currently spinning
  bool _tossComplete = false; // toss done, show result
  String _tossResult = ''; // 'Heads' or 'Tails'
  String _tossWinner = ''; // which team won — 'team1' / 'team2'
  String _tossChoice = ''; // 'bat' or 'bowl'
  String _callingTeam = 'team1'; // which team is calling
  String _call = 'heads'; // what the calling team called
  bool _willBeHeads = true; // decided before the flip so the coin lands on it

  @override
  void initState() {
    super.initState();

    // Setup animation — 1.5 seconds, ease out (slows at end like real coin)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _buildAnimation();

    // When animation completes — determine result
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _determineResult();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Coin spins 3 full rounds and lands on the decided face
  // (an extra half turn = π shows the back = tails)
  void _buildAnimation() {
    _rotationAnimation =
        Tween<double>(begin: 0, end: 6 * pi + (_willBeHeads ? 0 : pi)).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOut, // starts fast, slows down at end
          ),
        );
  }

  String _teamName(String id) => id == 'team1'
      ? widget.matchSetup.teamOneName
      : widget.matchSetup.teamTwoName;

  // Called when user taps the coin
  void _flipCoin() {
    if (_isFlipping || _tossComplete) return;
    _willBeHeads = Random.secure().nextBool();
    setState(() {
      _isFlipping = true;
      _buildAnimation();
    });
    _controller.forward(from: 0); // start animation from beginning
  }

  // Called when animation ends
  void _determineResult() {
    final result = _willBeHeads ? 'heads' : 'tails';
    final callingTeamWon = result == _call;
    final other = _callingTeam == 'team1' ? 'team2' : 'team1';

    setState(() {
      _isFlipping = false;
      _tossComplete = true;
      _tossResult = result.toUpperCase();
      _tossWinner = callingTeamWon ? _callingTeam : other;
    });
  }

  void _reflip() {
    _controller.reset();
    setState(() {
      _tossComplete = false;
      _tossChoice = '';
    });
  }

  // Build the match and go to the scoring screen
  void _confirmAndStart() {
    if (_tossChoice.isEmpty) return;
    final setup = widget.matchSetup;

    final match = ScoringState.newMatch(
      matchId: const Uuid().v4(),
      setup: setup,
      tossWinnerId: _tossWinner,
      tossChoice: _tossChoice,
    );

    // Live mode — create the match on Firebase (fire and forget)
    if (setup.isLiveMode && setup.matchCode.isNotEmpty) {
      FirebaseMatchService().createMatch(setup.matchCode, setup);
    }

    context.pushReplacement('/scoring', extra: match);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Toss',
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 48,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const Spacer(),

                    // ── Who is calling ──────────────────────────────
                    if (!_tossComplete) ...[
                      const Text(
                        'Who is calling?',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _callingTeamButton(
                            label: widget.matchSetup.teamOneName,
                            teamId: 'team1',
                          ),
                          const SizedBox(width: 10),
                          _callingTeamButton(
                            label: widget.matchSetup.teamTwoName,
                            teamId: 'team2',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_teamName(_callingTeam)} calls...',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _callButton('Heads', 'heads'),
                          const SizedBox(width: 10),
                          _callButton('Tails', 'tails'),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],

                    // ── Coin ────────────────────────────────────────
                    GestureDetector(
                      onTap: _flipCoin,
                      child: AnimatedBuilder(
                        animation: _rotationAnimation,
                        builder: (context, child) {
                          // Transform.rotate spins the coin on Y axis
                          // We use cos to determine if showing heads or tails
                          final rotation = _rotationAnimation.value;
                          final showHeads = cos(rotation) >= 0;
                          // Back face is seen through a half turn — flip the
                          // letter back so "T" isn't mirrored
                          final letter = Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(showHeads ? 0 : pi),
                            child: Text(
                              // Neutral face until flipped, so it doesn't look pre-decided
                              !_isFlipping && !_tossComplete
                                  ? '?'
                                  : showHeads
                                  ? 'H'
                                  : 'T',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          );

                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001) // perspective
                              ..rotateY(rotation), // spin on Y axis
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: showHeads
                                      ? [
                                          const Color(0xFFFFD700),
                                          const Color(0xFFFFA000),
                                        ]
                                      : [
                                          const Color(0xFF9E9E9E),
                                          const Color(0xFF616161),
                                        ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (showHeads
                                                ? const Color(0xFFFFD700)
                                                : const Color(0xFF9E9E9E))
                                            .withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(child: letter),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Tap to flip hint ────────────────────────────
                    if (!_isFlipping && !_tossComplete)
                      const Text(
                        'Tap coin to flip!',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),

                    // ── Toss result ─────────────────────────────────
                    if (_tossComplete) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.greenDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.green),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _tossResult,
                              style: const TextStyle(
                                color: AppColors.green,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_teamName(_tossWinner)} wins the toss!',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Bat or Bowl choice ──────────────────────
                      Text(
                        '${_teamName(_tossWinner)} chooses to...',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _choiceButton(label: '🏏  BAT', choice: 'bat'),
                          const SizedBox(width: 10),
                          _choiceButton(label: '🎳  BOWL', choice: 'bowl'),
                        ],
                      ),
                      TextButton(
                        onPressed: _reflip,
                        child: const Text(
                          'Flip again',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],

                    const Spacer(),

                    // ── Confirm button ──────────────────────────────
                    if (_tossComplete)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _tossChoice.isNotEmpty
                              ? _confirmAndStart
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            disabledBackgroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _tossChoice.isNotEmpty
                                ? 'Start Match! 🏏'
                                : 'Choose bat or bowl first',
                            style: TextStyle(
                              color: _tossChoice.isNotEmpty
                                  ? Colors.black
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Calling team button ────────────────────────────────────────
  Widget _callingTeamButton({required String label, required String teamId}) {
    final isSelected = _callingTeam == teamId;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _callingTeam = teamId),
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
            style: TextStyle(
              color: isSelected ? AppColors.green : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ── Heads / Tails call button ──────────────────────────────────
  Widget _callButton(String label, String call) {
    final isSelected = _call == call;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _call = call),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.amberDark : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.amber : AppColors.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.amber : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ── Bat / Bowl choice button ───────────────────────────────────
  Widget _choiceButton({required String label, required String choice}) {
    final isSelected = _tossChoice == choice;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tossChoice = choice),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.greenDark : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.green : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.green : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
