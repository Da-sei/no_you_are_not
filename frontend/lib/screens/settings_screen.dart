import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../providers/plan_provider.dart';
import '../providers/repository_providers.dart';
import '../providers/user_provider.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/usage_bar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  late final SubscriptionService _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = SubscriptionService(
      ref.read(subscriptionRepositoryProvider),
    );
    _subscription.onPurchaseResult = _onPurchaseResult;
    _subscription.initialize();
  }

  @override
  void dispose() {
    _subscription.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Stripe / Apple IAP からブラウザ経由で戻ったときにプランを更新
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(syncedUserProvider);
      ref.invalidate(messageUsageProvider);
    }
  }

  void _onPurchaseResult(bool success, String? error) {
    if (!mounted) return;
    if (success) {
      ref.invalidate(syncedUserProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PROプランにアップグレードしました！',
              style: AppTheme.caption.copyWith(color: AppTheme.textPrimary)),
        ),
      );
    } else if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $error')),
      );
    }
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(AppConstants.privacyPolicyUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URLを開けませんでした')),
        );
      }
    }
  }

  Future<void> _openCheckout() async {
    try {
      await _subscription.upgrade();
      if (mounted && !_subscription.useIAP) {
        ref.invalidate(syncedUserProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  Future<void> _openPortal() async {
    try {
      await _subscription.manage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text('SIGN OUT?', style: AppTheme.heading),
        content: Text('ログアウトしますか？', style: AppTheme.caption),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL',
                style: GoogleFonts.bebasNeue(
                    color: AppTheme.textSecondary, letterSpacing: 2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('SIGN OUT',
                style: GoogleFonts.bebasNeue(
                    color: AppTheme.accent, letterSpacing: 2)),
          ),
        ],
      ),
    );
    if (confirmed == true) await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(planProvider);
    final syncedUser = ref.watch(syncedUserProvider).valueOrNull;
    final email = syncedUser?['email'] as String? ?? '';

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(onBack: () => Navigator.of(context).pop()),
            const Divider(),
            // ── プランセクション ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CURRENT PLAN', style: AppTheme.label),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _PlanBadge(plan: plan),
                      const SizedBox(width: 12),
                      if (email.isNotEmpty)
                        Expanded(
                          child: Text(email,
                              style: AppTheme.caption,
                              overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (plan == 'FREE') ...[
                    _UsageSection(),
                    const SizedBox(height: 8),
                    Text('目標登録: 1件まで', style: AppTheme.caption),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _openCheckout,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.accent),
                          foregroundColor: AppTheme.accent,
                        ),
                        child: Text(
                          'UPGRADE TO PRO — ¥980/月',
                          style: GoogleFonts.bebasNeue(letterSpacing: 2),
                        ),
                      ),
                    ),
                  ] else ...[
                    Text('AIチャット・目標登録: 無制限', style: AppTheme.caption),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _openPortal,
                        child: Text(
                          'MANAGE SUBSCRIPTION',
                          style: GoogleFonts.bebasNeue(letterSpacing: 2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(),
            _SettingsItem(label: 'PRIVACY POLICY', onTap: _openPrivacyPolicy),
            const Divider(),
            _SettingsItem(label: 'SIGN OUT', onTap: _signOut, danger: true),
            const Divider(),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _PlanBadge extends StatelessWidget {
  final String plan;
  const _PlanBadge({required this.plan});

  @override
  Widget build(BuildContext context) {
    final isPro = plan == 'PRO';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPro ? AppTheme.accent : Colors.transparent,
        border: Border.all(color: isPro ? AppTheme.accent : AppTheme.border),
      ),
      child: Text(
        plan,
        style: GoogleFonts.bebasNeue(
          fontSize: 13,
          letterSpacing: 3,
          color: isPro ? Colors.white : AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _UsageSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAsync = ref.watch(messageUsageProvider);
    return usageAsync.when(
      loading: () => const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
              color: AppTheme.accent, strokeWidth: 1.5)),
      error: (err, st) =>
          Text('使用量を取得できませんでした', style: AppTheme.caption),
      data: (usage) {
        if (usage.limit == null) return const SizedBox.shrink();
        return UsageBar(count: usage.count, limit: usage.limit!);
      },
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text('SETTINGS', style: AppTheme.display)),
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration:
                  BoxDecoration(border: Border.all(color: AppTheme.border)),
              child: const Icon(Icons.close,
                  color: AppTheme.textSecondary, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _SettingsItem(
      {required this.label, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTheme.body.copyWith(
                    color: danger ? AppTheme.accent : AppTheme.textPrimary),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: danger ? AppTheme.accent : AppTheme.textSecondary,
                size: 14),
          ],
        ),
      ),
    );
  }
}
