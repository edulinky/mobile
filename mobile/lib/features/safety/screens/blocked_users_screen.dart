import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_image.dart';
import '../../profile/data/profile_repository.dart';
import '../data/safety_repository.dart';

/// The people you have blocked, and the way back.
///
/// A block with no undo is a trap: people block in anger, or by mistap, and a
/// permanent one-way door means a mis-tap costs them a match they wanted. It is
/// also what App Review looks for — blocking must be manageable, not just
/// available.
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final blocks = ref.watch(myBlocksProvider);

    return Scaffold(
      backgroundColor: AppColors.skyBg,
      appBar: AppBar(
        backgroundColor: AppColors.skyBg,
        elevation: 0,
        title: Text(l10n.blockedUsers,
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.text)),
      ),
      body: blocks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('$e', textAlign: TextAlign.center),
          ),
        ),
        data: (uids) {
          if (uids.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.block_rounded,
                        size: 60, color: AppColors.text3),
                    const SizedBox(height: 14),
                    Text(l10n.noBlockedUsers,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.text)),
                    const SizedBox(height: 6),
                    Text(l10n.noBlockedUsersSubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.text2)),
                  ],
                ),
              ),
            );
          }
          final list = uids.toList();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _BlockedTile(uid: list[i]),
          );
        },
      ),
    );
  }
}

class _BlockedTile extends ConsumerWidget {
  const _BlockedTile({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(userProfileProvider(uid));
    final name = profile.valueOrNull?.displayName ?? '';
    final photo = profile.valueOrNull?.photoUrl ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 44,
              height: 44,
              child: AvatarImage(url: photo, iconSize: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name.isEmpty ? l10n.unknownUser : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.text),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref
                    .read(safetyRepositoryProvider)
                    .setBlocked(uid, blocked: false);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.userUnblocked)),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: Text(l10n.unblockUser,
                style: const TextStyle(
                    color: AppColors.skyDeeper, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
