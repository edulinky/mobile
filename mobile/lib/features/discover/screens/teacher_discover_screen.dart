import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../jobs/data/jobs_repository.dart';
import '../../jobs/models/job_card.dart';
import '../../safety/widgets/safety_menu.dart';
import '../../jobs/widgets/salary_period_x.dart';
import '../../jobs/widgets/job_detail_sheet.dart';
import '../models/job_card_model.dart';
import '../providers/swipe_controller.dart';
import '../widgets/deck_empty_state.dart';
import '../../profile/data/profile_repository.dart';
import '../models/student_card_model.dart';
import '../widgets/quota_banner.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../notifications/widgets/activity_bell.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_image.dart';
import '../../../core/extensions/l10n_extension.dart';

/// The teacher's two decks: Students (mutual — a right swipe can make a match)
/// and Jobs (one-directional — a right swipe IS the application).
class TeacherDiscoverScreen extends ConsumerStatefulWidget {
  const TeacherDiscoverScreen({super.key});

  @override
  ConsumerState<TeacherDiscoverScreen> createState() => _TeacherDiscoverScreenState();
}

class _TeacherDiscoverScreenState extends ConsumerState<TeacherDiscoverScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  /// The Job Cards deck, loaded from getJobCards. Applying removes the card.
  List<JobCard>? _jobQueue;
  bool _jobsLoading = true;
  /// Jobs are fetched exactly once, and only after the teacher is approved —
  /// an unapproved teacher's getJobCards call fails with "awaiting
  /// verification", and they only ever see the pending notice anyway.
  bool _jobsRequested = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    // Jobs load lazily once approval is known (see build) — not here, because an
    // unapproved teacher must never call getJobCards.
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() => _jobsLoading = true);
    try {
      final cards = await ref.read(jobsRepositoryProvider).getJobCards();
      if (mounted) setState(() => _jobQueue = cards);
    } catch (e, st) {
      debugPrint('load jobs failed: $e\n$st');
      if (mounted) {
        setState(() => _jobQueue = const []);
        _snack(e);
      }
    } finally {
      if (mounted) setState(() => _jobsLoading = false);
    }
  }

  /// Shows a failure as a clean, localised line — never the raw `'$e'`, which
  /// can carry the `[code] …` prefix and a full async stack trace (a snackbar
  /// then balloons to fill the screen).
  void _snack(Object e) {
    final msg = friendlyDeckError(e);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg == kDeckGenericError ? context.l10n.errorGeneric : msg),
    ));
  }

  void _swipe(bool interested, TeacherDiscoverItem item) {
    if (item is StudentItem) {
      // Quota-checked server-side; a mutual like creates the match.
      ref.read(studentDeckProvider.notifier).swipe(item.student, liked: interested);
      return;
    }
    if (item is! JobItem) return;

    // A job card is ONE-DIRECTIONAL: a right swipe is an application, and the
    // institution is notified immediately. There is no mutual swipe and no
    // match — the counterparty is an organisation, not a person.
    final job = item.job;
    setState(() => _jobQueue = [..._jobQueue!]..removeWhere((j) => j.jobId == job.jobId));
    if (!interested) return;

    _showAppliedSnack(job.title, job.institutionName);
    ref.read(jobsRepositoryProvider).applyToJob(job.jobId).catchError((e) {
      if (!mounted) return;
      // Put it back — the application did not happen.
      setState(() => _jobQueue = [job, ...?_jobQueue]);
      _snack(e);
    });
  }

  void _showAppliedSnack(String title, String institution) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.appliedToJob(title, institution)),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final deck = ref.watch(studentDeckProvider);
    // A teacher only reaches students once an admin has approved their
    // certificate — the server enforces this, so show the reason rather than a
    // raw failed-precondition.
    final isApproved = ref.watch(myProfileProvider).maybeWhen(
          data: (p) => p.isVerified,
          orElse: () => false,
        );

    // Fetch jobs the first time we know the teacher is approved. Deferred to a
    // post-frame callback so we never call setState during build.
    if (isApproved && !_jobsRequested) {
      _jobsRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadJobs();
      });
    }

    ref.listen<String?>(studentDeckProvider.select((s) => s.error), (_, error) {
      if (error == null || !isApproved) return;
      final message = error == kDeckGenericError ? l10n.errorGeneric : error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      ref.read(studentDeckProvider.notifier).clearError();
    });

    return Scaffold(
      backgroundColor: AppColors.skyBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context, l10n, deck),
            _buildTabBar(context, l10n),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  if (!isApproved)
                    _PendingVerificationNotice(l10n: l10n)
                  else if (deck.loading)
                    const Center(child: CircularProgressIndicator())
                  else if (deck.cards.isEmpty)
                    DeckEmptyState(
                      radiusKm: deck.radiusKm,
                      canSearchWider: deck.canSearchWider,
                      onRefresh: () =>
                          ref.read(studentDeckProvider.notifier).refresh(),
                      onSearchWider: () =>
                          ref.read(studentDeckProvider.notifier).searchWider(),
                    )
                  else
                    _buildQueue(context, l10n,
                        deck.cards.map<TeacherDiscoverItem>(StudentItem.new).toList()),
                  if (!isApproved)
                    _PendingVerificationNotice(l10n: l10n)
                  else if (_jobsLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    _buildQueue(context, l10n,
                        (_jobQueue ?? const <JobCard>[])
                            .map<TeacherDiscoverItem>(JobItem.new)
                            .toList()),
                ],
              ),
            ),
            const BottomNav(currentIndex: 0, role: NavRole.teacher),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, dynamic l10n, SwipeState deck) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Flexible so a longer translation truncates instead of pushing the
          // quota chip and bell off the edge.
          Flexible(
            child: Text(l10n.teacherDiscoverTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.text)),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              QuotaBanner(
                remaining: deck.quota.remaining,
                total: deck.quota.primary.limit + deck.quota.discovery.limit,
                isPremium: deck.quota.unlimited,
              ),
              const SizedBox(width: 10),
              const ActivityBell(role: NavRole.teacher),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, dynamic l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.skyLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabs,
                indicator: BoxDecoration(
                  color: AppColors.skyDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.text2,
                // Same weight in both states, so selecting a tab does not resize it.
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: [
                  Tab(text: l10n.tabStudents),
                  Tab(text: l10n.tabJobs),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Applying is one-directional (a right swipe on a Job Card IS the
          // application) so there's nothing on the Jobs tab to show what was
          // already sent — this is that record.
          Tooltip(
            message: l10n.myApplications,
            child: InkWell(
              onTap: () => context.push('/teacher/applications'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.skyLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_outlined,
                    size: 20, color: AppColors.text),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueue(BuildContext context, dynamic l10n, List<TeacherDiscoverItem> queue) {
    // Only the Jobs tab lands here empty — the Students tab has its own
    // DeckEmptyState (refresh / search wider), because people and jobs run out
    // for different reasons and offer different ways out.
    if (queue.isEmpty) return _JobsEmptyState(onStartOver: _loadJobs);

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Render the FRONT of the queue (indices 0..2), not the back —
                // `isTop` below requires i == 0, so the top card must always be
                // among what's rendered or nothing is swipeable once the queue
                // has more than 3 items.
                for (int i = (queue.length - 1).clamp(0, 2); i >= 0; i--)
                  _buildSwipeCard(context, l10n, queue, i),
              ],
            ),
          ),
        ),
        _buildActionRow(context, l10n, queue),
      ],
    );
  }

  Widget _buildSwipeCard(BuildContext context, dynamic l10n, List<TeacherDiscoverItem> queue, int i) {
    final item = queue[i];
    final isTop = i == 0;
    final scale = 1.0 - i * 0.04;
    final yOff = i * -14.0;

    return _SwipeableCard(
      key: ValueKey(switch (item) { StudentItem s => s.student.uid, JobItem j => j.job.jobId }),
      isTop: isTop,
      scale: scale,
      yOffset: yOff,
      onSwiped: isTop ? (liked) => _swipe(liked, item) : null,
      child: switch (item) {
        StudentItem s => _StudentCardContent(
            student: s.student,
            l10n: l10n,
            onBlocked: () =>
                ref.read(studentDeckProvider.notifier).removeCard(s.student.uid),
          ),
        JobItem j     => _JobCardContent(job: j.job, l10n: l10n),
      },
    );
  }

  Widget _buildActionRow(BuildContext context, dynamic l10n, List<TeacherDiscoverItem> queue) {
    final item = queue.isEmpty ? null : queue.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionBtn(icon: Icons.close_rounded,     color: AppColors.error, size: 52,
              onTap: item == null ? null : () => _swipe(false, item)),
          _ActionBtn(
            icon: Icons.info_outline_rounded, color: AppColors.skyDark, size: 40,
            onTap: switch (item) {
              null => null,
              StudentItem s => () => context.push('/profile/${s.student.uid}'),
              // Jobs have no user profile — show the full posting instead. A
              // sheet, not a push: the data is already in memory (no network
              // call), and this is institution-owner-only info's read-only
              // counterpart, not `JobCardDetailScreen` (that screen exposes
              // edit/close controls and the applicant list — a browsing
              // teacher must never see either).
              JobItem j => () => showJobDetailSheet(context, j.job),
            },
          ),
          _ActionBtn(
            icon: switch (item) {
              JobItem _ => Icons.send_rounded,
              _         => Icons.thumb_up_rounded,
            },
            color: Colors.green, size: 52,
            onTap: item == null ? null : () => _swipe(true, item),
          ),
        ],
      ),
    );
  }
}

