import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../data/jobs_repository.dart';
import '../models/job_card.dart';
import '../widgets/salary_period_x.dart';

/// An institution's job cards, live from Firestore.
class InstitutionDashboardScreen extends ConsumerWidget {
  const InstitutionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cards = ref.watch(myJobCardsProvider);

    return Scaffold(
      backgroundColor: AppColors.skyBg,
      // The nav goes in the Scaffold slot, not inside the body: a FAB floats
      // over the BODY, so a nav bar built into the body column ends up
      // underneath it and the tabs become unclickable.
      bottomNavigationBar:
          const BottomNav(currentIndex: 0, role: NavRole.institution),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/institution/job/new'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.postJob),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(l10n.dashboardTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800, color: AppColors.text)),
                ],
              ),
            ),
            Expanded(
              child: cards.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('$e', textAlign: TextAlign.center),
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) return _empty(context, l10n);
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _JobTile(job: list[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, dynamic l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.work_outline_rounded,
                size: 64, color: AppColors.text3),
            const SizedBox(height: 16),
            Text(l10n.noJobsYet,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 8),
            Text(l10n.noJobsYetSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.text2)),
          ],
        ),
      ),
    );
  }
}

class _JobTile extends ConsumerWidget {
  const _JobTile({required this.job});

  final JobCard job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return InkWell(
      onTap: () => context.push('/institution/job/${job.jobId}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(job.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.text)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: job.isActive
                        ? const Color(0xFFDCFCE7)
                        : job.isDraft
                            ? const Color(0xFFFEF3C7)
                            : AppColors.skyLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    job.isActive
                        ? l10n.statusActive
                        : job.isDraft
                            ? l10n.statusDraft
                            : l10n.statusClosed,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: job.isActive
                          ? const Color(0xFF16A34A)
                          : job.isDraft
                              ? const Color(0xFFD97706)
                              : AppColors.text3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(job.subject,
                style: const TextStyle(fontSize: 13, color: AppColors.skyDeeper)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.people_outline_rounded,
                    size: 15, color: AppColors.text3),
                const SizedBox(width: 5),
                Text(l10n.applicantCount(job.applicantCount),
                    style:
                        const TextStyle(fontSize: 12.5, color: AppColors.text2)),
                const Spacer(),
                if (job.salaryRange().isNotEmpty)
                  Text('${job.salaryRange()}${job.salaryPeriod.short(context)}',
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text2)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
