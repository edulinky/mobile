import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/discover_repository.dart';
import '../models/student_card_model.dart';
import '../models/teacher_card_model.dart';

/// Fetches a batch of candidates.
typedef Fetch<T> = Future<List<T>> Function({
  double? radiusKm,
  bool includePassed,
});

@immutable
class SwipeState<T> {
  const SwipeState({
    this.cards = const [],
    this.quota = SwipeQuota.empty,
    this.loading = true,
    this.error,
    this.matchedWith,
    this.matchId,
    this.radiusKm = 50,
    this.canSearchWider = true,
  });

  final List<T> cards;
  final SwipeQuota quota;
  final bool loading;
  final String? error;

  /// Current search radius, shown in the empty state.
  final double radiusKm;
  final bool canSearchWider;

  /// Set when a swipe completed a mutual like — drives the match overlay.
  final T? matchedWith;
  final String? matchId;

  SwipeState<T> copyWith({
    List<T>? cards,
    SwipeQuota? quota,
    bool? loading,
    String? error,
    bool clearError = false,
    T? matchedWith,
    String? matchId,
    bool clearMatch = false,
    double? radiusKm,
    bool? canSearchWider,
  }) {
    return SwipeState<T>(
      cards: cards ?? this.cards,
      quota: quota ?? this.quota,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      matchedWith: clearMatch ? null : (matchedWith ?? this.matchedWith),
      matchId: clearMatch ? null : (matchId ?? this.matchId),
      radiusKm: radiusKm ?? this.radiusKm,
      canSearchWider: canSearchWider ?? this.canSearchWider,
    );
  }
}

/// Owns a swipe deck: prefetching, optimistic removal, quota, match overlay.
///
/// Generic over the card type because the engine is identical for both decks —
/// the server decides *who* you see from your own role, so a Student swiping
/// Teachers and a Teacher swiping Students run the exact same logic.
class SwipeController<T> extends StateNotifier<SwipeState<T>> {
  SwipeController({
    required DiscoverRepository repo,
    required Fetch<T> fetch,
    required String Function(T) uidOf,
  })  : _repo = repo,
        _fetch = fetch,
        _uidOf = uidOf,
        super(SwipeState<T>()) {
    load();
  }

  final DiscoverRepository _repo;
  final Fetch<T> _fetch;
  final String Function(T) _uidOf;

  /// How far discovery looks. Widened by "Search wider" when the deck runs dry —
  /// in a small market, "nobody within 50 km" is the likeliest reason it did.
  static const _radiusSteps = <double>[50, 100, 200, 500];
  int _radiusStep = 0;

  double get radiusKm => _radiusSteps[_radiusStep];
  bool get canSearchWider => _radiusStep < _radiusSteps.length - 1;

  /// Refetch in the background once the deck runs this low.
  static const _refetchThreshold = 3;
  bool _fetching = false;

  /// Swiped this session. The server excludes these too, but a prefetch that
  /// overlaps an in-flight swipe could still see stale data — and a card coming
  /// back after you swiped it is the worst bug in a swipe deck.
  final Set<String> _swiped = {};

  Future<void> load({bool includePassed = false}) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final cards = await _fetch(
        radiusKm: radiusKm,
        includePassed: includePassed,
      );
      final quota = await _repo.getQuota();
      // A refresh that re-shows passes must forget that we swiped them, or the
      // local guard below would filter them straight back out.
      if (includePassed) _swiped.clear();
      state = state.copyWith(
        cards: cards,
        quota: quota,
        loading: false,
        radiusKm: radiusKm,
        canSearchWider: canSearchWider,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
    }
  }

  /// "Refresh" at the end of the deck: re-fetch, and bring back everyone the
  /// user PASSED. People they LIKED stay gone — that like is already pending, or
  /// is a match.
  Future<void> refresh() => load(includePassed: true);

  /// Widen the search radius one step and reload.
  Future<void> searchWider() async {
    if (!canSearchWider) return;
    _radiusStep++;
    await load(includePassed: true);
  }

  /// Tops the deck up without a spinner — the user keeps swiping meanwhile.
  Future<void> _prefetch() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final more = await _fetch(radiusKm: radiusKm);
      final known = state.cards.map(_uidOf).toSet()..addAll(_swiped);
      final fresh = more.where((c) => !known.contains(_uidOf(c))).toList();
      if (fresh.isNotEmpty) {
        state = state.copyWith(cards: [...state.cards, ...fresh]);
      }
    } catch (_) {
      // A failed top-up is not worth interrupting the user for; the next swipe
      // tries again.
    } finally {
      _fetching = false;
    }
  }

  /// Optimistic: the card leaves immediately and the server call runs after. If
  /// the server rejects it (quota exhausted) the card goes back — the user must
  /// not lose a profile they never actually spent a swipe on.
  Future<void> swipe(T card, {required bool liked}) async {
    final previous = state.cards;
    final uid = _uidOf(card);
    _swiped.add(uid);
    state = state.copyWith(
      cards: previous.where((c) => _uidOf(c) != uid).toList(),
    );

    try {
      final result = await _repo.recordSwipe(targetId: uid, liked: liked);
      if (result.matched) {
        state = state.copyWith(matchedWith: card, matchId: result.matchId);
      }
    } catch (e) {
      // The swipe did not happen — put the card back and let them retry.
      _swiped.remove(uid);
      state = state.copyWith(cards: previous, error: '$e');
      return;
    }

    // Top up only AFTER the server has recorded the swipe. Prefetching
    // concurrently raced it: getCandidates would run before the swipe existed,
    // not know to exclude this person, and hand them back — so the card the user
    // just swiped reappeared, and they swiped it again.
    if (state.cards.length <= _refetchThreshold) {
      unawaited(_prefetch());
    }

    if (liked) {
      // The quota moved; re-read it rather than guessing which bucket was hit.
      try {
        state = state.copyWith(quota: await _repo.getQuota());
      } catch (_) {
        /* banner just stays stale */
      }
    }
  }

  /// Pull someone out of the deck now — used when they are blocked. The server
  /// already excludes them from the next fetch, but the card they are looking at
  /// is in memory, and leaving a blocked person on screen is exactly the thing
  /// blocking is supposed to prevent.
  void removeCard(String uid) {
    _swiped.add(uid); // never re-added by a prefetch
    state = state.copyWith(
      cards: state.cards.where((c) => _uidOf(c) != uid).toList(),
    );
  }

  void dismissMatch() => state = state.copyWith(clearMatch: true);
  void clearError() => state = state.copyWith(clearError: true);
}

/// Student's deck — teachers.
final teacherDeckProvider = StateNotifierProvider<SwipeController<TeacherCardModel>,
    SwipeState<TeacherCardModel>>((ref) {
  final repo = ref.watch(discoverRepositoryProvider);
  return SwipeController<TeacherCardModel>(
    repo: repo,
    fetch: repo.getTeacherCandidates,
    uidOf: (c) => c.uid,
  );
});

/// Teacher's deck — students.
final studentDeckProvider = StateNotifierProvider<SwipeController<StudentCardModel>,
    SwipeState<StudentCardModel>>((ref) {
  final repo = ref.watch(discoverRepositoryProvider);
  return SwipeController<StudentCardModel>(
    repo: repo,
    fetch: repo.getStudentCandidates,
    uidOf: (c) => c.uid,
  );
});
