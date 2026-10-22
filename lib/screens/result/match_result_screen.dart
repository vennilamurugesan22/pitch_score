import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../bloc/scoring/scoring_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/scorecard_view.dart';

// Final result. The match is already saved to history by the scoring
// screen, so nothing is lost if the scorer just closes the app here.
class MatchResultScreen extends StatefulWidget {
  final ScoringState state;
  const MatchResultScreen({super.key, required this.state});

  @override
  State<MatchResultScreen> createState() => _MatchResultScreenState();
}

class _MatchResultScreenState extends State<MatchResultScreen> {
  final _screenshot = ScreenshotController();
  bool _sharing = false;

  ScoringState get s => widget.state;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      // Render the whole scorecard (not just what's on screen) to a PNG
      final bytes = await _screenshot.captureFromLongWidget(
        InheritedTheme.captureAll(
          context,
          Material(color: AppColors.background, child: _shareCard()),
        ),
        context: context,
        pixelRatio: 2,
        delay: const Duration(milliseconds: 100),
        constraints: const BoxConstraints(maxWidth: 420),
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/pitchscore_${s.matchId}.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text:
              '🏏 ${s.teamOneName} vs ${s.teamTwoName} — ${s.resultText}\nScored with PitchScore',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share scorecard: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  // What goes into the shared image
  Widget _shareCard() {
    final second = s.secondInningsSummary;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _banner(animated: false),
          const SizedBox(height: 16),
          InningsScorecard(
            teamName: s.teamName(s.battingFirstId),
            summary: s.firstInningsSummary,
            showOvers: false,
          ),
          if (second != null) ...[
            const SizedBox(height: 20),
            InningsScorecard(
              teamName: s.teamName(s.bowlingFirstId),
              summary: second,
              showOvers: false,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'PitchScore · Score · Share · Celebrate',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _banner({bool animated = true}) {
    final potm = s.playerOfTheMatch;
    final banner = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.greenDark, AppColors.blueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green),
      ),
      child: Column(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 6),
          Text(
            s.resultText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${s.teamName(s.battingFirstId)} ${s.firstInningsSummary.scoreText} (${s.firstInningsSummary.oversText})'
            '  ·  '
            '${s.teamName(s.bowlingFirstId)} ${s.secondInningsSummary?.scoreText ?? '-'} (${s.secondInningsSummary?.oversText ?? '-'})',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          if (potm != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.amberDark,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.amber),
              ),
              child: Text(
                '⭐ Player of the match: ${potm.name}',
                style: TextStyle(
                  color: AppColors.amber,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
    if (!animated) return banner;
    return banner
        .animate()
        .scale(
          begin: const Offset(0.85, 0.85),
          duration: 500.ms,
          curve: Curves.easeOutBack,
        )
        .then()
        .shimmer(
          duration: 1200.ms,
          color: AppColors.green.withValues(alpha: 0.4),
        );
  }

  @override
  Widget build(BuildContext context) {
    final second = s.secondInningsSummary;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Match Result'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Home',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _banner(),
                  const SizedBox(height: 20),
                  InningsScorecard(
                    teamName: s.teamName(s.battingFirstId),
                    summary: s.firstInningsSummary,
                  ),
                  if (second != null) ...[
                    const SizedBox(height: 24),
                    InningsScorecard(
                      teamName: s.teamName(s.bowlingFirstId),
                      summary: second,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _sharing ? null : _share,
                        icon: _sharing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.share, color: AppColors.green),
                        label: Text(
                          'Share',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.green),
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
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => context.go('/'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: AppColors.onAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                '✓ Saved to match history',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
