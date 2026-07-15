import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_refs.dart';
import '../models/chat_models.dart';

/// Matches and their message threads.
///
/// Reads are direct Firestore streams (real-time is the point of chat). Writes
/// that must not be forgeable — the match doc's last message, the unread badge —
/// go through Cloud Functions; see `onNewMessage` and `markMatchRead`.
class MatchesRepository {
  const MatchesRepository();

  String get _uid {
    final uid = Fb.auth.currentUser?.uid;
    if (uid == null) throw StateError('No signed-in user.');
    return uid;
  }

  /// My matches, most recently active first.
  ///
  /// A blocked match is dropped: the thread is gone for both sides. Leaving it
  /// in the list is a scar the user should not have to keep looking at, and the
  /// rules deny sending to it anyway.
  Stream<List<MatchThread>> watchMatches() {
    final uid = _uid;
    return Fb.db
        .collection('matches')
        .where('participants', arrayContains: uid)
        .orderBy('last_message_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .where((d) => d.data()['blocked'] != true)
            .map((d) => MatchThread.fromDoc(d, uid))
            .whereType<MatchThread>()
            .toList());
  }

  /// The thread, oldest → newest.
  Stream<List<ChatMessage>> watchMessages(String matchId) {
    return Fb.db
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .orderBy('created_at')
        .limitToLast(200)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());
  }

  Future<void> sendMessage({
    required String matchId,
    required String text,
  }) async {
    final body = text.trim();
    if (body.isEmpty) return;
    await Fb.db
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .add({
      'sender_id': _uid,
      'text': body,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Clears my unread badge for this match.
  Future<void> markRead(String matchId) async {
    try {
      await Fb.functions
          .httpsCallable('markMatchRead')
          .call<Object?>({'matchId': matchId});
    } catch (_) {
      // A failed badge reset is not worth interrupting the user for.
    }
  }
}

final matchesRepositoryProvider = Provider<MatchesRepository>((ref) {
  return const MatchesRepository();
});

/// The signed-in user's matches, live.
final matchesProvider = StreamProvider<List<MatchThread>>((ref) {
  return ref.watch(matchesRepositoryProvider).watchMatches();
});

/// One thread's messages, live.
final messagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, matchId) {
  return ref.watch(matchesRepositoryProvider).watchMessages(matchId);
});
