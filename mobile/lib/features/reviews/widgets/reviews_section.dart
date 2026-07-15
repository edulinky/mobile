import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/firebase/firebase_refs.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_image.dart';
import '../../../core/widgets/star_rating.dart';
import '../data/reviews_repository.dart';
import '../models/review.dart';
import 'review_sheet.dart';

/// The Reviews block on a teacher's public profile: what other people said, and
/// — if you have matched with this teacher — your own review and a way to write
/// or change it.
class ReviewsSection extends ConsumerWidget {
  const ReviewsSection({
    super.key,
    required this.targetId,
    required this.targetName,
  });

  final String targetId;
  final String targetName;

  bool get _isMe => Fb.auth.currentUser?.uid == targetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final reviews = ref.watch(approvedReviewsProvider(targetId)).valueOrNull ??
        const <Review>[];
    final mine = ref.watch(myReviewProvider(targetId)).valueOrNull;
    final canReview = !_isMe && ref.watch(canReviewProvider(targetId));

    // Someone else's approved review of the same teacher is already in the list
    // below; don't print mine twice.
    final others = reviews.where((r) => r.id != mine?.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mine != null) ...[
          _MyReview(review: mine, targetId: targetId, targetName: targetName),
          const SizedBox(height: 12),
        ] else if (canReview) ...[
          OutlinedButton.icon(
            onPressed: () => _write(context, ref, null),
            icon: const Icon(Icons.rate_review_outlined, size: 18),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.skyDeeper,
              side: const BorderSide(color: AppColors.skyLight),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            label: Text(l10n.writeReview),
          ),
          const SizedBox(height: 12),
        ],
        if (others.isEmpty && mine == null)
          Text(l10n.noReviewsYet,
              style: const TextStyle(color: AppColors.text3))
        else
          ...others.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReviewTile(review: r),
              )),
      ],
    );
  }

  Future<void> _write(BuildContext context, WidgetRef ref, Review? existing) async {
    final l10n = context.l10n;
    final done = await showReviewSheet(
      context,
      targetId: targetId,
      targetName: targetName,
      existing: existing,
    );
    if (!done || !context.mounted) return;
    // It will not show up on the profile yet — say so, or it looks broken.
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.reviewSubmitted)));
  }
}

/// My own review, in whatever state — including the ones nobody else can see.
class _MyReview extends ConsumerWidget {
  const _MyReview({
    required this.review,
    required this.targetId,
    required this.targetName,
  });

  final Review review;
  final String targetId;
  final String targetName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final (String note, Color colour) = switch (review.status) {
      ReviewStatus.pending => (l10n.reviewPendingNote, AppColors.text2),
      ReviewStatus.rejected => (
          review.rejectionReason.isEmpty
              ? l10n.reviewRejectedNote
              : l10n.reviewRejectedNoteWithReason(review.rejectionReason),
          AppColors.error
        ),
      ReviewStatus.approved => (l10n.reviewPublishedNote, AppColors.text3),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.skyLight.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l10n.yourReviewLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.text)),
              const SizedBox(width: 8),
              StarRating(rating: review.rating.toDouble(), size: 14),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final done = await showReviewSheet(
                    context,
                    targetId: targetId,
                    targetName: targetName,
                    existing: review,
                  );
                  if (!done || !context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.reviewSubmitted)));
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l10n.editReview),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.comment,
                style: const TextStyle(
                    fontSize: 13.5, color: AppColors.text2, height: 1.45)),
          ],
          const SizedBox(height: 6),
          Text(note, style: TextStyle(fontSize: 12, color: colour)),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipOval(
          child: SizedBox(
            width: 36,
            height: 36,
            child: AvatarImage(url: review.reviewerPhoto, iconSize: 18),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      review.reviewerName.isEmpty
                          ? context.l10n.unknownUser
                          : review.reviewerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: AppColors.text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StarRating(rating: review.rating.toDouble(), size: 13),
                ],
              ),
              if (review.comment.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(review.comment,
                    style: const TextStyle(
                        fontSize: 13.5, color: AppColors.text2, height: 1.45)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
