import 'package:flutter/material.dart';
import '../bloc/scoring/innings_summary.dart';
import '../theme/app_colors.dart';
import 'ball_circle.dart';

// Full scorecard for ONE innings — batting, extras, bowling,
// fall of wickets, over-by-over. Not scrollable itself; put it in a list.
class InningsScorecard extends StatelessWidget {
  final String teamName;
  final InningsSummary summary;
  final bool showOvers;

  const InningsScorecard({
    super.key,
    required this.teamName,
    required this.summary,
    this.showOvers = true,
  });

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.greenDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.green.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  teamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                s.scoreText,
                style: const TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${s.oversText} ov)',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── Batting ───────────────────────────────────────────
        _Table(
          header: const ['Batter', 'R', 'B', '4s', '6s', 'SR'],
          rows: [
            for (final r in s.battingRows)
              _TableRow(
                name: r.player.name,
                subtitle: r.howOut,
                highlight: !r.isOut,
                cells: [
                  '${r.runs}',
                  '${r.balls}',
                  '${r.fours}',
                  '${r.sixes}',
                  r.strikeRate.toStringAsFixed(1),
                ],
              ),
          ],
        ),
        _infoLine(
          'Extras',
          '${s.extras}',
          detail: 'wd ${s.wides}, nb ${s.noBalls}, b ${s.byes}, lb ${s.legByes}',
        ),
        _infoLine(
          'Total',
          s.scoreText,
          detail: '${s.oversText} ov · RR ${s.runRate.toStringAsFixed(2)}',
          bold: true,
        ),
        if (s.didNotBat.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Text(
              'Did not bat: ${s.didNotBat.map((p) => p.name).join(', ')}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        const SizedBox(height: 14),

        // ── Bowling ───────────────────────────────────────────
        if (s.bowlingRows.isNotEmpty)
          _Table(
            header: const ['Bowler', 'O', 'M', 'R', 'W', 'Econ'],
            rows: [
              for (final r in s.bowlingRows)
                _TableRow(
                  name: r.player.name,
                  subtitle: (r.wides + r.noBalls) > 0
                      ? '${r.wides} wd, ${r.noBalls} nb'
                      : null,
                  cells: [
                    r.oversText,
                    '${r.maidens}',
                    '${r.runs}',
                    '${r.wickets}',
                    r.economy.toStringAsFixed(2),
                  ],
                ),
            ],
          ),

        // ── Fall of wickets ───────────────────────────────────
        if (s.fallOfWickets.isNotEmpty) ...[
          const SizedBox(height: 14),
          const _SectionTitle('Fall of wickets'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in s.fallOfWickets)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${f.score}-${f.wicketNumber} (${f.batsmanName}, ${f.overText})',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                  ),
                ),
            ],
          ),
        ],

        // ── Over by over ──────────────────────────────────────
        if (showOvers && s.overs.isNotEmpty) ...[
          const SizedBox(height: 14),
          const _SectionTitle('Over by over'),
          const SizedBox(height: 6),
          for (final o in s.overs)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ov ${o.overNumber}',
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                        Text(o.bowlerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 10)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      runSpacing: 4,
                      children: [for (final b in o.balls) BallCircle(ball: b, size: 26)],
                    ),
                  ),
                  Text(
                    '${o.runs}\n${o.scoreAtEnd}/${o.wicketsAtEnd}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _infoLine(String label, String value, {String? detail, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                color: bold ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              )),
          const SizedBox(width: 8),
          if (detail != null)
            Expanded(
              child: Text(detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            )
          else
            const Spacer(),
          Text(value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _TableRow {
  final String name;
  final String? subtitle;
  final bool highlight;
  final List<String> cells;
  const _TableRow({
    required this.name,
    this.subtitle,
    this.highlight = false,
    required this.cells,
  });
}

class _Table extends StatelessWidget {
  final List<String> header;
  final List<_TableRow> rows;
  const _Table({required this.header, required this.rows});

  static const _widths = [34.0, 30.0, 28.0, 28.0, 46.0];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Expanded(child: _text(header.first, AppColors.textSecondary, 11)),
                for (var i = 1; i < header.length; i++)
                  SizedBox(
                    width: _widths[i - 1],
                    child: _text(header[i], AppColors.textSecondary, 11, right: true),
                  ),
              ],
            ),
          ),
          for (final r in rows)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name + (r.highlight ? ' *' : ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: r.highlight ? AppColors.green : AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (r.subtitle != null)
                          Text(r.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  for (var i = 0; i < r.cells.length; i++)
                    SizedBox(
                      width: _widths[i],
                      child: _text(
                        r.cells[i],
                        i == 0 ? AppColors.textPrimary : AppColors.textSecondary,
                        13,
                        right: true,
                        bold: i == 0,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _text(String t, Color c, double size, {bool right = false, bool bold = false}) =>
      Text(
        t,
        textAlign: right ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          color: c,
          fontSize: size,
          fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
        ),
      );
}
