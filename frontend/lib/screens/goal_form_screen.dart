import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/goals_provider.dart';
import '../repositories/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/paywall_sheet.dart';

class GoalFormScreen extends ConsumerStatefulWidget {
  const GoalFormScreen({super.key});

  @override
  ConsumerState<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends ConsumerState<GoalFormScreen> {
  final _contentCtrl = TextEditingController();
  final _motivationCtrl = TextEditingController();
  DateTime? _deadline;
  bool _submitting = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _motivationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.accent,
            surface: AppTheme.surface,
            onSurface: AppTheme.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) return;

    setState(() => _submitting = true);
    try {
      await ref.read(goalsProvider.notifier).createGoal(
            content: content,
            motivation: _motivationCtrl.text.trim().isEmpty
                ? null
                : _motivationCtrl.text.trim(),
            deadline: _deadline,
          );
      if (mounted) context.pop();
    } on LimitException catch (e) {
      if (mounted) await PaywallSheet.show(context, e);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEW MISSION'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COMMIT TO\nA MISSION.',
                style: AppTheme.display.copyWith(fontSize: 38),
              ),
              const SizedBox(height: 4),
              Text(
                'This cannot be edited later.',
                style: AppTheme.caption.copyWith(color: AppTheme.accent),
              ),
              const SizedBox(height: 36),
              _FieldLabel('OBJECTIVE *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentCtrl,
                style: AppTheme.body,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'What will you accomplish?',
                ),
              ),
              const SizedBox(height: 24),
              _FieldLabel('DEADLINE'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDeadline,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: Border.all(
                      color: _deadline != null
                          ? AppTheme.accent
                          : AppTheme.border,
                    ),
                  ),
                  child: Text(
                    _deadline != null
                        ? '${_deadline!.year}-'
                            '${_deadline!.month.toString().padLeft(2, '0')}-'
                            '${_deadline!.day.toString().padLeft(2, '0')}'
                        : 'Set a deadline.',
                    style: AppTheme.body.copyWith(
                      color: _deadline != null
                          ? AppTheme.textPrimary
                          : const Color(0xFF444444),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _FieldLabel('MOTIVATION'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _motivationCtrl,
                style: AppTheme.body,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Why does this matter to you?',
                ),
              ),
              const SizedBox(height: 36),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_outlined,
                      color: AppTheme.accent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Once committed, missions cannot be edited. Think carefully.',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.accent.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 1.5,
                          ),
                        )
                      : Text(
                          'COMMIT TO MISSION',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 16,
                            letterSpacing: 3,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTheme.label);
  }
}
