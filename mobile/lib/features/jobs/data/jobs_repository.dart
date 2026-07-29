import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_refs.dart';
import '../models/job_card.dart';

/// Job Cards: institutions post them, teachers swipe them.
///
/// Reads are direct Firestore (an institution's own cards, its applications).
/// Every WRITE goes through a callable — the geohash must be derived from the
/// institution's verified city, and `inst_id`/`status`/`applicant_count` must not
/// be forgeable.
class JobsRepository {
  const JobsRepository();

  String get _uid {
    final uid = Fb.auth.currentUser?.uid;
    if (uid == null) throw StateError('No signed-in user.');
    return uid;
  }

  // ── Institution ──────────────────────────────────────────────

  Stream<List<JobCard>> watchMyJobCards() {
    return Fb.db
        .collection('jobCards')
        .where('inst_id', isEqualTo: _uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((s) => s.docs.map(JobCard.fromDoc).toList());
  }

  /// Applications this institution has received, newest first.
  Stream<List<JobApplication>> watchApplications({String? jobId}) {
    var q = Fb.db.collection('applications').where('inst_id', isEqualTo: _uid);
    if (jobId != null) q = q.where('job_id', isEqualTo: jobId);
    return q
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((s) => s.docs.map(JobApplication.fromDoc).toList());
  }

  Future<String> upsertJobCard({
    String? jobId,
    required String title,
    required String subject,
    required String level,
    required String description,
    required ContractType contractType,
    num? salaryMin,
    num? salaryMax,
    SalaryPeriod salaryPeriod = SalaryPeriod.month,
    DateTime? startAt,
    String videoUrl = '',
    bool draft = false,
  }) async {
    final res = await Fb.functions.httpsCallable('upsertJobCard').call({
      'jobId': ?jobId,
      'title': title,
      'subject': subject,
      'level': level,
      'description': description,
      'contractType': contractType.code,
      'salaryMin': ?salaryMin,
      'salaryMax': ?salaryMax,
      'salaryPeriod': salaryPeriod.code,
      'startAtMs': ?startAt?.millisecondsSinceEpoch,
      'videoUrl': videoUrl,
      'status': draft ? 'draft' : 'active',
    });
    return ((res.data as Map)['jobId'] ?? '') as String;
  }

  /// `status` is one of: draft, active, closed.
  Future<void> setStatus(String jobId, String status) async {
    await Fb.functions
        .httpsCallable('setJobCardStatus')
        .call<Object?>({'jobId': jobId, 'status': status});
  }

  // ── Teacher ──────────────────────────────────────────────────

  /// The jobs THIS teacher has applied to, newest first. Rules allow a teacher
  /// to read applications where `teacher_id` is their own uid, so this is a
  /// direct query — no callable needed.
  Stream<List<JobApplication>> watchMyApplications() {
    return Fb.db
        .collection('applications')
        .where('teacher_id', isEqualTo: _uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((s) => s.docs.map(JobApplication.fromDoc).toList());
  }

  Future<List<JobCard>> getJobCards({double? radiusKm}) async {
    final res = await Fb.functions.httpsCallable('getJobCards').call({
      'radiusKm': ?radiusKm,
    });
    final list = (res.data as Map)['jobCards'] as List? ?? const [];
    return list.map((e) => JobCard.fromMap(e as Map)).toList();
  }

  /// Right-swipe on a job card. One-directional: the institution is notified
  /// immediately; there is no mutual swipe and no match.
  Future<void> applyToJob(String jobId) async {
    await Fb.functions
        .httpsCallable('applyToJob')
        .call<Object?>({'jobId': jobId});
  }
}

final jobsRepositoryProvider =
    Provider<JobsRepository>((ref) => const JobsRepository());

final myJobCardsProvider = StreamProvider<List<JobCard>>((ref) {
  return ref.watch(jobsRepositoryProvider).watchMyJobCards();
});

final myApplicationsProvider = StreamProvider<List<JobApplication>>((ref) {
  return ref.watch(jobsRepositoryProvider).watchApplications();
});

/// The applications a teacher has SENT (jobs they applied to).
final teacherApplicationsProvider =
    StreamProvider<List<JobApplication>>((ref) {
  return ref.watch(jobsRepositoryProvider).watchMyApplications();
});

/// The teacher's Job Cards deck.
final jobDeckProvider = FutureProvider<List<JobCard>>((ref) {
  return ref.watch(jobsRepositoryProvider).getJobCards();
});
