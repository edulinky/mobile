import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/firebase/firebase_refs.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_image.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../matches/data/matches_repository.dart';
import '../../safety/widgets/safety_menu.dart';
import '../../matches/models/chat_models.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherName,
    required this.otherAvatarUrl,
    required this.otherUid,
  });

  final String matchId;
  final String otherName;
  final String otherAvatarUrl;
  final String otherUid;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Opening the thread clears my unread badge.
    ref.read(matchesRepositoryProvider).markRead(widget.matchId);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    final l10n = context.l10n;

    // Clear the field immediately — Firestore echoes the message back from its
    // local cache before the server acks, so the bubble appears at once.
    _ctrl.clear();
    setState(() => _sending = true);
    try {
      await ref
          .read(matchesRepositoryProvider)
          .sendMessage(matchId: widget.matchId, text: text);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      _ctrl.text = text; // don't lose what they typed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errSendMessage('$e'))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTimestamp(DateTime? at) {
    // Null until the server stamps it; the bubble is already on screen from the
    // local cache, so show nothing rather than a wrong time.
    if (at == null) return '';
    final t = at;
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inDays == 0) return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 1) return 'Yesterday';
    return '${t.day}/${t.month}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.skyBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // The header is the way back to the other person's profile. Once you have
        // matched, the chat is the only place they appear — without this there is
        // no route to their profile at all, and so no way to review a teacher you
        // are actually learning from.
        title: InkWell(
          onTap: () => context.push('/profile/${widget.otherUid}'),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: AvatarImage(url: widget.otherAvatarUrl, iconSize: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(widget.otherName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.text3),
              ],
            ),
          ),
        ),
        actions: [
          SafetyMenu(
            targetUid: widget.otherUid,
            targetName: widget.otherName,
            // Blocking removes the thread, so there is nothing left to look at.
            onBlocked: () => Navigator.of(context).pop(),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(height: 0.5, color: AppColors.skyLight),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ref.watch(messagesProvider(widget.matchId)).when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(l10n.errLoadMessages('$e'),
                          textAlign: TextAlign.center),
                    ),
                  ),
                  data: (messages) {
                    if (messages.isEmpty) return _buildEmptyThread(l10n);
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _scrollToBottom());
                    final myUid = Fb.auth.currentUser?.uid ?? '';
                    return ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (_, i) {
                        final msg = messages[i];
                        final isMe = msg.isMine(myUid);
                        final showTime = i == 0 ||
                            messages[i - 1].senderId != msg.senderId;
                        return _buildBubble(msg, isMe, showTime);
                      },
                    );
                  },
                ),
          ),
          _buildInputBar(context, l10n),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg, bool isMe, bool showTime) {
    return Padding(
      padding: EdgeInsets.only(
        top: showTime ? 12 : 3,
        bottom: 3,
        left: isMe ? 60 : 0,
        right: isMe ? 0 : 60,
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showTime)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                _formatTimestamp(msg.sentAt),
                style: const TextStyle(fontSize: 11, color: AppColors.text3),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AppColors.skyDark : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)],
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                  color: isMe ? Colors.white : AppColors.text, fontSize: 14.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyThread(dynamic l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined, size: 56, color: AppColors.text3),
            const SizedBox(height: 12),
            Text(l10n.chatEmpty,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.text2)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, dynamic l10n) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.skyLight, width: 0.8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: l10n.chatInputHint,
                hintStyle: const TextStyle(color: AppColors.text3),
                filled: true,
                fillColor: AppColors.skyBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.skyLight),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: AppColors.skyDark, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
