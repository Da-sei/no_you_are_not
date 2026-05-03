import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/goal.dart';
import '../theme/app_theme.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final int index;
  final VoidCallback onStart;
  final VoidCallback onDelete;

  const GoalCard({
    super.key,
    required this.goal,
    required this.index,
    required this.onStart,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = goal.deadline?.difference(DateTime.now()).inDays;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(left: BorderSide(color: AppTheme.accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Text(
                  'MISSION ${index.toString().padLeft(2, '0')}',
                  style: AppTheme.label,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(
                    Icons.close,
                    color: AppTheme.textSecondary,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(goal.content, style: AppTheme.heading),
          ),
          if (goal.motivation != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                '"${goal.motivation}"',
                style: AppTheme.caption.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          if (daysLeft != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _DeadlineBadge(daysLeft: daysLeft),
            ),
          const SizedBox(height: 16),
          const Divider(),
          _StartButton(onTap: onStart),
        ],
      ),
    );
  }
}

class _DeadlineBadge extends StatelessWidget {
  final int daysLeft;

  const _DeadlineBadge({required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    final isUrgent = daysLeft < 7;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: isUrgent ? AppTheme.accent : Colors.transparent,
      child: Text(
        daysLeft <= 0 ? 'OVERDUE' : '$daysLeft DAYS REMAINING',
        style: GoogleFonts.ibmPlexMono(
          fontSize: 11,
          letterSpacing: 1,
          color: isUrgent ? Colors.white : AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final VoidCallback onTap;

  const _StartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(
              'BEGIN INTERROGATION',
              style: GoogleFonts.bebasNeue(
                fontSize: 14,
                color: AppTheme.accent,
                letterSpacing: 3,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward, color: AppTheme.accent, size: 16),
          ],
        ),
      ),
    );
  }
}
