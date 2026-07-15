import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/data/profile_repository.dart';

/// Whether the signed-in user is premium.
///
/// Read from `sub_status` on the **user doc**, which only the RevenueCat webhook
/// writes (the rules forbid the client from touching it). Deliberately not read
/// from the RevenueCat SDK's local cache: the server is what enforces the quota,
/// so the server is what the UI should agree with — otherwise the app can promise
/// unlimited swipes that `recordSwipe` then refuses.
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(myProfileProvider).maybeWhen(
        data: (p) => p.subStatus != 'free',
        orElse: () => false,
      );
});

/// The "go premium" prompt in Settings.
///
/// It shows **no prices**. The real, localised, current prices come from the
/// store on the paywall itself — a `$4.99` hard-coded here is wrong in every
/// other currency and stale the first time you run a promotion.
class UpgradeCard extends ConsumerWidget {
  const UpgradeCard({super.key, this.isTeacher = false});

  final bool isTeacher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return GestureDetector(
      onTap: () => context.push('/premium'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l10n.upgradeToPremium,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 10),
            _line(l10n.benefitUnlimitedSwipes),
            if (isTeacher) _line(l10n.benefitFeaturedBadge),
          ],
        ),
      ),
    );
  }

  Widget _line(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, color: Colors.white70, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

/// Shown instead of the upgrade card once they have paid: what they have, and
/// the store's own management screen (which is the ONLY place a subscription can
/// be cancelled — Apple and Google do not let an app do it, and users who cannot
/// find "cancel" leave one-star reviews and charge back).
class PremiumStatusCard extends StatelessWidget {
  const PremiumStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.skyLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded,
              color: Color(0xFF7C3AED), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.premiumPlan,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.text)),
                Text(l10n.manageSubscriptionHint,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.text2, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
