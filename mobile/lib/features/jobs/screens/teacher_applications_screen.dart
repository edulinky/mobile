import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../data/jobs_repository.dart';
import '../models/job_card.dart';

/// The jobs a teacher has applied to. Applying is one-directional — a right
/// swipe on a Job Card *is* the application — so there's nothing to act on
/// here; it's a record of what they've applied for.
class TeacherApplicationsScreen extends ConsumerWidget {
  const TeacherApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final apps = ref.watch(teacherApplicationsProvider);
    return Scaffold(
      backgroundColor: AppColors.skyBg,
      appBar: AppBar(
        backgroundColor: AppColors.skyBg,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.myApplications),
      ),
      body: apps.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              l10n.errorGeneric,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.text2),
            ),
          ),
        ),
        data: (list) {
          if (list.isEmpty) return _EmptyState(l10n: l10n);
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _ApplicationTile(app: list[i]),
          );
        },
      ),
    );
  }
}

class _ApplicationTile extends StatelessWidget {
  const _ApplicationTile({required this.app});

  final JobApplication app;

  /// Compact relative time, matching the convention used elsewhere (e.g. the
  /// notifications list): now / 5m / 3h / 2d.
  String _ago(DateTime? t) {
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final when = _ago(app.createdAt);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.skyLight),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.skyBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.work_outline_rounded,
                color: AppColors.skyDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.jobTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text),
                ),
                const SizedBox(height: 4),
                Text(
                  when.isEmpty ? l10n.applied : '${l10n.applied} · $when',
                  style: const TextStyle(fontSize: 13, color: AppColors.text2),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l10n.applied,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF15803D)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_outlined,
                size: 64, color: AppColors.text3),
            const SizedBox(height: 16),
            Text(
              l10n.noApplicationsYet,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700, color: AppColors.text),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noApplicationsYetSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.text2),
            ),
          ],
        ),
      ),
    );
  }
}
