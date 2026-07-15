import 'package:cloud_firestore/cloud_firestore.dart';

enum ReviewStatus {
  pending,
  approved,
  rejected;

  static ReviewStatus fromString(String? s) => switch (s) {
        'approved' => ReviewStatus.approved,
        'rejected' => ReviewStatus.rejected,
        _ => ReviewStatus.pending,
      };
}

/// One person's review of a teacher.
///
/// Only `approved` reviews are readable by anyone other than their author (and
/// admins) — see the `reviews` rule.
class Review {
  const Review({
    required this.id,
    required this.targetId,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerPhoto,
    required this.rating,
    required this.comment,
    required this.status,
    required this.rejectionReason,
    required this.createdAt,
  });

  final String id;
  final String targetId;
  final String reviewerId;
  final String reviewerName;
  final String reviewerPhoto;
  final int rating;
  final String comment;
  final ReviewStatus status;
  final String rejectionReason;
  final DateTime? createdAt;

  static Review fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return Review(
      id: doc.id,
      targetId: (d['target_id'] as String?) ?? '',
      reviewerId: (d['reviewer_id'] as String?) ?? '',
      reviewerName: (d['reviewer_name'] as String?) ?? '',
      reviewerPhoto: (d['reviewer_photo'] as String?) ?? '',
      rating: ((d['rating'] as num?) ?? 0).toInt(),
      comment: (d['comment'] as String?) ?? '',
      status: ReviewStatus.fromString(d['status'] as String?),
      rejectionReason: (d['rejection_reason'] as String?) ?? '',
      createdAt: (d['created_at'] as Timestamp?)?.toDate(),
    );
  }
}
