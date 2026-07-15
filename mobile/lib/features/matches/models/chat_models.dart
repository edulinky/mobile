import 'package:cloud_firestore/cloud_firestore.dart';

/// A mutual match — the consent record that unlocks a chat thread.
class MatchThread {
  const MatchThread({
    required this.matchId,
    required this.otherUid,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unread,
    required this.createdAt,
  });

  final String matchId;
  final String otherUid;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unread;
  final DateTime? createdAt;

  /// A match nobody has written in yet — shown as a "new match", not a thread.
  bool get hasMessages => lastMessageAt != null;

  static MatchThread? fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String myUid,
  ) {
    final d = doc.data();
    if (d == null) return null;
    final participants =
        ((d['participants'] as List?) ?? const []).map((e) => '$e').toList();
    final other = participants.where((p) => p != myUid).firstOrNull;
    if (other == null) return null;

    final unread = (d['unread'] as Map?)?.cast<String, dynamic>();
    return MatchThread(
      matchId: doc.id,
      otherUid: other,
      lastMessage: (d['last_message'] as String?) ?? '',
      lastMessageAt: (d['last_message_at'] as Timestamp?)?.toDate(),
      unread: ((unread?[myUid] as num?) ?? 0).toInt(),
      createdAt: (d['created_at'] as Timestamp?)?.toDate(),
    );
  }
}

/// One message in a thread.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
  });

  final String id;
  final String senderId;
  final String text;

  /// Null while the write is still in flight (Firestore fills the server
  /// timestamp on ack) — the message is already shown from the local cache.
  final DateTime? sentAt;

  bool isMine(String myUid) => senderId == myUid;

  static ChatMessage fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return ChatMessage(
      id: doc.id,
      senderId: (d['sender_id'] as String?) ?? '',
      text: (d['text'] as String?) ?? '',
      sentAt: (d['created_at'] as Timestamp?)?.toDate(),
    );
  }
}
