import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/payroll_models.dart';
import 'payroll_actions.dart';
import 'salary_breakdown.dart';

/// معاينة راتب لم يُصرف (`Payroll.html`): الأساسي والعمولة والسلف المفتوحة من الخادم، ثم المكافأة والخصومات وخصم
/// السلف والعملة، والتفصيل بالصافي **التقديري** مع الكتابة، و "صرف الراتب من الصندوق".
class SalaryForm extends StatelessWidget {
  const SalaryForm({super.key, required this.preview, required this.onPaid});

  final SalaryPreview preview;
  final Future<void> Function() onPaid;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => AppFormCubit(initial: const {PayrollActions.currency: 'USD'}),
    child: _Form(preview: preview, onPaid: onPaid),
  );
}

class _Form extends StatelessWidget {
  const _Form({required this.preview, required this.onPaid});

  final SalaryPreview preview;
  final Future<void> Function() onPaid;

  static const _money = TextInputType.numberWithOptions(decimal: true);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = preview;
    final form = context.read<AppFormCubit>();
    final hasAdvances = p.openAdvancesUsd > 0;
    if (!hasAdvances) form.validator(PayrollActions.advance, null);
    final busy = context.select<AppFormCubit, bool>((f) => f.state.submitting);
    Future<void> pay() async {
      if (await PayrollActions.paySalary(context, p, form)) await onPaid();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s4,
      children: [
        ResponsiveGrid(
          minItemWidth: AppSize.formFieldMin,
          maxColumns: 3,
          spacing: AppSpace.s3,
          children: [
            SalaryTile(label: 'الراتب الأساسي', usd: p.baseUsd),
            SalaryTile(
              label: p.commissionClients > 0
                  ? 'العمولة · ${Formatters.count(p.commissionClients, 'عميل', 'عميلان', 'عملاء', many: 'عميلاً')}'
                  : 'العمولة',
              usd: p.commissionUsd,
            ),
            SalaryTile(label: 'سلف مفتوحة', usd: p.openAdvancesUsd, tone: UTone.warning),
          ],
        ),
        ResponsiveGrid(
          minItemWidth: AppSize.formFieldMin,
          maxColumns: 3,
          spacing: AppSpace.s3,
          children: [
            FormText(
              PayrollActions.bonus,
              label: 'مكافأة (\$)',
              ltr: true,
              hint: '0.00',
              keyboardType: _money,
              validator: Validators.amount(optional: true),
            ),
            FormText(
              PayrollActions.deductions,
              label: 'خصومات (\$)',
              ltr: true,
              hint: '0.00',
              keyboardType: _money,
              validator: Validators.all([
                Validators.amount(optional: true),
                (_) => PayrollActions.netOf(p, form) < -0.004 ? 'الخصومات أكبر من الراتب: الصافي سالب.' : null,
              ]),
            ),
            if (hasAdvances)
              FormText(
                PayrollActions.advance,
                label: 'خصم من السلف (\$)',
                ltr: true,
                hint: 'حتى ${Formatters.usd(p.openAdvancesUsd)}',
                keyboardType: _money,
                validator: Validators.all([
                  Validators.amount(optional: true),
                  (v) => PayrollActions.amountOf(v) - p.openAdvancesUsd > 0.004
                      ? 'أقصى خصم ${Formatters.ltr(Formatters.usd(p.openAdvancesUsd))}.'
                      : null,
                ]),
              ),
          ],
        ),
        const FormChoice<String>(
          PayrollActions.currency,
          label: 'الصرف',
          options: [(value: 'USD', label: 'بالدولار'), (value: 'SYP', label: 'بالليرة')],
        ),
        const FormText(PayrollActions.note, label: 'ملاحظة', hint: 'مثلاً: مكافأة الالتزام'),
        _LiveBreakdown(p),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpace.s3,
          runSpacing: AppSpace.s2,
          children: [
            UGButton(
              label: 'صرف الراتب من الصندوق',
              icon: Icons.payments_rounded,
              onPressed: busy ? null : pay,
            ),
            Text(
              'يُسجَّل مصروفاً على وردية الصندوق المفتوحة ويُطبع إيصال.',
              style: UType.caption(color: c.inkMuted),
            ),
          ],
        ),
      ],
    );
  }
}

/// التفصيل يتحدث مع كتابة المبالغ وتغيير العملة.
class _LiveBreakdown extends StatelessWidget {
  const _LiveBreakdown(this.p);

  final SalaryPreview p;

  @override
  Widget build(BuildContext context) {
    final form = context.read<AppFormCubit>();
    final syp = context.select<AppFormCubit, bool>((f) => f.state.values[PayrollActions.currency] == 'SYP');
    final controllers = [
      for (final k in const [PayrollActions.bonus, PayrollActions.deductions, PayrollActions.advance]) form.text(k),
    ];
    return ListenableBuilder(
      listenable: Listenable.merge(controllers),
      builder: (context, _) {
        final net = PayrollActions.netOf(p, form);
        final rate = p.exchangeRate;
        return SalaryBreakdown(
          lines: [
            (label: 'الراتب الأساسي', usd: p.baseUsd, sign: ''),
            (label: 'العمولة', usd: p.commissionUsd, sign: '+'),
            (label: 'المكافأة', usd: PayrollActions.amountOf(form.value(PayrollActions.bonus)), sign: '+'),
            (label: 'الخصومات', usd: PayrollActions.amountOf(form.value(PayrollActions.deductions)), sign: '−'),
            if (p.openAdvancesUsd > 0)
              (label: 'خصم السلف', usd: PayrollActions.amountOf(form.value(PayrollActions.advance)), sign: '−'),
          ],
          netLabel: 'الصافي (تقديري)',
          net: net,
          note: !syp
              ? null
              : rate == null
              ? 'لا سعر صرف معتمد: الصرف بالليرة يُرفض.'
              : 'يعادل ${Formatters.ltr(Formatters.syp(net * rate))} بسعر اليوم',
        );
      },
    );
  }
}