// ── Swipeable wrapper ──────────────────────────────────────────────────────────

class _SwipeableCard extends StatefulWidget {
  const _SwipeableCard({
    super.key,
    required this.child,
    required this.isTop,
    required this.scale,
    required this.yOffset,
    this.onSwiped,
  });

  final Widget child;
  final bool isTop;
  final double scale;
  final double yOffset;
  final void Function(bool liked)? onSwiped;

  @override
  State<_SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<_SwipeableCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<Offset> _anim;
  Offset _offset = Offset.zero;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _anim = AlwaysStoppedAnimation(Offset.zero);
    _ctrl.addListener(() { if (_animating) setState(() => _offset = _anim.value); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_animating || widget.onSwiped == null) return;
    setState(() => _offset += d.delta);
  }

  void _onPanEnd(DragEndDetails d) {
    if (widget.onSwiped == null) return;
    if (_offset.dx.abs() > 90) {
      _flyOff(_offset.dx > 0);
    } else {
      _springBack();
    }
  }

  void _springBack() {
    _animating = true;
    _anim = Tween<Offset>(begin: _offset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward(from: 0).then((_) {
      if (mounted) setState(() { _offset = Offset.zero; _animating = false; });
    });
  }

  void _flyOff(bool right) {
    _animating = true;
    _anim = Tween<Offset>(begin: _offset, end: Offset(right ? 700 : -700, _offset.dy + 80))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward(from: 0).then((_) { if (mounted) widget.onSwiped!(right); });
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: _offset + Offset(0, widget.yOffset),
      child: Transform.rotate(
        angle: widget.isTop ? (_offset.dx / 300).clamp(-0.4, 0.4) : 0,
        child: Transform.scale(
          scale: widget.scale,
          child: GestureDetector(
            onPanUpdate: widget.isTop ? _onPanUpdate : null,
            onPanEnd:    widget.isTop ? _onPanEnd    : null,
            child: Stack(
              children: [
                widget.child,
                if (widget.isTop) _stamp(true,  (_offset.dx / 100).clamp(0, 1)),
                if (widget.isTop) _stamp(false, (-_offset.dx / 100).clamp(0, 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stamp(bool isLike, double opacity) {
    return Positioned(
      top: 48,
      left: isLike ? null : 24,
      right: isLike ? 24 : null,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: isLike ? 0.3 : -0.3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: isLike ? Colors.green : AppColors.error, width: 3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(isLike ? 'YES' : 'PASS',
                style: TextStyle(
                    color: isLike ? Colors.green : AppColors.error,
                    fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ),
        ),
      ),
    );
  }
}

// ── Student card content ───────────────────────────────────────────────────────

class _StudentCardContent extends StatelessWidget {
  const _StudentCardContent({
    required this.student,
    required this.l10n,
    this.onBlocked,
  });
  final StudentCardModel student;
  final dynamic l10n;

  /// Called after this student is blocked — the card must leave the deck.
  final VoidCallback? onBlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AvatarImage(url: student.avatarUrl),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.78)],
                stops: const [0.45, 1.0],
              ),
            ),
          ),
          // Report/block straight from the deck — a teacher should not have to
          // open a profile to get away from someone.
          Positioned(
            top: 12, right: 12,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.black26,
              child: SafetyMenu(
                targetUid: student.uid,
                targetName: student.name,
                color: Colors.white,
                onBlocked: onBlocked,
              ),
            ),
          ),
          Positioned(
            top: 16, left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.skyDark, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.school_rounded, size: 13, color: Colors.white),
                const SizedBox(width: 5),
                Text(student.gradeLevel, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
          Positioned(
            left: 20, right: 20, bottom: 28,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(student.name,
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                const SizedBox(width: 3),
                Text(l10n.kmAway(student.distanceKm),
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
              const SizedBox(height: 8),
              Text(student.bio, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6,
                children: student.subjects.map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                )).toList()),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Job card content ───────────────────────────────────────────────────────────

class _JobCardContent extends StatelessWidget {
  const _JobCardContent({required this.job, required this.l10n});
  final JobCard job;
  final dynamic l10n;

  String _contractLabel() => switch (job.contractType) {
    ContractType.fullTime => l10n.contractFullTime,
    ContractType.partTime => l10n.contractPartTime,
    ContractType.contract => l10n.contractContract,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0C2A4A), Color(0xFF0369A1)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(job.institutionLogoUrl, fit: BoxFit.cover,
                    errorBuilder: (ctx, e, s) => const Icon(Icons.account_balance_rounded, color: Colors.white70, size: 28)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(job.institutionName,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.location_on_rounded, color: Colors.white54, size: 13),
                const SizedBox(width: 3),
                // A long city name must truncate, not overflow the card.
                Expanded(
                  child: Text(job.city,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ),
              ]),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.work_outline_rounded, size: 12, color: Colors.white70),
                const SizedBox(width: 4),
                Text(l10n.jobCardLabel, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
          const Spacer(),
          Text(job.title,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1.2)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.sky.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
                job.level.isEmpty ? job.subject : '${job.subject} · ${job.level}',
                style: const TextStyle(color: AppColors.sky, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          const SizedBox(height: 16),
          Text(job.description, maxLines: 3, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60, fontSize: 13.5, height: 1.5)),
          const SizedBox(height: 20),
          Row(children: [
            if (job.salaryRange().isNotEmpty)
              _infoChip(Icons.payments_outlined,
                  '${job.salaryRange()}${job.salaryPeriod.short(context)}'),
            const SizedBox(width: 10),
            _infoChip(Icons.schedule_rounded, _contractLabel()),
          ]),
        ]),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.color, required this.size, this.onTap});
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}

/// Shown in the Students tab while a teacher's certificate is still under review.
class _PendingVerificationNotice extends StatelessWidget {
  const _PendingVerificationNotice({required this.l10n});

  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_top_rounded,
                size: 64, color: AppColors.text3),
            const SizedBox(height: 16),
            Text(l10n.pendingDiscoverTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 8),
            Text(l10n.pendingDiscoverBody,
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

/// Shown when the Jobs deck runs out.
///
/// Not the Students copy ("check back tomorrow for new matches"): a job card is
/// not a person and there is no match to wait for. Skipped jobs come straight
/// back on a reload — only the ones already applied to are gone for good, and
/// those are gone because the application is with the institution, not because
/// a day has to pass.
///
/// It also says **why** the deck is empty. The server only returns jobs in the
/// subjects this teacher teaches, so a teacher with one subject can very easily
/// see nothing — and "no jobs" would read as "this platform has no jobs" rather
/// than "widen what you teach". Hence the second button, straight to the field
/// that decides it.
class _JobsEmptyState extends StatelessWidget {
  const _JobsEmptyState({required this.onStartOver});

  final VoidCallback onStartOver;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.work_off_outlined, size: 64, color: AppColors.text3),
            const SizedBox(height: 16),
            Text(l10n.noMoreJobs,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 8),
            Text(l10n.noMoreJobsSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.text2)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStartOver,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l10n.startOverJobs),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                // Reload on the way back: the whole point of going there was to
                // change which jobs are visible, so coming back to the same
                // empty deck would look broken.
                onPressed: () async {
                  await context.push('/teacher/profile');
                  onStartOver();
                },
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(l10n.editMySubjects),
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
        ),
      ),
    );
  }
}
