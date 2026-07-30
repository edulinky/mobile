import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_image.dart';
import '../../profile/data/profile_repository.dart';
import '../data/matches_repository.dart';
import '../models/chat_models.dart';

/// The signed-in user's matches: the ones nobody has written in yet as a row of
/// avatars ("new matches"), the rest as a conversation list. A search field
/// filters both by the other person's name or the last message.
///
/// Shared by the student, teacher, and institution screens — a match is
/// symmetric, so there is nothing role-specific to render.
class MatchesList extends ConsumerStatefulWidget {
  const MatchesList({super.key, required this.chatRoute});

  /// Where to push a conversation, e.g. `/student/chat`.
  final String chatRoute;

  @override
  ConsumerState<MatchesList> createState() => _MatchesListState();
}

class _MatchesListState extends ConsumerState<MatchesList> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// The other person's name, resolved the same way each tile already does —
  /// watching here too is free: it is the same cached provider, not a second
  /// fetch.
  String _nameOf(MatchThread m) =>
      ref.watch(userProfileProvider(m.otherUid)).valueOrNull?.displayName ?? '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ref.watch(matchesProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.errLoadMatches('$e'), textAlign: TextAlign.center),
            ),
          ),
          data: (matches) {
            if (matches.isEmpty) return _empty(context, l10n);

            final query = _query.trim().toLowerCase();
            final visible = query.isEmpty
                ? matches
                : matches.where((m) {
                    return _nameOf(m).toLowerCase().contains(query) ||
                        m.lastMessage.toLowerCase().contains(query);
                  }).toList();

            final fresh = visible.where((m) => !m.hasMessages).toList();
            final threads = visible.where((m) => m.hasMessages).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: l10n.searchMatchesHint,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => setState(() {
                                _searchCtrl.clear();
                                _query = '';
                              }),
                            ),
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.skyLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.skyLight),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? _noResults(context, l10n)
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
                          children: [
                            if (fresh.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                                child: Text(l10n.newMatchesLabel,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.text2)),
                              ),
                              SizedBox(
                                height: 92,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  itemCount: fresh.length,
                                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                                  itemBuilder: (_, i) => _NewMatchAvatar(
                                    match: fresh[i],
                                    chatRoute: widget.chatRoute,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (threads.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                                child: Text(l10n.messagesLabel,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.text2)),
                              ),
                              for (final m in threads)
                                _ThreadTile(match: m, chatRoute: widget.chatRoute),
                            ],
                          ],
                        ),
                ),
              ],
            );
          },
        );
  }

  Widget _noResults(BuildContext context, dynamic l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 56, color: AppColors.text3),
            const SizedBox(height: 12),
            Text(l10n.noMatchesFound,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.text)),
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
            const Icon(Icons.handshake_outlined,
                size: 64, color: AppColors.text3),
            const SizedBox(height: 16),
            Text(l10n.noMatchesYet,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 8),
            Text(l10n.noMatchesYetSubtitle,
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

/// Opens the chat, passing what the header needs so it renders without a second
/// round-trip.
void _openChat(
  BuildContext context,
  String chatRoute,
  MatchThread match,
  String name,
  String photoUrl,
) {
  context.push(chatRoute, extra: {
    'matchId': match.matchId,
    'otherName': name,
    'otherAvatarUrl': photoUrl,
    'otherUid': match.otherUid,
  });
}

class _NewMatchAvatar extends ConsumerWidget {
  const _NewMatchAvatar({required this.match, required this.chatRoute});

  final MatchThread match;
  final String chatRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider(match.otherUid));
    final name = profile.valueOrNull?.displayName ?? '';
    final photo = profile.valueOrNull?.photoUrl ?? '';

    return GestureDetector(
      onTap: () => _openChat(context, chatRoute, match, name, photo),
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.sky, AppColors.skyDeeper],
                ),
              ),
              child: ClipOval(
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: AvatarImage(url: photo, iconSize: 28),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.text2),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadTile extends ConsumerWidget {
  const _ThreadTile({required this.match, required this.chatRoute});

  final MatchThread match;
  final String chatRoute;

  String _ago(DateTime? t) {
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider(match.otherUid));
    final name = profile.valueOrNull?.displayName ?? '';
    final photo = profile.valueOrNull?.photoUrl ?? '';
    final unread = match.unread;

    return InkWell(
      onTap: () => _openChat(context, chatRoute, match, name, photo),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            ClipOval(
              child: SizedBox(
                width: 52,
                height: 52,
                child: AvatarImage(url: photo, iconSize: 26),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.text),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    match.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: unread > 0 ? AppColors.text : AppColors.text3,
                      fontWeight:
                          unread > 0 ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_ago(match.lastMessageAt),
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.text3)),
                const SizedBox(height: 6),
                if (unread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.skyDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$unread',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
