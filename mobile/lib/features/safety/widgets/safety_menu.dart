import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../data/safety_repository.dart';

/// The ⋮ menu that must exist on every surface showing another user.
///
/// App Store Guideline 1.2 requires that a user can report objectionable content
/// and block an abusive user from *within* the app. Burying it in settings is
/// not enough — it has to be where the person is.
class SafetyMenu extends ConsumerWidget {
  const SafetyMenu({
    super.key,
    required this.targetUid,
    required this.targetName,
    this.color = AppColors.text2,
    this.onBlocked,
  });

  final String targetUid;
  final String targetName;
  final Color color;

  /// Called after a successful block — the caller usually pops the screen, since
  /// the person they just blocked should not still be on it.
  final VoidCallback? onBlocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final blocked =
        ref.watch(myBlocksProvider).valueOrNull?.contains(targetUid) ?? false;

    // IconButton's default 48x48 minimum tap target does not fit inside the
    // 36px circle on a deck card — it overflows and pushes the glyph off-centre.
    // Strip the padding and let the parent size it; the tap target stays large
    // because the whole circle is the button.
    return IconButton(
      icon: Icon(Icons.more_horiz_rounded, color: color),
      tooltip: l10n.moreOptions,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      splashRadius: 20,
      onPressed: () => _openSheet(context, ref, blocked),
    );
  }

  /// An action sheet, not a popup menu: this is the iOS convention for
  /// destructive actions, and it gives Report/Block room to *look* destructive
  /// rather than reading as two more menu rows.
  Future<void> _openSheet(
    BuildContext context,
    WidgetRef ref,
    bool blocked,
  ) async {
    final l10n = context.l10n;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                targetName,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.text),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppColors.error),
              title: Text(l10n.reportUser,
                  style: const TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w600)),
              subtitle: Text(l10n.reportUserSubtitle),
              onTap: () => Navigator.of(ctx).pop('report'),
            ),
            ListTile(
              leading: Icon(
                  blocked ? Icons.lock_open_rounded : Icons.block_rounded,
                  color: AppColors.error),
              title: Text(blocked ? l10n.unblockUser : l10n.blockUser,
                  style: const TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w600)),
              subtitle:
                  Text(blocked ? l10n.unblockUserSubtitle : l10n.blockUserSubtitle),
              onTap: () => Navigator.of(ctx).pop('block'),
            ),
            const Divider(height: 8),
            ListTile(
              title: Center(
                child: Text(l10n.cancel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.text2)),
              ),
              onTap: () => Navigator.of(ctx).pop(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice == null || !context.mounted) return;
    if (choice == 'report') {
      await _report(context, ref);
    } else {
      await _toggleBlock(context, ref, blocked);
    }
  }

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final reason = await showModalBottomSheet<ReportReason>(
      context: context,
      showDragHandle: true,
      // Seven reasons plus a header do not fit in the default half-height sheet
      // on a small phone — let it grow and scroll rather than clip.
      isScrollControlled: true,
      builder: (ctx) => _ReasonSheet(name: targetName),
    );
    if (reason == null || !context.mounted) return;

    try {
      final isNew = await ref
          .read(safetyRepositoryProvider)
          .report(reportedId: targetUid, reason: reason);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isNew ? l10n.reportSent : l10n.reportAlreadySent),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _toggleBlock(
    BuildContext context,
    WidgetRef ref,
    bool blocked,
  ) async {
    final l10n = context.l10n;
    if (!blocked) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.blockUserTitle(targetName)),
          content: Text(l10n.blockUserBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.blockUser,
                  style: const TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
    }

    try {
      await ref
          .read(safetyRepositoryProvider)
          .setBlocked(targetUid, blocked: !blocked);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(blocked ? l10n.userUnblocked : l10n.userBlocked)),
      );
      if (!blocked) onBlocked?.call();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

class _ReasonSheet extends StatelessWidget {
  const _ReasonSheet({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reasons = <ReportReason, String>{
      ReportReason.harassment: l10n.reasonHarassment,
      ReportReason.inappropriateContent: l10n.reasonInappropriate,
      ReportReason.spam: l10n.reasonSpam,
      ReportReason.fakeProfile: l10n.reasonFakeProfile,
      ReportReason.underage: l10n.reasonUnderage,
      ReportReason.safetyConcern: l10n.reasonSafety,
      ReportReason.other: l10n.reasonOther,
    };

    return SafeArea(
      child: ConstrainedBox(
        // Never taller than 80% of the screen; scrolls if the reasons do not fit.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(l10n.reportUserTitle(name),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.text)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(l10n.reportUserBody,
                  style: const TextStyle(fontSize: 13, color: AppColors.text2)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final e in reasons.entries)
                    ListTile(
                      dense: true,
                      title: Text(e.value),
                      onTap: () => Navigator.of(context).pop(e.key),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
