import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/firebase/firebase_refs.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../data/notifications_repository.dart';

/// The activity feed — matches, messages, verification decisions.
///
/// One screen for all three roles: the events differ, the presentation does not.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key, required this.role});

  final NavRole role;

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Opening the inbox is what "seeing" them means — clear the badge.
    ref.read(notificationsRepositoryProvider).markAllRead();
  }

  String get _matchesRoute => switch (widget.role) {
        NavRole.teacher => '/teacher/matches',
        _ => '/student/matches',
      };

  void _open(AppNotification n) {
    switch (n.type) {
      // Both lead to the conversation; a match with no messages opens an empty
      // thread, which is exactly where "say hello" belongs.
      case NotificationType.match:
      case NotificationType.message:
        final matchId = n.data['matchId'];
        if (matchId == null) return;
        context.push(_matchesRoute);
      // A new review is about YOUR profile, so that is where it opens — the
      // public view, which is the only place reviews are shown.
      case NotificationType.review:
        final me = Fb.auth.currentUser?.uid;
        if (me == null) return;
        context.push('/profile/$me');
      case NotificationType.verificationApproved:
      case NotificationType.verificationRejected:
      case NotificationType.jobApplication:
      case NotificationType.unknown:
        break;
    }
  }

  IconData _iconFor(NotificationType t) => switch (t) {
        // Handshake, not a heart — this is an education platform, not a
        // dating app. Same icon the Matches tab uses.
        NotificationType.match => Icons.handshake_rounded,
        NotificationType.message => Icons.chat_bubble_rounded,
        NotificationType.verificationApproved => Icons.verified_rounded,
        NotificationType.verificationRejected => Icons.error_outline_rounded,
        NotificationType.jobApplication => Icons.work_outline_rounded,
        NotificationType.review => Icons.star_rounded,
        NotificationType.unknown => Icons.notifications_none_rounded,
      };

  Color _colorFor(NotificationType t) => switch (t) {
        NotificationType.match => AppColors.skyDeeper,
        NotificationType.verificationApproved => const Color(0xFF16A34A),
        NotificationType.verificationRejected => AppColors.error,
        NotificationType.review => const Color(0xFFF59E0B),
        _ => AppColors.skyDark,
      };

  String _ago(DateTime? t) {
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  /// Institutions reach Activity from the bottom nav; the other roles push it
  /// from the bell in the Discover header.
  bool get isTab => widget.role == NavRole.institution;

  String get _homeRoute => switch (widget.role) {
        NavRole.teacher => '/teacher/discover',
        NavRole.institution => '/institution/dashboard',
        NavRole.student => '/student/discover',
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.skyBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(isTab ? 20 : 8, 8, 20, 8),
              child: Row(
                children: [
                  // The institution opens Activity as a bottom-nav TAB, which
                  // replaces the stack — there is nothing to pop, and a back
                  // button would blow up ("popped the last page off the stack").
                  // Students and teachers push it from the bell, so they get one.
                  if (!isTab)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: AppColors.text),
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go(_homeRoute),
                    ),
                  Text(l10n.activityTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800, color: AppColors.text)),
                ],
              ),
            ),
            Expanded(
              child: items.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.errLoadActivity('$e'),
                        textAlign: TextAlign.center),
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) return _empty(context, l10n);
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _tile(list[i]),
                  );
                },
              ),
            ),
            if (isTab) BottomNav(currentIndex: 1, role: widget.role),
          ],
        ),
      ),
    );
  }

  Widget _tile(AppNotification n) {
    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      onDismissed: (_) =>
          ref.read(notificationsRepositoryProvider).dismiss(n.id),
      child: InkWell(
        onTap: () => _open(n),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            // Unread items are tinted, so "what's new" is obvious at a glance.
            color: n.read ? Colors.white : AppColors.skyLight.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _colorFor(n.type).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconFor(n.type), size: 19, color: _colorFor(n.type)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title,
                        style: TextStyle(
                            fontWeight:
                                n.read ? FontWeight.w600 : FontWeight.w800,
                            fontSize: 14.5,
                            color: AppColors.text)),
                    const SizedBox(height: 2),
                    Text(n.body,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.text2, height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(_ago(n.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.text3)),
            ],
          ),
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
            const Icon(Icons.notifications_none_rounded,
                size: 64, color: AppColors.text3),
            const SizedBox(height: 16),
            Text(l10n.noActivityYet,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 8),
            Text(l10n.noActivityYetSubtitle,
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
