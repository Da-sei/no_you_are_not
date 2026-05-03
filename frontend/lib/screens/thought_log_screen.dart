import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/conversation.dart';
import '../providers/conversations_provider.dart';
import '../theme/app_theme.dart';

class ThoughtLogScreen extends ConsumerWidget {
  const ThoughtLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convsAsync = ref.watch(archivedConversationsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(),
            const Divider(),
            Expanded(
              child: convsAsync.when(
                loading: () => const _LoadingState(),
                error: (error, _) => const _ErrorState(),
                data: (convs) => convs.isEmpty
                    ? const _EmptyState()
                    : _ConversationList(conversations: convs),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ARCHIVE', style: AppTheme.display),
          Text(
            'DEFEATED EXCUSES',
            style: AppTheme.label.copyWith(letterSpacing: 4),
          ),
        ],
      ),
    );
  }
}

// ── Conversation List ─────────────────────────────────────────────────────────

class _ConversationList extends StatelessWidget {
  final List<Conversation> conversations;

  const _ConversationList({required this.conversations});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: conversations.length,
      separatorBuilder: (_, index) => const SizedBox(height: 1),
      itemBuilder: (context, i) => _ConversationTile(
        conversation: conversations[i],
        sessionNumber: conversations.length - i,
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final int sessionNumber;

  const _ConversationTile({
    required this.conversation,
    required this.sessionNumber,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('yyyy-MM-dd').format(conversation.createdAt.toLocal());

    return InkWell(
      onTap: () => context.push(
        '/chat/${conversation.id}'
        '?goal=${Uri.encodeComponent(conversation.title ?? '')}',
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SESSION ${sessionNumber.toString().padLeft(3, '0')}',
                    style: AppTheme.label,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.title ?? 'Untitled Session',
                    style: AppTheme.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(dateStr, style: AppTheme.caption),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.accent),
              ),
              child: Text(
                'ANNIHILATED',
                style: GoogleFonts.bebasNeue(
                  fontSize: 10,
                  color: AppTheme.accent,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── States ────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: AppTheme.accent,
          strokeWidth: 1.5,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('CONNECTION\nFAILED.', style: AppTheme.heading),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NO ARCHIVED\nSESSIONS.', style: AppTheme.display),
          const SizedBox(height: 16),
          Text(
            "Your excuses haven't been\nconfronted yet.",
            style: AppTheme.caption,
          ),
        ],
      ),
    );
  }
}
