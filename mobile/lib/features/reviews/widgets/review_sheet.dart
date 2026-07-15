import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../data/reviews_repository.dart';
import '../models/review.dart';

/// Compose (or edit) a review of a teacher.
///
/// Returns true if a review was submitted, so the caller can confirm it — the
/// review does not appear immediately, and a user who is told nothing assumes it
/// failed and writes it again.
Future<bool> showReviewSheet(
  BuildContext context, {
  required String targetId,
  required String targetName,
  Review? existing,
}) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReviewSheet(
      targetId: targetId,
      targetName: targetName,
      existing: existing,
    ),
  );
  return done == true;
}

class _ReviewSheet extends ConsumerStatefulWidget {
  const _ReviewSheet({
    required this.targetId,
    required this.targetName,
    this.existing,
  });

  final String targetId;
  final String targetName;
  final Review? existing;

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  // The sheet owns the controller. A controller created by the caller and
  // disposed when `showModalBottomSheet` returns is still being read by the exit
  // animation — which is exactly how the "used after being disposed" crash in the
  // add-subject dialog happened.
  late final TextEditingController _comment =
      TextEditingController(text: widget.existing?.comment ?? '');
  late int _rating = widget.existing?.rating ?? 0;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(reviewsRepositoryProvider).submit(
            targetId: widget.targetId,
            rating: _rating,
            comment: _comment.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = context.l10n.reviewFailed('$e');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      // Lift the sheet clear of the keyboard — the comment field is the point of
      // it, and a field you cannot see while typing in is not a field.
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 16),
              Text(l10n.reviewSheetTitle(widget.targetName),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800, color: AppColors.text)),
              const SizedBox(height: 4),
              Text(l10n.reviewModerationNote,
                  style: const TextStyle(fontSize: 13, color: AppColors.text2)),
              const SizedBox(height: 18),
              Text(l10n.yourRatingLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.text)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) {
                  final value = i + 1;
                  return IconButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _rating = value),
                    padding: const EdgeInsets.only(right: 4),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      value <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 38,
                      color: const Color(0xFFF59E0B),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _comment,
                enabled: !_busy,
                maxLines: 4,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: l10n.reviewCommentHint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(_error!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _rating == 0 || _busy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.submitReviewBtn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
