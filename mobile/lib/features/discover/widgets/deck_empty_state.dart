import 'package:flutter/material.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';

/// Shown when the deck runs out.
///
/// Offers the two things that can actually produce more cards:
///  - **Refresh** — re-fetch, bringing back everyone you PASSED (never the
///    people you liked: that like is already pending, or is a match). It also
///    picks up new users and anyone who has liked you since you last loaded.
///  - **Search wider** — the radius starts at 50 km, and in a small market
///    "nobody within 50 km" is the likeliest reason the deck is empty.
class DeckEmptyState extends StatelessWidget {
  const DeckEmptyState({
    super.key,
    required this.radiusKm,
    required this.canSearchWider,
    required this.onRefresh,
    required this.onSearchWider,
  });

  final double radiusKm;
  final bool canSearchWider;
  final VoidCallback onRefresh;
  final VoidCallback onSearchWider;

  /// Mirrors the controller's radius ladder: 50 → 100 → 200 → 500 km.
  int get _nextRadiusKm => switch (radiusKm.round()) {
        50 => 100,
        100 => 200,
        _ => 500,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.explore_off_rounded, size: 64, color: AppColors.text3),
            const SizedBox(height: 16),
            Text(l10n.noMoreCards,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 8),
            Text(l10n.noMoreCardsSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.text2)),
            const SizedBox(height: 6),
            Text(l10n.searchRadiusNote(radiusKm.round()),
                style: const TextStyle(fontSize: 12, color: AppColors.text3)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l10n.refreshDeck),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            if (canSearchWider) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onSearchWider,
                  icon: const Icon(Icons.travel_explore_rounded, size: 18),
                  label: Text(l10n.searchWider(_nextRadiusKm)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.skyDeeper,
                    side: const BorderSide(color: AppColors.skyLight),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
