import 'package:flutter/material.dart';
import '../models/ball_model.dart';
import '../theme/app_colors.dart';

// One delivery in the "this over" row
// dot=grey, 1/2/3=green, 4=bright green+border, 6=blue+border,
// W=red, Wd/NB=amber
class BallCircle extends StatelessWidget {
  final Ball? ball; // null = ball not bowled yet
  final double size;

  const BallCircle({super.key, this.ball, this.size = 34});

  @override
  Widget build(BuildContext context) {
    final b = ball;
    if (b == null) {
      return Container(
        width: size,
        height: size,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
      );
    }

    final (bg, fg, borderWidth) = colorsFor(b);

    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderWidth > 1 ? fg : fg.withValues(alpha: 0.4),
          width: borderWidth,
        ),
      ),
      child: Center(
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Text(
              b.label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static (Color bg, Color fg, double borderWidth) colorsFor(Ball b) {
    if (b.isWicket) return (AppColors.redDark, AppColors.red, 1);
    if (b.isWide || b.isNoBall)
      return (AppColors.amberDark, AppColors.amber, 1);
    if (b.isSix) return (AppColors.blueDark, AppColors.blue, 2);
    if (b.isFour) return (AppColors.greenDark, AppColors.green, 2);
    if (b.totalRuns == 0)
      return (AppColors.surface, AppColors.textSecondary, 1);
    return (AppColors.surface, AppColors.green, 1);
  }
}
