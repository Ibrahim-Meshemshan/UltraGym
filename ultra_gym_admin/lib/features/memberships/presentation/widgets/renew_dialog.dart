import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../data/repo/membership_detail_repository.dart';
import '../../domain/models/membership_detail_models.dart';
import 'cash_fields.dart';

/// تجديد بنفس الخطة `POST memberships/{id}/renew`: التسعير من `memberships/quote` (يبدأ بعد الحالي إن كان سارياً)،
/// ثم الدفع بالعملتين. الناقص دين إن سمح النادي بالدفع الجزئي (الخادم يرفض غير ذلك برسالته).
/// النجاح يفتح صفحة الاشتراك الجديد. تغيير الخطة أو الكوبون من "بيع اشتراك".
Future<void> renewMembership(BuildContext context, MembershipDetail d) async {
  final planId = d.planId;
  if (planId == null) return;
  final router = GoRouter.of(context);
  final repo = sl<MembershipDetailRepository>();
  final branch = CashBranch.of(context, fallback: d.branchId);
  final keeper = IdempotencyKeeper();
  final done = await FormDialog.show<int>(
    context,
    title: 'تجديد ${d.membership.planName}',
    icon: Icons.autorenew_rounded,
    initial: branch.initial,
    submitLabel: 'تجديد',
    fields: (form) => FormColumn(
      children: [
        BlocProvider(
          create: (_) => LoadCubit(() => repo.renewQuote(planId: planId, previousId: d.id))..load(),
          child: const _QuoteView(),
        ),
        const PaymentFields(usdLabel: 'المدفوع بالدولار', sypLabel: 'المدفوع بالليرة'),
        if (branch.needsField) branch.field(),
      ],
    ),
    onSubmit: (form) {
      final payments = PaymentFields.linesOf(form);
      final body = {
        if (payments.isNotEmpty) 'payments': payments,
        CashBranch.key: ?branch.idOf(form),
        'trainer_id': ?d.trainerId,
      };
      return repo.renew(d.id, body, idempotencyKey: keeper.keyFor(body));
    },
  );
  if (done != null) router.go(Routes.child(Routes.memberships, done.data));
}

/// ملخص التسعير: الفترة الجديدة والصافي بالعملتين، وهل يُقبل دفع جزئي.
class _QuoteView extends StatelessWidget {
  const _QuoteView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<LoadCubit<MembershipQuote>>();
    return SliceView<MembershipQuote>(
      slice: cubit.state,
      loading: const AppShimmer(child: ShimmerBox(height: AppSize.controlLg * 2)),
      onRetry: cubit.load,
      builder: (context, q) {
        final c = context.colors;
        final label = UType.caption(color: c.infoInk);
        final value = UType.body(color: c.infoInk).weight(600);
        return Container(
          padding: const EdgeInsets.all(AppSpace.s4),
          decoration: BoxDecoration(color: c.infoSoft, borderRadius: AppRadius.fieldAll),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.s2,
            children: [
              Wrap(
                spacing: AppSpace.s6,
                runSpacing: AppSpace.s2,
                children: [
                  _Fig('الفترة', '${Formatters.date(q.startsOn)} → ${Formatters.date(q.endsOn)}', label, value),
                  _Fig('الصافي', Formatters.usd(q.netUsd), label, value),
                  _Fig('بالليرة', Formatters.syp(q.netSyp), label, value),
                ],
              ),
              Text(
                q.allowPartial ? 'يمكن دفع جزء منه، والباقي يُسجَّل ديناً.' : 'يجب دفع الصافي كاملاً عند التجديد.',
                style: label,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Fig extends StatelessWidget {
  const _Fig(this.label, this.value, this.labelStyle, this.valueStyle);

  final String label, value;
  final TextStyle labelStyle, valueStyle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: labelStyle),
      LtrText(value, style: valueStyle),
    ],
  );
}
