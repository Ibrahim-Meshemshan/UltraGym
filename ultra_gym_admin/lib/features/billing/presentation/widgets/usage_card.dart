import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../club_plan/presentation/bloc/club_plan_cubit.dart';
import '../../domain/models/billing_models.dart';
import '../../domain/models/billing_texts.dart';
import '../bloc/billing_cubits.dart';

/// "الاستخدام مقابل الحدود" (`ClubBilling.html`): الأعضاء والموظفون والفروع من `GET club.usage`
/// (الشريط عنبري عند بلوغ الحد)، وحد التخزين من الباقة (لا استعمال له بالخادم). فشلها يخفيها.
class UsageCard extends StatelessWidget {
  const UsageCard({super.key});

  @override
  Widget build(BuildContext context) {
    final slice = context.watch<PlanUsageCubit>().state;
    final storage = context.select<ClubPlanCubit, int?>((p) => p.state.entitlements.data?.limits.storageMb);
    final c = context.colors;
    if (slice.isFirstLoad) return const DetailsShimmer();
    final u = slice.data;
    if (u == null) return const SizedBox.shrink();
    return CutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s4,
        children: [
          Text('الاستخدام مقابل الحدود', style: UType.h3(color: c.ink)),
          _Meter('الأعضاء', u.players),
          _Meter('الموظفون', u.staff, hint: 'المالك والاستقبال'),
          _Meter('الفروع', u.branches),
          if (BillingTexts.storage(storage) case final s?)
            Row(
              children: [
                Expanded(child: Text('التخزين', style: UType.label(color: c.ink))),
                LtrText(s, style: UType.label(color: c.inkMuted)),
              ],
            ),
          Text(
            'عند الوصول للحد تُرفض إضافة عضو أو موظف أو فرع جديد.',
            style: UType.caption(color: c.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter(this.label, this.line, {this.hint});

  final String label;
  final String? hint;
  final UsageLine line;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ratio = line.ratio;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s2,
      children: [
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: AppSpace.s2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(label, style: UType.label(color: c.ink)),
                  if (hint case final h?) Text(h, style: UType.caption(color: c.inkFaint)),
                ],
              ),
            ),
            LtrText(BillingTexts.usage(line), style: UType.label(color: line.reached ? c.warningInk : c.ink)),
          ],
        ),
        if (ratio != null)
          ClipRRect(
            borderRadius: AppRadius.fullAll,
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: AppSpace.s2,
              color: line.reached ? c.warning : c.primary,
              backgroundColor: c.surfaceAlt,
            ),
          )
        else
          Text('بلا حد بباقتك', style: UType.caption(color: c.inkFaint)),
      ],
    );
  }
}
