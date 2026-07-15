import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_refs.dart';

/// Why a user is being reported. A fixed list, not free text — it makes reports
/// triageable, and it tells the reporter what this is actually for.
enum ReportReason {
  harassment('harassment'),
  inappropriateContent('inappropriate_content'),
  spam('spam'),
  fakeProfile('fake_profile'),
  underage('underage'),
  safetyConcern('safety_concern'),
  other('other');

  const ReportReason(this.code);
  final String code;
}

/// Reporting and blocking.
///
/// Required by App Store Guideline 1.2 (user-generated content): users must be
/// able to flag objectionable content and block abusive users, and reports must
/// be acted on within 24 hours. Google Play requires the equivalent.
class SafetyRepository {
  const SafetyRepository();

  String get _uid {
    final uid = Fb.auth.currentUser?.uid;
    if (uid == null) throw StateError('No signed-in user.');
    return uid;
  }

  /// Reports go straight to every admin. Returns true if this is a new report.
  Future<bool> report({
    required String reportedId,
    required ReportReason reason,
    String details = '',
  }) async {
    final res = await Fb.functions.httpsCallable('reportUser').call({
      'reportedId': reportedId,
      'reason': reason.code,
      'details': details,
    });
    return (res.data as Map)['alreadyReported'] != true;
  }

  /// Blocking is immediate and symmetric — neither party sees the other in
  /// discovery, neither can message, and any existing chat disappears.
  Future<void> setBlocked(String targetId, {required bool blocked}) async {
    await Fb.functions.httpsCallable('blockUser').call<Object?>({
      'targetId': targetId,
      'blocked': blocked,
    });
  }

  /// Who I have blocked. (Not who has blocked me — telling someone they've been
  /// blocked, and by whom, hands a harasser exactly the information they want.)
  Stream<Set<String>> watchMyBlocks() {
    return Fb.db
        .collection('blocks')
        .doc(_uid)
        .collection('blocked')
        .snapshots()
        .map((s) => s.docs.map((d) => d.id).toSet());
  }
}

final safetyRepositoryProvider =
    Provider<SafetyRepository>((ref) => const SafetyRepository());

final myBlocksProvider = StreamProvider<Set<String>>((ref) {
  return ref.watch(safetyRepositoryProvider).watchMyBlocks();
});
