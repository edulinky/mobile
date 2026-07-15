import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_refs.dart';
import '../../matches/data/matches_repository.dart';
import '../models/review.dart';

/// Reviews of a teacher.
///
/// Submission goes through a callable: the server checks the reviewer actually
/// matched with the teacher, and holds the review as `pending` until an admin
/// publishes it. Reads are direct Firestore queries — the rules only ever hand
/// back approved reviews (plus your own, whatever its state).
class ReviewsRepository {
  const ReviewsRepository();

  String get _uid {
    final uid = Fb.auth.currentUser?.uid;
    if (uid == null) throw StateError('No signed-in user.');
    return uid;
  }

  Future<void> submit({
    required String targetId,
    required int rating,
    String comment = '',
  }) async {
    await Fb.functions.httpsCallable('submitReview').call<Object?>({
      'targetId': targetId,
      'rating': rating,
      'comment': comment,
    });
  }

  /// The reviews shown on a teacher's public profile.
  ///
  /// The `status` filter is not decoration: the rules reject the whole query
  /// without it, because a list may only return documents the caller is allowed
  /// to read one by one.
  Stream<List<Review>> watchApproved(String targetId) {
    return Fb.db
        .collection('reviews')
        .where('target_id', isEqualTo: targetId)
        .where('status', isEqualTo: 'approved')
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(Review.fromDoc).toList());
  }

  /// My own review of this teacher, in whatever state — so the app can say
  /// "awaiting approval" or show why it was turned down, instead of appearing to
  /// have swallowed it.
  ///
  /// A **query**, not a `doc().get()` on the (deterministic) id. Two reasons, and
  /// both matter:
  ///  - the rules cannot evaluate a document that does not exist — `resource` is
  ///    null and `resource.data.reviewer_id` blows up — so fetching the id of a
  ///    review I have not written yet would come back `permission-denied` rather
  ///    than empty;
  ///  - and making the *absence* readable would leak: "denied" would mean a
  ///    pending review exists, "empty" would mean none does, and anyone could
  ///    probe who has reviewed whom.
  Stream<Review?> watchMine(String targetId) {
    return Fb.db
        .collection('reviews')
        .where('target_id', isEqualTo: targetId)
        .where('reviewer_id', isEqualTo: _uid)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty ? null : Review.fromDoc(s.docs.first));
  }
}

final reviewsRepositoryProvider =
    Provider<ReviewsRepository>((ref) => const ReviewsRepository());

final approvedReviewsProvider =
    StreamProvider.family<List<Review>, String>((ref, targetId) {
  return ref.watch(reviewsRepositoryProvider).watchApproved(targetId);
});

final myReviewProvider =
    StreamProvider.family<Review?, String>((ref, targetId) {
  return ref.watch(reviewsRepositoryProvider).watchMine(targetId);
});

/// Whether I may review this person: a match is the price of admission, and the
/// server enforces it too. This provider only decides whether to *show* the
/// button — an ineligible user who forced the call would be rejected anyway.
final canReviewProvider = Provider.family<bool, String>((ref, targetId) {
  return ref.watch(matchesProvider).maybeWhen(
        data: (matches) => matches.any((m) => m.otherUid == targetId),
        orElse: () => false,
      );
});
