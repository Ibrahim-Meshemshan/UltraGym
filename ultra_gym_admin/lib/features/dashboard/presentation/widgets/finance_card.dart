import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../domain/models/dashboard_models.dart';
import 'revenue_bars.dart';

/// المال · هذا الشهر (للمالك): أربعة أرقام ثم إيراد آخر 7 أيام (آخر عمود = اليوم بالبرتقالي).
class FinanceCard extends StatelessWidget {
  const FinanceCard({super.key, required this.finance});

  final DashboardFinance finance;

  @override
  Widget build(BuildContext context) {
    final f = finance;
    return SectionCard(
      title: 'المال · هذا الشهر',
      action: 'التقارير',
      onAction: () => context.go(Routes.reports),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResponsiveGrid(
            minItemWidth: AppSize.figure,
            children: [
              _Figure(label: 'إيراد اليوم', usd: f.revenueTodayUsd),
              _Figure(label: 'إيراد الشهر', usd: f.revenueMonthUsd),
              _Figure(label: 'مصاريف الشهر', usd: f.expensesMonthUsd),
              _Figure(label: 'صافي الشهر', usd: f.netMonthUsd, tone: f.netMonthUsd < 0 ? UTone.danger : UTone.success),
            ],
          ),
          AppSpace.gap5,
          RevenueBars(daily: f.daily),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.usd, this.tone});

  final String label;
  final double usd;
  final UTone? tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: UType.caption(color: c.inkMuted)),
        AppSpace.gap1,
        LtrText(Formatters.usd(usd), style: UType.h3(color: tone?.colors(c).$2 ?? c.ink)),
      ],
    );
  }
}
