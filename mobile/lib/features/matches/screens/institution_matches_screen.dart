import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../data/matches_repository.dart';
import '../widgets/matches_list.dart';

/// An institution's connections with teachers — created via `connectWithApplicant`
/// on an applicant's profile, never through a swipe deck (institutions have
/// none). Same `matches`/chat plumbing as everyone else; only the entry point
/// differs.
class InstitutionMatchesScreen extends ConsumerWidget {
  const InstitutionMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final count = ref.watch(matchesProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.skyBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(l10n.matchesTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800, color: AppColors.text)),
                  if (count > 0) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.skyLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l10n.matchesTotal(count),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.skyDeeper),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Expanded(child: MatchesList(chatRoute: '/institution/chat')),
            const BottomNav(currentIndex: 1, role: NavRole.institution),
          ],
        ),
      ),
    );
  }
}
