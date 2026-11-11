import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../notifications/presentation/bloc/unread_count_cubit.dart';
import '../../data/repo/sell_membership_repository.dart';
import '../../domain/models/sale_models.dart';
import '../bloc/sell_membership_cubit.dart';
import 'cash_fields.dart';

/// ملخص البيع (`aside` بالنموذج): الخطة والفترة والسعر والخصم والصافي من التسعير،
/// والمدفوع والمتبقي تقديراً من حقلي الدفع بسعر صرف اليوم، ثم "تأكيد البيع".
class SaleSummary extends StatelessWidget {
  const SaleSummary({super.key, required this.branch});

  final CashBranch branch;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.watch<SellMembershipCubit>().state;
    final form = context.read<AppFormCubit>();
    final q = s.quote.data;
    return CutCard(
      padding: const EdgeInsets.all(AppSpace.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s2,
        children: [
          Semantics(
            header: true,
            child: Text('الملخص', style: UType.h3(color: c.ink)),
          ),
          _Line('الخطة', text: s.plan?.name ?? '—'),
          _Line(
            'المدة',
            ltr: q?.startsOn == null ? '—' : '${Formatters.date(q!.startsOn)} → ${Formatters.date(q.endsOn)}',
          ),
          if (s.quote.isLoading) const LinearProgressIndicator(minHeight: AppSize.progress),
          if (s.quote.failure case final f?)
            ErrorState(failure: f, onRetry: context.read<SellMembershipCubit>().retryQuote, compact: true),
          Divider(color: c.line),
          _Line('السعر', ltr: q == null ? '—' : Formatters.usd(q.priceUsd)),
          if ((q?.discountUsd ?? 0) > 0)
            _Line(
              q!.couponCode == null ? 'الخصم' : 'الخصم · ${Formatters.ltr(q.couponCode!)}',
              ltr: '−${Formatters.usd(q.discountUsd)}',
              tone: c.successInk,
            ),
          Divider(color: c.line),
          _Net(q),
          // المدفوع يتغير مع الكتابة بحقلي الدفع (controllers) لا مع حالة النموذج.
          ListenableBuilder(
            listenable: Listenable.merge([form.text(PaymentFields.usd), form.text(PaymentFields.syp)]),
            builder: (context, _) => _Paid(q, form),
          ),
          if (q != null)
            Text(
              q.allowPartial
                  ? 'الدفع الجزئي مسموح بإعدادات النادي. الباقي يظهر بقائمة الديون.'
                  : 'الدفع الجزئي غير مفعّل بالنادي: ادفع كامل الصافي.',
              style: UType.caption(color: c.inkMuted),
            ),
          const FormErrorBanner(),
          AppSpace.gap2,
          BlocBuilder<AppFormCubit, AppFormState>(
            buildWhen: (a, b) => a.submitting != b.submitting,
            builder: (context, f) => UGButton(
              label: f.submitting ? 'جارٍ البيع...' : 'تأكيد البيع',
              icon: Icons.check_rounded,
              large: true,
              expand: true,
              onPressed: f.submitting || s.member.data == null || q == null || s.quote.isLoading
                  ? null
                  : () => _confirm(context),
            ),
          ),
          Text(
            s.member.data == null || s.planId == null
                ? 'اختر العضو والخطة أولاً.'
                : 'بعد التأكيد: إيصال لكل دفعة جاهز للطباعة.',
            textAlign: TextAlign.center,
            style: UType.caption(color: c.inkMuted),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final sale = context.read<SellMembershipCubit>();
    final form = context.read<AppFormCubit>();
    final unread = context.read<UnreadCountCubit?>();
    final s = sale.state;
    // حقل المدرب يبقى مسجلاً بعد تبديل الخطة لخطة عادية: لا تحقق منه حينها.
    if (!s.needsTrainer) form.validator('trainer_id', null);
    final payments = PaymentFields.linesOf(form);
    final notes = '${form.value('notes') ?? ''}'.trim();
    final body = <String, Object?>{
      'player_id': s.member.data!.id,
      'plan_id': s.planId,
      CashBranch.key: ?branch.idOf(form),
      if (s.startsOn != null) 'starts_on': Formatters.date(s.startsOn),
      'coupon_code': ?s.coupon,
      'discount_usd': ?s.discount,
      if (s.needsTrainer) 'trainer_id': form.value('trainer_id'),
      if (payments.isNotEmpty) 'payments': payments,
      if (notes.isNotEmpty) 'notes': notes,
    };
    final r = await form.submit((_) => sl<SellMembershipRepository>().sell(body, idempotencyKey: sale.keyFor(body)));
    if (r case ApiSuccess(:final data, :final message)) {
      sale.done(data.withMessage(message));
      unawaited(unread?.refresh());
    }
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, {this.text, this.ltr, this.tone});

  final String label;
  final String? text, ltr;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = UType.body(color: tone ?? c.ink);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.s3,
      children: [
        Text(label, style: UType.body(color: c.inkMuted)),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ltr != null
                ? LtrText(ltr!, style: style)
                : Text(text ?? '—', style: style, textAlign: TextAlign.end),
          ),
        ),
      ],
    );
  }
}

class _Net extends StatelessWidget {
  const _Net(this.q);

  final MembershipQuote? q;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text('الصافي', style: UType.bodyLg(color: c.ink).weight(600)),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            LtrText(q == null ? '—' : Formatters.usd(q!.netUsd), style: UType.stat(color: c.ink)),
            if (q != null) LtrText(Formatters.syp(q!.netSyp), style: UType.caption(color: c.inkMuted)),
          ],
        ),
      ],
    );
  }
}

/// المدفوع والمتبقي: تقدير للعرض (الخادم يحسب الدين النهائي ويرفض الزائد).
class _Paid extends StatelessWidget {
  const _Paid(this.q, this.form);

  final MembershipQuote? q;
  final AppFormCubit form;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final quote = q;
    if (quote == null) return const SizedBox.shrink();
    num read(String key) => num.tryParse('${form.value(key) ?? ''}'.replaceAll(',', '').trim()) ?? 0;
    final paid = quote.paidUsd(usd: read(PaymentFields.usd), syp: read(PaymentFields.syp));
    final left = quote.netUsd - paid;
    final (label, value, soft, ink) = switch (left) {
      < -0.005 => ('المدفوع أكثر من الصافي', -left, c.dangerSoft, c.dangerInk),
      > 0.005 => ('المتبقي (دين)', left, c.warningSoft, c.warningInk),
      _ => ('مدفوع بالكامل', 0.0, c.successSoft, c.successInk),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s2,
      children: [
        _Line('المدفوع', ltr: Formatters.usd(paid)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3, vertical: AppSpace.s2),
          decoration: BoxDecoration(color: soft, borderRadius: AppRadius.smAll),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: UType.body(color: ink).weight(600)),
              ),
              if (value > 0) LtrText(Formatters.usd(value), style: UType.body(color: ink).weight(600)),
            ],
          ),
        ),
      ],
    );
  }
}
