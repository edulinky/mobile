import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/teacher_card_model.dart';
import '../providers/swipe_controller.dart';
import '../../profile/data/profile_repository.dart';
import '../widgets/deck_empty_state.dart';
import '../widgets/swipe_card.dart';
import '../widgets/quota_banner.dart';
import '../../../core/widgets/avatar_image.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../notifications/widgets/activity_bell.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/l10n_extension.dart';

class StudentDiscoverScreen extends ConsumerWidget {
  const StudentDiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(teacherDeckProvider);
    final controller = ref.read(teacherDeckProvider.notifier);

    // A rejected swipe (quota exhausted) surfaces here — the card was already
    // put back by the controller, so this is the only thing left to say.
    ref.listen<String?>(teacherDeckProvider.select((s) => s.error), (_, error) {
      if (error == null) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      controller.clearError();
    });

    void swipe(TeacherCardModel card, bool liked) =>
        controller.swipe(card, liked: liked);

    final cards = state.cards;
    return Scaffold(
      backgroundColor: AppColors.skyBg,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _topBar(context, l10n, state),
                Expanded(child: _swipeArea(context, ref, l10n, state, swipe)),
                _actionButtons(context, cards, swipe),
                const BottomNav(currentIndex: 0),
              ],
            ),
          ),
          if (state.matchedWith != null)
            _MatchOverlay(
              teacher: state.matchedWith!,
              onSendMessage: () {
                final matched = state.matchedWith!;
                final matchId = state.matchId;
                controller.dismissMatch();
                context.push('/student/chat', extra: {
                  'matchId': matchId ?? '',
                  'otherName': matched.name,
                  'otherAvatarUrl': matched.avatarUrl,
                  'otherUid': matched.uid,
                });
              },
              onKeepSwiping: controller.dismissMatch,
            ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context, dynamic l10n, SwipeState<TeacherCardModel> state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(l10n.discoverTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.text)),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              if (!state.quota.unlimited)
                QuotaBanner(
                  remaining: state.quota.remaining,
                  total: state.quota.primary.limit + state.quota.discovery.limit,
                ),
              const SizedBox(width: 10),
              const ActivityBell(role: NavRole.student),
            ],
          ),
        ],
      ),
    );
  }

  Widget _swipeArea(
    BuildContext context,
    WidgetRef ref,
    dynamic l10n,
    SwipeState<TeacherCardModel> state,
    void Function(TeacherCardModel, bool) swipe,
  ) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final cards = state.cards;
    if (cards.isEmpty) {
      return DeckEmptyState(
        radiusKm: state.radiusKm,
        canSearchWider: state.canSearchWider,
        onRefresh: () => ref.read(teacherDeckProvider.notifier).refresh(),
        onSearchWider: () =>
            ref.read(teacherDeckProvider.notifier).searchWider(),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Render back-to-front so the top card (index 0) paints last.
          for (int i = (cards.length - 1).clamp(0, 2); i >= 0; i--)
            SwipeCard(
              key: ValueKey(cards[i].uid),
              teacher: cards[i],
              isTop: i == 0,
              stackOffset: i,
              onSwiped: (liked) => swipe(cards[i], liked),
              onBlocked: () => ref
                  .read(teacherDeckProvider.notifier)
                  .removeCard(cards[i].uid),
              onTap: () => context.push('/profile/${cards[i].uid}'),
            ),
        ],
      ),
    );
  }

  Widget _actionButtons(
    BuildContext context,
    List<TeacherCardModel> cards,
    void Function(TeacherCardModel, bool) swipe,
  ) {
    final top = cards.isEmpty ? null : cards.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.close_rounded,
            color: AppColors.error,
            size: 52,
            onTap: top == null ? null : () => swipe(top, false),
          ),
          _ActionButton(
            icon: Icons.info_outline_rounded,
            color: AppColors.skyDark,
            size: 40,
            onTap: top == null
                ? null
                : () => context.push('/profile/${top.uid}'),
          ),
          _ActionButton(
            icon: Icons.thumb_up_rounded,
            color: Colors.green,
            size: 52,
            onTap: top == null ? null : () => swipe(top, true),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.color, required this.size, this.onTap});

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
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

class _MatchOverlay extends ConsumerWidget {
  const _MatchOverlay({
    required this.teacher,
    required this.onSendMessage,
    required this.onKeepSwiping,
  });

  final TeacherCardModel teacher;
  final VoidCallback onSendMessage;
  final VoidCallback onKeepSwiping;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // My own photo — the prototype hard-coded a stock stranger here.
    final myPhoto = ref.watch(myProfileProvider).valueOrNull?.photoUrl ?? '';
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const Icon(Icons.handshake_rounded, size: 56, color: AppColors.sky),
              const SizedBox(height: 20),
              Text(l10n.itsAMatch,
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text(l10n.matchSubtitle(teacher.name),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _avatar(myPhoto),
                  const SizedBox(width: 16),
                  const Icon(Icons.handshake_rounded, size: 32, color: AppColors.sky),
                  const SizedBox(width: 16),
                  _avatar(teacher.avatarUrl),
                ],
              ),
              const Spacer(flex: 2),
              ElevatedButton(
                onPressed: onSendMessage,
                child: Text(l10n.sendMessage),
              ),
              const SizedBox(height: 12),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
                onPressed: onKeepSwiping,
                child: Text(l10n.keepSwiping),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(String url) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.sky, width: 3),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12)],
      ),
      child: ClipOval(
        child: SizedBox(
          width: 96,
          height: 96,
          // Handles the empty-url case; a user may have no photo.
          child: AvatarImage(url: url, iconSize: 40),
        ),
      ),
    );
  }
}
