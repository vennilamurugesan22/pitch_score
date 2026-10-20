// Links people share to watch a match live.
//
//   https://pitchscore-d15a6.web.app/watch/123456   ← shared (clickable in WhatsApp)
//   pitchscore://app/watch/123456                    ← fallback the web page opens
//
// Both land on the /watch/:code route.
class LiveLink {
  static const host = 'pitchscore-d15a6.web.app';

  static String forCode(String code) => 'https://$host/watch/$code';

  static String shareText({
    required String teamOne,
    required String teamTwo,
    required String code,
    String? score,
  }) {
    final scoreLine = score == null ? '' : '\n📊 $score';
    return '🏏 $teamOne vs $teamTwo is LIVE on PitchScore!$scoreLine\n'
        '👉 Watch ball by ball: ${forCode(code)}\n'
        'Or open PitchScore → Watch Live → code $code';
  }
}
