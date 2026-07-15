import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_refs.dart';
import '../../../core/money/currency.dart';
import '../models/student_card_model.dart';
import '../models/teacher_card_model.dart';

/// One bucket of the free right-swipe budget.
class QuotaBucket {
  const QuotaBucket({
    required this.used,
    required this.limit,
    required this.remaining,
  });

  final int used;
  final int limit;
  final int remaining;

  static QuotaBucket fromMap(Map? m) => QuotaBucket(
        used: (m?['used'] as num?)?.toInt() ?? 0,
        limit: (m?['limit'] as num?)?.toInt() ?? 0,
        remaining: (m?['remaining'] as num?)?.toInt() ?? 0,
      );
}

/// The signed-in user's remaining right-swipes for the current 24h window.
class SwipeQuota {
  const SwipeQuota({
    required this.unlimited,
    required this.primary,
    required this.discovery,
  });

  final bool unlimited;
  final QuotaBucket primary;
  final QuotaBucket discovery;

  /// What the banner shows: the total still available across both budgets.
  int get remaining => primary.remaining + discovery.remaining;
  bool get exhausted => !unlimited && remaining <= 0;

  static const empty = SwipeQuota(
    unlimited: false,
    primary: QuotaBucket(used: 0, limit: 0, remaining: 0),
    discovery: QuotaBucket(used: 0, limit: 0, remaining: 0),
  );
}

/// The outcome of a swipe — `matched` is what triggers the match overlay.
class SwipeResult {
  const SwipeResult({required this.matched, required this.matchId});

  final bool matched;
  final String? matchId;
}

/// Talks to the discovery Cloud Functions. All the rules — who is visible, how
/// far, quota, what counts as a match — live server-side; this just calls them.
class DiscoverRepository {
  const DiscoverRepository();

  /// The raw candidate batch. Who you get back is decided server-side from your
  /// own role — a Student receives Teachers, a Teacher receives Students.
  Future<List<Map>> _candidates({
    double? radiusKm,
    bool includePassed = false,
  }) async {
    final res = await Fb.functions.httpsCallable('getCandidates').call({
      'radiusKm': ?radiusKm,
      // Re-shows people you PASSED. Never people you liked — that like is
      // already pending, and showing them again would let you like them twice.
      'includePassed': includePassed,
    });
    final list = (res.data as Map)['candidates'] as List? ?? const [];
    return list.cast<Map>();
  }

  Future<List<TeacherCardModel>> getTeacherCandidates({
    double? radiusKm,
    bool includePassed = false,
  }) async {
    final raw = await _candidates(radiusKm: radiusKm, includePassed: includePassed);
    return raw.map(_teacherCardFrom).toList();
  }

  Future<List<StudentCardModel>> getStudentCandidates({
    double? radiusKm,
    bool includePassed = false,
  }) async {
    final raw = await _candidates(radiusKm: radiusKm, includePassed: includePassed);
    return raw.map(_studentCardFrom).toList();
  }

  StudentCardModel _studentCardFrom(Map m) {
    return StudentCardModel(
      uid: (m['uid'] ?? '') as String,
      name: (m['displayName'] ?? '') as String,
      avatarUrl: (m['photoUrl'] ?? '') as String,
      subjects: ((m['subjects'] as List?) ?? const []).map((e) => '$e').toList(),
      distanceKm: ((m['distanceKm'] as num?) ?? 0).toDouble(),
      bio: (m['about'] ?? '') as String,
    );
  }

  Future<SwipeResult> recordSwipe({
    required String targetId,
    required bool liked,
  }) async {
    final res = await Fb.functions.httpsCallable('recordSwipe').call({
      'targetId': targetId,
      'liked': liked,
    });
    final m = res.data as Map;
    return SwipeResult(
      matched: m['matched'] == true,
      matchId: m['matchId'] as String?,
    );
  }

  Future<SwipeQuota> getQuota() async {
    final res = await Fb.functions.httpsCallable('getSwipeQuota').call();
    final m = res.data as Map;
    return SwipeQuota(
      unlimited: m['unlimited'] == true,
      primary: QuotaBucket.fromMap(m['primary'] as Map?),
      discovery: QuotaBucket.fromMap(m['discovery'] as Map?),
    );
  }

  TeacherCardModel _teacherCardFrom(Map m) {
    return TeacherCardModel(
      uid: (m['uid'] ?? '') as String,
      name: (m['displayName'] ?? '') as String,
      avatarUrl: (m['photoUrl'] ?? '') as String,
      subjects: ((m['subjects'] as List?) ?? const []).map((e) => '$e').toList(),
      distanceKm: ((m['distanceKm'] as num?) ?? 0).toDouble(),
      rating: ((m['avgRating'] as num?) ?? 0).toDouble(),
      reviewCount: ((m['totalReviews'] as num?) ?? 0).toInt(),
      // Years of experience is not on the profile schema yet; the card shows 0
      // rather than inventing a number.
      experienceYears: 0,
      bio: (m['about'] ?? '') as String,
      verifiedStatus: switch (m['verifiedStatus']) {
        'approved' => VerifiedStatus.verified,
        'pending' => VerifiedStatus.pending,
        _ => VerifiedStatus.unverified,
      },
      isFeatured: m['featured'] == true,
      hourlyRate: m['hourlyRate'] as num?,
      currency: Currency.fromCode(m['currency'] as String?),
    );
  }
}

final discoverRepositoryProvider = Provider<DiscoverRepository>((ref) {
  return const DiscoverRepository();
});
