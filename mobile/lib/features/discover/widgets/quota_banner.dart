import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/l10n_extension.dart';

class QuotaBanner extends StatelessWidget {
  const QuotaBanner({super.key, required this.remaining, required this.total, this.isPremium = false});

  final int remaining;
  final int total;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fraction = total > 0 ? remaining / total : 1.0;
    final color = fraction > 0.4 ? AppColors.skyDark : fraction > 0.2 ? const Color(0xFFF59E0B) : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              value: isPremium ? 1.0 : fraction,
              strokeWidth: 3,
              backgroundColor: AppColors.skyLight,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isPremium ? l10n.swipesUnlimited : l10n.swipesLeft(remaining),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
