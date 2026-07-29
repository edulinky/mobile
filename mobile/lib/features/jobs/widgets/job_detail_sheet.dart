import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../models/job_card.dart';
import 'salary_period_x.dart';

/// Full job details for a TEACHER browsing the Jobs deck.
///
/// A separate widget from `JobCardDetailScreen` on purpose — that screen is the
/// institution's own management view (edit / close / see who applied), and an
/// applicant list is exactly the kind of thing a browsing teacher must never
/// see (it would expose other teachers' identities to someone who is not the
/// job's owner). This is read-only, and needs no network call: the card the
/// teacher is looking at already carries everything it shows.
Future<void> showJobDetailSheet(BuildContext context, JobCard job) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _JobDetailSheet(job: job),
  );
}

class _JobDetailSheet extends StatelessWidget {
  const _JobDetailSheet({required this.job});

  final JobCard job;

  String _contractLabel(BuildContext context) => switch (job.contractType) {
        ContractType.fullTime => context.l10n.contractFullTime,
        ContractType.partTime => context.l10n.contractPartTime,
        ContractType.contract => context.l10n.contractContract,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.skyLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.skyBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    job.institutionLogoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                        Icons.account_balance_rounded,
                        color: AppColors.skyDark),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.institutionName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.text)),
                    if (job.city.isNotEmpty)
                      Text(job.city,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.text3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(job.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 6),
          Text(
            job.level.isEmpty ? job.subject : '${job.subject} · ${job.level}',
            style: const TextStyle(
                color: AppColors.skyDeeper,
                fontWeight: FontWeight.w600,
                fontSize: 14),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if (job.salaryRange().isNotEmpty)
                _chip(Icons.payments_outlined,
                    '${job.salaryRange()}${job.salaryPeriod.short(context)}'),
              _chip(Icons.schedule_rounded, _contractLabel(context)),
              if (job.startAt != null)
                _chip(
                    Icons.event_rounded,
                    DateFormat.yMMMd(Localizations.localeOf(context).toString())
                        .format(job.startAt!)),
              if (job.distanceKm > 0)
                _chip(Icons.location_on_outlined, l10n.kmAway(job.distanceKm)),
            ],
          ),
          if (job.description.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(job.description,
                style: const TextStyle(
                    color: AppColors.text2, fontSize: 14.5, height: 1.55)),
          ],
          if (job.videoUrl.isNotEmpty) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse(job.videoUrl),
                  mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
              label: Text(l10n.watchIntroVideo),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.skyDeeper,
                side: const BorderSide(color: AppColors.skyLight),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ],
      ),
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
