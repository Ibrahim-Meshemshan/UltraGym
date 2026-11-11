import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../domain/models/dashboard_models.dart';
import '../demo/demo_card.dart';
import '../demo/demo_shape.dart';
import '../demo/lollipop_chart.dart';

/// المال · هذا الشهر (للمالك) بأسلوب التجربة: أربعة أرقام بآبار هادئة، ثم رسم "الخرز" لإيراد
/// آخر 7 أو 14 يوماً (الخادم يرسل 14؛ التبويب يختار الطرف الأخير منها، آخر يوم = اليوم).
class FinanceCard extends StatelessWidget {
  const FinanceCard({super.key, required this.finance});

  final DashboardFinance finance;

  static const ranges = [(value: 7, label: '7 أيام'), (value: 14, label: '14 يوماً')];

  @override
  Widget build(BuildContext context) {
    final f = finance;
    return BlocProvider(
      create: (_) => ValueCubit<int>(ranges.first.value),
      child: BlocBuilder<ValueCubit<int>, int>(
        builder: (context, range) {
          final days = f.daily.length > range ? f.daily.sublist(f.daily.length - range) : f.daily;
          return DemoCard(
            title: 'المال · هذا الشهر',
            subtitle: 'إيراد آخر ${Formatters.count(days.length, 'يوم واحد', 'يومين', 'أيام', many: 'يوماً')}',
            action: 'التقارير',
            onAction: () => context.go(Routes.reports),
            trailing: f.daily.length > ranges.first.value
                ? DemoSegmented<int>(options: ranges, value: range, onChanged: context.read<ValueCubit<int>>().set)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ResponsiveGrid(
                  minItemWidth: AppSize.figure,
                  children: [
                    _Figure(label: 'إيراد اليوم', usd: f.revenueTodayUsd),
                    _Figure(label: 'إيراد الشهر', usd: f.revenueMonthUsd),
                    _Figure(label: 'مصاريف الشهر', usd: f.expensesMonthUsd),
                    _Figure(
                      label: 'صافي الشهر',
                      usd: f.netMonthUsd,
                      tone: f.netMonthUsd < 0 ? UTone.danger : UTone.success,
                    ),
                  ],
                ),
                AppSpace.gap5,
                LollipopChart(days: days),
              ],
            ),
          );
        },
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
    final d = AppPalette.of(context);
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpace.s3),
      decoration: BoxDecoration(
        color: d.well,
        borderRadius: DemoShape.mdAll,
        border: Border.all(color: d.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: UType.caption(color: d.muted)),
          AppSpace.gap1,
          LtrText(Formatters.usd(usd), style: UType.h3(color: tone?.colors(c).$2 ?? d.ink)),
        ],
      ),
    );
  }
}
