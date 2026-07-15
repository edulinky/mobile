import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_image.dart';
import '../data/jobs_repository.dart';
import '../models/job_card.dart';
import '../widgets/salary_period_x.dart';

/// An institution's own job card: its details, its applicants, and the controls
/// to edit or close it.
class JobCardDetailScreen extends ConsumerWidget {
  const JobCardDetailScreen({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cards = ref.watch(myJobCardsProvider);

    return Scaffold(
      backgroundColor: AppColors.skyBg,
      appBar: AppBar(
        backgroundColor: AppColors.skyBg,
        elevation: 0,
        title: Text(l10n.jobDetailTitle,
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.text)),
      ),
      body: cards.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          final job = list.where((j) => j.jobId == jobId).firstOrNull;
          if (job == null) {
            return Center(child: Text(l10n.jobNotFound));
          }
          return _Body(job: job);
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.job});

  final JobCard job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final applications = ref.watch(myApplicationsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(job.title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(job.subject,
            style: const TextStyle(color: AppColors.skyDeeper, fontSize: 14)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            if (job.salaryRange().isNotEmpty)
              _chip(Icons.payments_outlined,
                  '${job.salaryRange()}${job.salaryPeriod.short(context)}'),
            _chip(Icons.schedule_rounded, switch (job.contractType) {
              ContractType.fullTime => l10n.contractFullTime,
              ContractType.partTime => l10n.contractPartTime,
              ContractType.contract => l10n.contractContract,
            }),
            if (job.level.isNotEmpty)
              _chip(Icons.school_outlined, job.level),
            if (job.startAt != null)
              _chip(Icons.event_rounded,
                  DateFormat.yMMMd(Localizations.localeOf(context).toString())
                      .format(job.startAt!)),
            if (job.city.isNotEmpty)
              _chip(Icons.location_on_outlined, job.city),
          ],
        ),
        if (job.description.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(job.description,
              style: const TextStyle(
                  color: AppColors.text2, fontSize: 14.5, height: 1.55)),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push('/institution/job/${job.jobId}/edit', extra: job),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(l10n.editJob),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.skyDeeper,
                  side: const BorderSide(color: AppColors.skyLight),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                // A draft is published; an active card is closed; a closed card
                // is reopened.
                onPressed: () => ref.read(jobsRepositoryProvider).setStatus(
                      job.jobId,
                      job.isActive ? 'closed' : 'active',
                    ),
                icon: Icon(
                    job.isActive
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                    size: 18),
                label: Text(job.isDraft
                    ? l10n.publishJob
                    : job.isActive
                        ? l10n.closeJob
                        : l10n.reopenJob),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      job.isActive ? AppColors.error : const Color(0xFF16A34A),
                  side: const BorderSide(color: AppColors.skyLight),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Text(l10n.applicantsSection,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 10),
        applications.when(
          loading: () =>
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )),
          error: (e, _) => Text('$e'),
          data: (all) {
            final mine = all.where((a) => a.jobId == job.jobId).toList();
            if (mine.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(l10n.noApplicantsYet,
                    style: const TextStyle(color: AppColors.text3)),
              );
            }
            return Column(
              children: [
                for (final a in mine)
                  InkWell(
                    onTap: () => context.push('/profile/${a.teacherId}'),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          ClipOval(
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: AvatarImage(
                                  url: a.teacherPhotoUrl, iconSize: 22),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(a.teacherName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.5,
                                    color: AppColors.text)),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.text3),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.skyLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.skyDeeper),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.skyDeeper)),
          ],
        ),
      );
}
