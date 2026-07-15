class NewMatch {
  const NewMatch({
    required this.uid,
    required this.name,
    required this.avatarUrl,
    this.isOnline = false,
  });

  final String uid;
  final String name;
  final String avatarUrl;
  final bool isOnline;
}

final mockNewMatches = [
  NewMatch(uid: 'n1', name: 'Sarah',  avatarUrl: 'https://i.pravatar.cc/80?img=5',  isOnline: true),
  NewMatch(uid: 'n2', name: 'James',  avatarUrl: 'https://i.pravatar.cc/80?img=44', isOnline: false),
  NewMatch(uid: 'n3', name: 'Aisha',  avatarUrl: 'https://i.pravatar.cc/80?img=29', isOnline: false),
  NewMatch(uid: 'n4', name: 'Tom',    avatarUrl: 'https://i.pravatar.cc/80?img=12', isOnline: false),
];

class MatchModel {
  const MatchModel({
    required this.matchId,
    required this.otherUid,
    required this.otherName,
    required this.otherAvatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  final String matchId;
  final String otherUid;
  final String otherName;
  final String otherAvatarUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
}

class MessageModel {
  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
}

final mockMatches = [
  MatchModel(
    matchId: 'm1',
    otherUid: 't1',
    otherName: 'Sarah Johnson',
    otherAvatarUrl: 'https://i.pravatar.cc/300?img=47',
    lastMessage: 'Sure, I\'m free on Wednesday at 10am!',
    lastMessageTime: DateTime.now().subtract(const Duration(minutes: 12)),
    unreadCount: 2,
  ),
  MatchModel(
    matchId: 'm2',
    otherUid: 't2',
    otherName: 'Daniel Okonkwo',
    otherAvatarUrl: 'https://i.pravatar.cc/300?img=12',
    lastMessage: 'Let\'s start with essay structure next session.',
    lastMessageTime: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  MatchModel(
    matchId: 'm3',
    otherUid: 't4',
    otherName: 'James Adeola',
    otherAvatarUrl: 'https://i.pravatar.cc/300?img=68',
    lastMessage: 'I sent you the study notes.',
    lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

final mockMessages = [
  MessageModel(id: '1', senderId: 't1', text: 'Hi! I saw you\'re looking for a Maths teacher. I\'d love to help!', timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 30))),
  MessageModel(id: '2', senderId: 'me', text: 'Yes! I have final exams in 4 months and need help with calculus.', timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 15))),
  MessageModel(id: '3', senderId: 't1', text: 'Perfect. I specialise in calculus and have helped many students through their finals.', timestamp: DateTime.now().subtract(const Duration(hours: 2))),
  MessageModel(id: '4', senderId: 'me', text: 'That\'s great! What are your rates?', timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45))),
  MessageModel(id: '5', senderId: 't1', text: "\$25/hr for one-on-one sessions. I'm also flexible with timing.", timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30))),
  MessageModel(id: '6', senderId: 'me', text: 'That works for me. Can we start this week?', timestamp: DateTime.now().subtract(const Duration(minutes: 20))),
  MessageModel(id: '7', senderId: 't1', text: 'Sure, I\'m free on Wednesday at 10am!', timestamp: DateTime.now().subtract(const Duration(minutes: 12))),
];
