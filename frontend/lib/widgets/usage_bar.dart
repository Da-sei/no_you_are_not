import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class UsageBar extends StatelessWidget {
  final int count;
  final int limit;

  const UsageBar({super.key, required this.count, required this.limit});

  @override
  Widget build(BuildContext context) {
    final ratio = (count / limit).clamp(0.0, 1.0);
    final isCritical = ratio >= 0.8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('AIチャット 今月の使用回数', style: AppTheme.label),
            Text(
              '$count / $limit 回',
              style: AppTheme.label.copyWith(
                color: isCritical ? AppTheme.accent : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRect(
          child: SizedBox(
            height: 3,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      width: constraints.maxWidth,
                      color: AppTheme.border,
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      width: constraints.maxWidth * ratio,
                      color: isCritical ? AppTheme.accent : AppTheme.textSecondary,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
