import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_refs.dart';

enum NotificationType {
  match,
  message,
  verificationApproved,
  verificationRejected,
  jobApplication,
  review,
  unknown;

  static NotificationType fromString(String? s) => switch (s) {
        'match' => NotificationType.match,
        'message' => NotificationType.message,
        'verification_approved' => NotificationType.verificationApproved,
        'verification_rejected' => NotificationType.verificationRejected,
        'job_application' => NotificationType.jobApplication,
        'review' => NotificationType.review,
        _ => NotificationType.unknown,
      };
}

/// One item in the activity feed.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, String> data;
  final bool read;
  final DateTime? createdAt;

  static AppNotification fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return AppNotification(
      id: doc.id,
      type: NotificationType.fromString(d['type'] as String?),
      title: (d['title'] as String?) ?? '',
      body: (d['body'] as String?) ?? '',
      data: ((d['data'] as Map?) ?? const {})
          .map((k, v) => MapEntry('$k', '$v')),
      read: d['read'] == true,
      createdAt: (d['created_at'] as Timestamp?)?.toDate(),
    );
  }
}

/// The in-app activity feed. Items are written **server-side only** — a client
/// that could write here could fabricate "you matched with X" or "you're
/// verified". The owner may only mark them read or dismiss them.
class NotificationsRepository {
  const NotificationsRepository();

  CollectionReference<Map<String, dynamic>> get _items {
    final uid = Fb.auth.currentUser?.uid;
    if (uid == null) throw StateError('No signed-in user.');
    return Fb.db.collection('notifications').doc(uid).collection('items');
  }

  Stream<List<AppNotification>> watch() {
    return _items
        .orderBy('created_at', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map(AppNotification.fromDoc).toList());
  }

  /// Marks everything read (clears the nav badge) when the inbox is opened.
  Future<void> markAllRead() async {
    try {
      await Fb.functions.httpsCallable('markNotificationsRead').call<Object?>();
    } catch (_) {
      // A failed badge reset is not worth interrupting the user for.
    }
  }

  Future<void> dismiss(String id) => _items.doc(id).delete();
}

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) => const NotificationsRepository());

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  return ref.watch(notificationsRepositoryProvider).watch();
});

/// Drives the badge on the Alerts tab.
final unreadNotificationsProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).maybeWhen(
        data: (items) => items.where((n) => !n.read).length,
        orElse: () => 0,
      );
});
