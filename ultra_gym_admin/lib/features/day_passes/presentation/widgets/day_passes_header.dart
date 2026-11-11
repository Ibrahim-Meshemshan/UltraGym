import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/day_pass_models.dart';
import '../bloc/day_passes_cubit.dart';

/// رأس الشاشة: سعر الدخول اليومي بالفرع (أو سبب تعذّر البيع) و "بيع دخول يومي".
class DayPassesHeader extends StatelessWidget {
  const DayPassesHeader({super.key, required this.onSell});

  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final slice = context.watch<DayPassPriceCubit>().state;
    final p = slice.data;
    final title = p?.branchName == null ? 'سعر الدخول اليومي' : 'سعر الدخول اليومي · ${p!.branchName}';
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpace.s4,
      runSpacing: AppSpace.s3,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpace.s1,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: UType.h3(color: c.ink)),
            ),
            if (slice.isFirstLoad)
              const AppShimmer(child: ShimmerBox(width: AppSpace.s16 * 2))
            else if (p != null)
              _PriceLine(p)
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('تعذّر تحميل السعر.', style: UType.caption(color: c.inkMuted)),
                  TextButton(onPressed: context.read<DayPassPriceCubit>().load, child: const Text('إعادة المحاولة')),
                ],
              ),
          ],
        ),
        UGButton(
          label: 'بيع دخول يومي',
          icon: Icons.confirmation_number_rounded,
          // السعر لم يصل بعد أو فشل: النافذة تطلبه بنفسها.
          onPressed: p == null || p.canSell ? onSell : null,
        ),
      ],
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine(this.p);

  final DayPassPrice p;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (!p.enabled) {
      return Text('الدخول اليومي غير مفعّل بإعدادات النادي.', style: UType.label(color: c.warningInk));
    }
    if (!p.hasPrice) {
      return Text(
        p.canChangePrice
            ? 'لم يُحدد سعر بعد: اكتبه عند البيع، أو حدده من إعدادات النادي.'
            : 'لم يُحدد سعر بعد. يحدده مالك النادي من الإعدادات.',
        style: UType.label(color: c.warningInk),
      );
    }
    return Wrap(
      spacing: AppSpace.s2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        LtrText(Formatters.usd(p.priceUsd), style: UType.body(color: c.ink).weight(600)),
        if (p.priceSyp != null) LtrText(Formatters.syp(p.priceSyp), style: UType.label(color: c.inkMuted)),
        Text(p.source == 'branch' ? 'سعر الفرع' : 'سعر النادي', style: UType.caption(color: c.inkMuted)),
      ],
    );
  }
}

/// مجاميع السجل للفلتر الحالي (`meta.summary`). أول تحميل بهياكل، والفشل يتركه للجدول.
class DayPassesStats extends StatelessWidget {
  const DayPassesStats({super.key});

  @override
  Widget build(BuildContext context) {
    final slice = context.select<DayPassesListCubit, Slice<Paged<DayPass>>>((l) => l.state.slice);
    if (slice.isFirstLoad) return const StatsShimmer();
    final data = slice.data;
    if (data == null) return const SizedBox.shrink();
    final s = DayPassSummary.fromJson(data.summary);
    return ResponsiveGrid(
      children: [
        AppStatCard(
          icon: Icons.confirmation_number_outlined,
          label: 'دخول يومي',
          value: s.count.toDouble(),
          note: 'للفترة والفلاتر المعروضة',
        ),
        AppStatCard(icon: Icons.person_outline_rounded, label: 'زوار', value: s.visitors.toDouble()),
        AppStatCard(icon: Icons.badge_outlined, label: 'أعضاء بلا اشتراك', value: s.players.toDouble()),
        AppStatCard(icon: Icons.payments_outlined, label: 'الإيراد', value: s.revenueUsd, prefix: r'$', decimals: 2),
      ],
    );
  }
}
