import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/repository_providers.dart';
import '../providers/user_provider.dart';
import '../repositories/api_client.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';

class PaywallSheet extends ConsumerStatefulWidget {
  final LimitException error;

  const PaywallSheet({super.key, required this.error});

  static Future<void> show(BuildContext context, LimitException error) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      isScrollControlled: true,
      builder: (_) => PaywallSheet(error: error),
    );
  }

  @override
  ConsumerState<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends ConsumerState<PaywallSheet> {
  bool _loading = false;
  late final SubscriptionService _service;

  @override
  void initState() {
    super.initState();
    _service = SubscriptionService(ref.read(subscriptionRepositoryProvider));
    _service.onPurchaseResult = _onPurchaseResult;
    _service.initialize();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  void _onPurchaseResult(bool success, String? error) {
    if (!mounted) return;
    if (success) {
      ref.invalidate(syncedUserProvider);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PROプランにアップグレードしました！',
              style: AppTheme.caption.copyWith(color: AppTheme.textPrimary)),
        ),
      );
    } else if (error != null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $error')),
      );
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _upgrade() async {
    setState(() => _loading = true);
    try {
      await _service.upgrade();
      // Stripe の場合はブラウザに移動するだけなので loading を解除してシートを閉じる
      if (mounted && !_service.useIAP) {
        Navigator.pop(context);
        ref.invalidate(syncedUserProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    } finally {
      if (mounted && !_service.useIAP) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: AppTheme.accent,
                child: Text('FREE', style: AppTheme.label.copyWith(color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Text('LIMIT REACHED.', style: AppTheme.heading),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.error.isMessages
                ? '無料プランのAIチャットは月${widget.error.limit}回までです。\n今月の使用回数: ${widget.error.current}/${widget.error.limit}'
                : '無料プランの目標登録は${widget.error.limit}件までです。\n現在の登録数: ${widget.error.current}/${widget.error.limit}',
            style: AppTheme.caption,
          ),
          const SizedBox(height: 28),
          const _PlanCompareTable(),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _upgrade,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 1.5),
                    )
                  : Text(
                      'UPGRADE TO PRO — ¥980/月',
                      style: GoogleFonts.bebasNeue(fontSize: 15, letterSpacing: 2),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('MAYBE LATER',
                  style: GoogleFonts.bebasNeue(letterSpacing: 2)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCompareTable extends StatelessWidget {
  const _PlanCompareTable();

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: AppTheme.border),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
      },
      children: [
        _headerRow(),
        _row('AIチャット', '月10回', '無制限'),
        _row('目標登録', '1件', '無制限'),
        _row('思考ログ', '直近10件', '無制限'),
      ],
    );
  }

  TableRow _headerRow() => TableRow(
        decoration: const BoxDecoration(color: AppTheme.bg),
        children: [
          _cell('機能', isHeader: true),
          _cell('FREE', isHeader: true),
          _cell('PRO', isHeader: true, highlight: true),
        ],
      );

  TableRow _row(String feature, String free, String pro) => TableRow(children: [
        _cell(feature),
        _cell(free),
        _cell(pro, highlight: true),
      ]);

  Widget _cell(String text, {bool isHeader = false, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        style: isHeader
            ? AppTheme.label.copyWith(
                color: highlight ? AppTheme.accent : AppTheme.textSecondary)
            : AppTheme.caption.copyWith(
                color: highlight ? AppTheme.textPrimary : AppTheme.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }
}
