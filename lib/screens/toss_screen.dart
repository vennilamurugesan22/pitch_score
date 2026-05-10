import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pitch_score/bloc/setup/match_setup_state.dart';
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
  bool _isFlipping = false;       // coin currently spinning
  bool _tossComplete = false;     // toss done, show result
  String _tossResult = '';        // 'Heads' or 'Tails'
  String _tossWinner = '';        // which team won
  String _tossChoice = '';        // 'bat' or 'bowl'
  String _callingTeam = 'team1';  // which team is calling

  @override
  void initState() {
    super.initState();

    // Setup animation — 1.5 seconds, ease out (slows at end like real coin)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 6 * pi, // 3 full rotations
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut, // starts fast, slows down at end
    ));

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

  // Called when user taps the coin
  void _flipCoin() {
    if (_isFlipping || _tossComplete) return;

    setState(() => _isFlipping = true);
    _controller.forward(from: 0); // start animation from beginning
  }

  // Called when animation ends — randomly pick heads or tails
  void _determineResult() {
    final random = Random();
    final isHeads = random.nextBool();

    // Determine winner based on what calling team picked
    // For simplicity — team1 always calls Heads
    // You can make this selectable later
    final callingTeamWon = isHeads; // team1 called heads

    final teamOneName = widget.matchSetup.teamOneName;
    final teamTwoName = widget.matchSetup.teamTwoName;

    setState(() {
      _isFlipping = false;
      _tossComplete = true;
      _tossResult = isHeads ? 'HEADS' : 'TAILS';
      _tossWinner = callingTeamWon ? teamOneName : teamTwoName;
    });
  }

  // Navigate to scoring screen with all match data
  void _confirmAndStart() {
    if (_tossChoice.isEmpty) return;

    // Determine batting team based on toss winner's choice
    final tossWinnerIsTeamOne =
        _tossWinner == widget.matchSetup.teamOneName;

    final battingFirst = _tossChoice == 'bat'
        ? (tossWinnerIsTeamOne ? 'team1' : 'team2')
        : (tossWinnerIsTeamOne ? 'team2' : 'team1');

    context.pushReplacement('/scoring', extra: {
      'matchSetup': widget.matchSetup,
      'tossWinner': _tossWinner,
      'tossChoice': _tossChoice,
      'battingFirst': battingFirst,
    });
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
        child: Padding(
          padding: const EdgeInsets.all(24),
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

                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001) // perspective
                        ..rotateY(rotation),    // spin on Y axis
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: showHeads
                                ? [const Color(0xFFFFD700), const Color(0xFFFFA000)]
                                : [const Color(0xFF9E9E9E), const Color(0xFF616161)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (showHeads
                                      ? const Color(0xFFFFD700)
                                      : const Color(0xFF9E9E9E))
                                  .withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            showHeads ? 'H' : 'T',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
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
                        '$_tossWinner wins the toss!',
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
                  '$_tossWinner chooses to...',
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
    );
  }

  // ── Calling team button ────────────────────────────────────────
  Widget _callingTeamButton({
    required String label,
    required String teamId,
  }) {
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
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ── Bat / Bowl choice button ───────────────────────────────────
  Widget _choiceButton({
    required String label,
    required String choice,
  }) {
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
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.normal,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}