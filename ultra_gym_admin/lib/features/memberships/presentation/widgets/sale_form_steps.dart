import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/sale_models.dart';
import '../bloc/sell_membership_cubit.dart';
import 'cash_fields.dart';
import 'sale_steps.dart';

/// الخطوة 3: تاريخ البداية (النهاية من الخادم) والخصم: كوبون للجميع، أو خصم يدوي للمالك.
class SaleDiscountStep extends StatelessWidget {
  const SaleDiscountStep({super.key, required this.isOwner});

  final bool isOwner;

  static const startKey = 'starts_on', couponKey = 'coupon_code', discountKey = 'discount_usd';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<SellMembershipCubit>();
    final mode = context.select<SellMembershipCubit, DiscountMode>((c) => c.state.mode);
    final endsOn = context.select<SellMembershipCubit, DateTime?>((c) => c.state.quote.data?.endsOn);
    final today = DateUtils.dateOnly(DateTime.now());
    return SaleStep(
      number: 3,
      title: 'التاريخ والخصم',
      // تغيير التاريخ بالمنتقي ← تسعير جديد (النهاية والسعر من الخادم).
      child: BlocListener<AppFormCubit, AppFormState>(
        listenWhen: (a, b) => a.values[startKey] != b.values[startKey],
        listener: (context, s) => cubit.setStart(s.values[startKey] as DateTime?),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.s4,
          children: [
            ResponsiveGrid(
              maxColumns: 2,
              children: [
                FormDate(
                  startKey,
                  label: 'تاريخ البداية',
                  // الخادم يقبل حتى 30 يوماً للخلف (تسجيل متأخر).
                  firstDate: today.subtract(const Duration(days: 30)),
                  lastDate: today.add(const Duration(days: 365)),
                ),
                _ReadOnly(
                  label: 'تاريخ النهاية',
                  value: endsOn == null ? '—' : Formatters.date(endsOn),
                  note: 'يحسبه الخادم من الخطة',
                ),
              ],
            ),
            Text('الخصم', style: UType.label(color: c.ink)),
            if (isOwner)
              Wrap(
                spacing: AppSpace.s2,
                children: [
                  for (final (m, label) in const [
                    (DiscountMode.coupon, 'كوبون'),
                    (DiscountMode.manual, 'خصم يدوي · للمالك'),
                  ])
                    ChoiceChip(label: Text(label), selected: mode == m, onSelected: (_) => cubit.setMode(m)),
                ],
              ),
            if (mode == DiscountMode.coupon)
              const _ApplyField(name: couponKey, label: 'كود الكوبون', hint: 'WELCOME10', manual: false)
            else
              const _ApplyField(name: discountKey, label: 'قيمة الخصم بالدولار', hint: '5.00', manual: true),
          ],
        ),
      ),
    );
  }
}

/// حقل + "تطبيق": الكوبون أو الخصم اليدوي يُرسل للتسعير، ويظهر تحته المطبّق أو سبب الرفض.
class _ApplyField extends StatelessWidget {
  const _ApplyField({required this.name, required this.label, required this.hint, required this.manual});

  final String name, label, hint;
  final bool manual;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<SellMembershipCubit>();
    final form = context.read<AppFormCubit>();
    final s = context.watch<SellMembershipCubit>().state;
    void apply() => manual
        ? cubit.applyDiscount(double.tryParse('${form.value(name) ?? ''}'.replaceAll(',', '').trim()))
        : cubit.applyCoupon('${form.value(name) ?? ''}');
    final applied = manual ? s.discount != null : s.coupon != null;
    final discount = s.quote.data?.discountUsd ?? 0;
    final note = switch (s.discountError) {
      final e? => (e, c.dangerInk),
      _ when applied => (
        '${manual ? 'خصم مطبّق' : 'كوبون صالح'}: ${Formatters.ltr('−${Formatters.usd(discount)}')}',
        c.successInk,
      ),
      _ => (manual ? 'لا يتجاوز سعر الخطة' : 'اكتب الكود ثم "تطبيق"', c.inkMuted),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s2,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: AppSpace.s3,
          children: [
            Expanded(
              child: FormText(
                name,
                label: label,
                hint: hint,
                ltr: true,
                keyboardType: manual ? const TextInputType.numberWithOptions(decimal: true) : null,
                onSubmitted: (_) => apply(),
              ),
            ),
            UGButton(label: 'تطبيق', kind: UButtonKind.secondary, onPressed: s.planId == null ? null : apply),
          ],
        ),
        Semantics(
          liveRegion: true,
          child: Text(note.$1, style: UType.caption(color: note.$2)),
        ),
      ],
    );
  }
}

/// الخطوة 4: الدفع بالعملتين (أو بلا دفع إن سمح النادي بالدين)، وصندوق الفرع، والملاحظات.
class SalePaymentStep extends StatelessWidget {
  const SalePaymentStep({super.key, required this.branch});

  final CashBranch branch;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rate = context.select<SellMembershipCubit, double?>((c) => c.state.quote.data?.exchangeRate);
    return SaleStep(
      number: 4,
      title: 'الدفع',
      trailing: rate == null
          ? null
          : Text.rich(
              TextSpan(
                text: 'سعر صرف اليوم: ',
                children: [
                  TextSpan(
                    text: Formatters.ltr(Formatters.number(rate)),
                    style: UType.caption(color: c.ink).weight(600),
                  ),
                  const TextSpan(text: ' ل.س للدولار'),
                ],
              ),
              style: UType.caption(color: c.inkMuted),
            ),
      child: FormColumn(
        children: [
          const PaymentFields(usdLabel: 'المدفوع بالدولار', sypLabel: 'المدفوع بالليرة'),
          if (branch.needsField) branch.field(label: 'فرع البيع والصندوق'),
          const FormText('notes', label: 'ملاحظات', hint: 'خصم للطلاب...', maxLines: 2),
        ],
      ),
    );
  }
}

/// قيمة للعرض فقط بشكل حقل (تاريخ النهاية).
class _ReadOnly extends StatelessWidget {
  const _ReadOnly({required this.label, required this.value, required this.note});

  final String label, value, note;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s2,
      children: [
        FieldLabel(label),
        Container(
          height: AppSize.control,
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3),
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: AppRadius.fieldAll,
            border: Border.all(color: c.line),
          ),
          child: LtrText(value, style: UType.body(color: c.ink)),
        ),
        Text(note, style: UType.caption(color: c.inkMuted)),
      ],
    );
  }
}
