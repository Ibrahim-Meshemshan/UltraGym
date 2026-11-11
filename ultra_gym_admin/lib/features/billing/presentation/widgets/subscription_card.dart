import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../club_plan/presentation/bloc/club_plan_cubit.dart';
import '../../domain/models/billing_models.dart';
import '../../domain/models/billing_texts.dart';
import '../bloc/billing_cubits.dart';

/// بطاقة اشتراك النادي (`ClubBilling.html`): الباقة والدورة والحالة، الفترة، الميزات المشمولة، المستحق للمنصة،
/// والسجل السابق. بلا اشتراك مسجّل: دعوة للتواصل مع الفريق. السعر لا يرسله الخادم (يظهر بالفواتير).
class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BillingOverviewCubit>();
    return SliceView<BillingOverview>(
      slice: context.watch<BillingOverviewCubit>().state,
      loading: const DetailsShimmer(),
      onRetry: cubit.load,
      isEmpty: (o) => o.current == null,
      empty: CutCard(
        child: AppEmptyState(
          icon: Icons.workspace_premium_rounded,
          title: 'لا يوجد اشتراك مسجّل للنادي بعد',
          message: 'يفعّل فريق UltraGym الباقة ويصدر فواتيرها. تواصل معنا من الدعم الفني لأي سؤال.',
          actionLabel: 'فتح الدعم الفني',
          onAction: () => context.go(Routes.billingSupport),
        ),
      ),
      builder: (context, o) => _Content(o),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content(this.overview);

  final BillingOverview overview;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = overview.current!;
    final status = Labels.tenantSubscription(s.status);
    final days = context.select<PlanUsageCubit, int?>((u) => u.state.data?.daysRemaining);
    final features = context.select<ClubPlanCubit, Map<String, bool>?>((p) => p.state.entitlements.data?.features);
    final note = BillingTexts.note(s, days);
    final previous = [for (final h in overview.history) if (!h.isCurrent) h];
    return CutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s4,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpace.s3,
            runSpacing: AppSpace.s2,
            children: [
              Wrap(
                spacing: AppSpace.s3,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(BillingTexts.title(s), style: UType.h2(color: c.ink)),
                  StatusBadge(status.text, tone: status.tone),
                ],
              ),
              if (note != null) Text(note, style: UType.label(color: c.inkMuted)),
            ],
          ),
          Column(
            children: [
              BillingRow('الفترة الحالية', BillingTexts.period(s.startsOn, s.endsOn)),
              if (s.graceEndsOn != null) BillingRow('نهاية فترة السماح', Formatters.date(s.graceEndsOn), ltr: true),
              if (features != null)
                BillingRow('الميزات', BillingTexts.included(features).join(' · ').ifBlank('الأساسية فقط')),
              BillingRow(
                'المستحق للمنصة',
                overview.outstanding > 0 ? Formatters.usd(overview.outstanding) : 'لا مستحقات',
                ltr: overview.outstanding > 0,
                trailing: overview.overdueInvoices > 0
                    ? StatusBadge(
                        Formatters.count(overview.overdueInvoices, 'فاتورة متأخرة', 'فاتورتان متأخرتان', 'فواتير متأخرة'),
                        tone: UTone.danger,
                      )
                    : null,
              ),
            ],
          ),
          if (previous.isNotEmpty) _History(previous),
          Text(
            'التجديد وتغيير الباقة يتمّان مع فريق UltraGym. الدفع يدوي بتحويل أو نقداً.',
            style: UType.caption(color: c.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// الاشتراكات السابقة (من الأحدث).
class _History extends StatelessWidget {
  const _History(this.items);

  final List<PlatformSubscription> items;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.s2,
      children: [
        Text('الاشتراكات السابقة', style: UType.label(color: c.inkMuted).weight(600)),
        for (final h in items)
          Wrap(
            spacing: AppSpace.s3,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(BillingTexts.title(h), style: UType.label(color: c.ink)),
              Text(BillingTexts.period(h.startsOn, h.endsOn), style: UType.caption(color: c.inkMuted)),
              StatusBadge(Labels.tenantSubscription(h.status).text, tone: Labels.tenantSubscription(h.status).tone),
            ],
          ),
      ],
    );
  }
}

/// سطر "العنوان ← القيمة" بفاصل خفيف (`.kv` بالنموذج).
class BillingRow extends StatelessWidget {
  const BillingRow(this.label, this.value, {super.key, this.ltr = false, this.trailing});

  final String label, value;
  final bool ltr;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = UType.body(color: c.ink);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.s3,
        children: [
          SizedBox(
            width: AppSize.billingLabelCol,
            child: Text(label, style: UType.label(color: c.inkMuted)),
          ),
          Expanded(
            child: Wrap(
              spacing: AppSpace.s2,
              runSpacing: AppSpace.s1,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [ltr ? LtrText(value, style: style) : Text(value, style: style), ?trailing],
            ),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String ifBlank(String fallback) => trim().isEmpty ? fallback : this;
}
