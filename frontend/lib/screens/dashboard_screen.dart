import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/goal.dart';
import '../providers/goals_provider.dart';
import '../providers/repository_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/goal_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              onAdd: () async {
                await context.push('/goal/new');
                ref.invalidate(goalsProvider);
              },
            ),
            const Divider(),
            Expanded(
              child: goalsAsync.when(
                loading: () => const _LoadingState(),
                error: (e, _) => _ErrorState(message: e.toString()),
                data: (goals) => goals.isEmpty
                    ? const _EmptyState()
                    : _GoalList(goals: goals),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onAdd;

  const _Header({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NO,', style: AppTheme.display),
                Text(
                  'YOU ARE NOT.',
                  style: AppTheme.display.copyWith(color: AppTheme.accent),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/tutorial'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.help_outline,
                color: AppTheme.textSecondary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push('/settings'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: AppTheme.textSecondary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.add,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Goal List ────────────────────────────────────────────────────────────────

class _GoalList extends ConsumerWidget {
  final List<Goal> goals;

  const _GoalList({required this.goals});

  Future<void> _startSession(
      BuildContext context, WidgetRef ref, Goal goal) async {
    try {
      final conv = await ref.read(conversationRepositoryProvider).createConversation(
            goalId: goal.id,
            title: goal.content,
          );
      if (context.mounted) {
        context.push(
          '/chat/${conv.id}?goal=${Uri.encodeComponent(goal.content)}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, Goal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDialog(goalContent: goal.content),
    );
    if (confirmed == true) {
      ref.read(goalsProvider.notifier).deleteGoal(goal.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: goals.length,
      separatorBuilder: (_, index) => const SizedBox(height: 16),
      itemBuilder: (context, i) => GoalCard(
        goal: goals[i],
        index: i + 1,
        onStart: () => _startSession(context, ref, goals[i]),
        onDelete: () => _delete(context, ref, goals[i]),
      ),
    );
  }
}

// ── States ───────────────────────────────────────────────────────────────────

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
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'CONNECTION\nFAILED.',
          style: AppTheme.heading,
          textAlign: TextAlign.center,
        ),
      ),
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
          Text('NO ACTIVE\nMISSIONS.', style: AppTheme.display),
          const SizedBox(height: 16),
          Text(
            "You have no goal to avoid.\nThat's convenient, isn't it?",
            style: AppTheme.caption,
          ),
        ],
      ),
    );
  }
}

// ── Delete Dialog ─────────────────────────────────────────────────────────────

class _DeleteDialog extends StatelessWidget {
  final String goalContent;

  const _DeleteDialog({required this.goalContent});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ABANDON\nMISSION?', style: AppTheme.heading),
            const SizedBox(height: 12),
            Text('"$goalContent"', style: AppTheme.caption),
            const SizedBox(height: 6),
            Text(
              'This cannot be undone.',
              style: AppTheme.caption.copyWith(color: AppTheme.accent),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'CANCEL',
                      style: GoogleFonts.bebasNeue(letterSpacing: 2),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      'ABANDON',
                      style: GoogleFonts.bebasNeue(letterSpacing: 2),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
