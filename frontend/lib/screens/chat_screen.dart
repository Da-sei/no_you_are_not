import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/message.dart';
import '../providers/conversations_provider.dart';
import '../providers/repository_providers.dart';
import '../repositories/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/message_bubble.dart';
import '../widgets/paywall_sheet.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final int conversationId;
  final String goalContent;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.goalContent,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _messages = <Message>[];
  bool _loading = false;
  bool _thinking = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    try {
      final msgs = await ref
          .read(messageRepositoryProvider)
          .getMessages(widget.conversationId);
      setState(() {
        _messages
          ..clear()
          ..addAll(msgs);
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _thinking) return;
    _inputCtrl.clear();

    // ユーザーメッセージを即時表示（楽観的更新）
    final optimistic = Message(
      id: -DateTime.now().millisecondsSinceEpoch,
      conversationId: widget.conversationId,
      role: MessageRole.user,
      content: text,
      createdAt: DateTime.now(),
    );
    setState(() {
      _messages.add(optimistic);
      _thinking = true;
    });
    _scrollToBottom();

    try {
      final aiMsg = await ref
          .read(messageRepositoryProvider)
          .sendMessage(widget.conversationId, text);
      setState(() => _messages.add(aiMsg));
      _scrollToBottom();
    } on LimitException catch (e) {
      setState(() => _messages.remove(optimistic));
      if (mounted) await PaywallSheet.show(context, e);
    } catch (e) {
      setState(() => _messages.remove(optimistic));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _thinking = false);
    }
  }

  Future<void> _archive() async {
    try {
      await ref
          .read(conversationRepositoryProvider)
          .archiveConversation(widget.conversationId);
      // アーカイブ一覧を再取得させる
      ref.invalidate(archivedConversationsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('INTERROGATION'),
            if (widget.goalContent.isNotEmpty)
              Text(
                widget.goalContent,
                style: AppTheme.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _archive,
            child: Text(
              'ARCHIVE',
              style: GoogleFonts.bebasNeue(
                fontSize: 13,
                color: AppTheme.accent,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _InputBar(
            controller: _inputCtrl,
            onSend: _send,
            disabled: _thinking,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.accent,
          strokeWidth: 1.5,
        ),
      );
    }

    if (_messages.isEmpty && !_thinking) {
      return _EmptySession(goalContent: widget.goalContent);
    }

    final itemCount = _messages.length + (_thinking ? 1 : 0);

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: itemCount,
      itemBuilder: (context, i) {
        if (_thinking && i == _messages.length) {
          return const TypingIndicator();
        }
        return MessageBubble(message: _messages[i]);
      },
    );
  }
}

// ── Empty Session ─────────────────────────────────────────────────────────────

class _EmptySession extends StatelessWidget {
  final String goalContent;

  const _EmptySession({required this.goalContent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SESSION\nINITIATED.',
            style: AppTheme.heading.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 12),
          Text(
            "State your excuse.\nI'm waiting.",
            style: AppTheme.caption,
          ),
        ],
      ),
    );
  }
}

// ── Input Bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool disabled;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 12,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '>',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 16,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !disabled,
              style: AppTheme.body,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: disabled ? null : (_) => onSend(),
              decoration: InputDecoration(
                hintText: disabled ? 'ANALYZING...' : 'State your excuse.',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: disabled ? null : onSend,
            child: Container(
              width: 40,
              height: 40,
              color: disabled ? AppTheme.border : AppTheme.accent,
              child: const Icon(Icons.send, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
