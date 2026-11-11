import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../../memberships/presentation/widgets/cash_fields.dart';
import '../../../notifications/presentation/bloc/unread_count_cubit.dart';
import '../../data/repo/payroll_repository.dart';
import '../../domain/models/payroll_models.dart';

/// صرف الراتب والسلفة: كلاهما حركة خروج من صندوق الفرع بإيصال (`Idempotency-Key`)، و `CASH_SESSION_REQUIRED`
/// يظهر بزر "فتح الصندوق" (`FormErrorBanner`).
abstract final class PayrollActions {
  static PayrollRepository get _repo => sl<PayrollRepository>();

  static const bonus = 'bonus_usd',
      deductions = 'deductions_usd',
      advance = 'advance_deduction_usd',
      currency = 'currency',
      note = 'note',
      staff = 'staff_member_id',
      amount = 'amount';

  static num amountOf(Object? v) => num.tryParse('${v ?? ''}'.replaceAll(',', '').trim()) ?? 0;

  /// الصافي **تقديراً** مع الكتابة: المقترح من الخادم (الأساسي + العمولة) + المكافأة − الخصومات − خصم السلف.
  static num netOf(SalaryPreview p, AppFormCubit f) =>
      p.suggestedNetUsd + amountOf(f.value(bonus)) - amountOf(f.value(deductions)) - amountOf(f.value(advance));

  /// `{period, currency, bonus_usd?, deductions_usd?, advance_deduction_usd?, note?}`: الأساسي والعمولة يحسبهما الخادم.
  static Json salaryBody(AppFormCubit f, String period) => {
    'period': period,
    currency: f.value(currency) ?? 'USD',
    for (final k in const [bonus, deductions, advance])
      if (amountOf(f.value(k)) case final a when a > 0) k: a,
    note: ?_text(f.value(note)),
  };

  /// يتحقق من حقول اللوحة ثم يؤكد بنافذة (صندوق الفرع حين يلزم) ويصرف. يرجع true إن صُرف.
  static Future<bool> paySalary(BuildContext context, SalaryPreview p, AppFormCubit form) async {
    final valid = await form.submit((_) async => const ApiSuccess<void>(null));
    if (valid is! ApiSuccess || !context.mounted) return false;
    final body = salaryBody(form, p.period);
    final branch = CashBranch.of(context, fallback: p.staff.branchId);
    final keeper = IdempotencyKeeper();
    final done = await FormDialog.show<SalaryPayment>(
      context,
      title: 'صرف راتب ${p.staff.name}',
      icon: Icons.payments_rounded,
      message:
          'راتب ${PayrollTexts.month(p.period)} بصافٍ ${Formatters.ltr(Formatters.usd(netOf(p, form)))} تقديراً '
          '(الخادم يثبّت المبلغ). يُسجَّل مصروفاً على وردية الصندوق المفتوحة ويُطبع إيصال، ولا يُصرف الشهر مرتين.',
      initial: branch.initial,
      submitLabel: 'صرف الراتب',
      fields: branch.needsField ? (_) => FormColumn(children: [branch.field()]) : null,
      onSubmit: (f) {
        final b = {...body, CashBranch.key: ?branch.idOf(f)};
        return _repo.paySalary(p.staff.id, b, idempotencyKey: keeper.keyFor(b));
      },
    );
    if (done == null || !context.mounted) return false;
    unawaited(context.read<UnreadCountCubit>().refresh());
    return true;
  }

  /// "صرف سلفة": الموظف، المبلغ وعملته، ملاحظة، وصندوق الفرع حين يلزم. يرجع true إن صُرفت.
  static Future<bool> addAdvance(BuildContext context, List<PayrollStaff> staffList) async {
    if (staffList.isEmpty) {
      AppSnackbar.show('لا موظفين فعّالين. أضف الموظف من "الموظفون والحسابات" أولاً.');
      return false;
    }
    final branch = CashBranch.of(context, fallback: context.read<BranchScopeCubit>().state.mainId);
    final keeper = IdempotencyKeeper();
    final c = context.colors;
    final done = await FormDialog.show<StaffAdvance>(
      context,
      title: 'صرف سلفة',
      icon: Icons.request_quote_rounded,
      initial: {currency: 'USD', ...branch.initial},
      submitLabel: 'صرف السلفة',
      fields: (_) => FormColumn(
        children: [
          FormDropdown<int>(
            staff,
            label: 'الموظف',
            required: true,
            hint: 'اختر الموظف',
            options: [for (final s in staffList) (value: s.id, label: s.name)],
          ),
          FormText(
            amount,
            label: 'المبلغ',
            required: true,
            ltr: true,
            hint: '0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: Validators.all([Validators.amount(message: 'اكتب المبلغ بالأرقام.'), _positive]),
          ),
          const FormChoice<String>(
            currency,
            label: 'العملة',
            options: [(value: 'USD', label: 'بالدولار'), (value: 'SYP', label: 'بالليرة')],
          ),
          const FormText(note, label: 'ملاحظة', hint: 'مثلاً: سلفة طارئة'),
          if (branch.needsField) branch.field(),
          Text(
            'تُسجَّل حركة خروج على وردية الصندوق المفتوحة ويُطبع إيصال. السلفة لا تُحسب مصروفاً؛ تُخصم من الراتب عند صرفه.',
            style: UType.caption(color: c.inkMuted),
          ),
        ],
      ),
      onSubmit: (f) {
        final body = {
          staff: f.value(staff),
          currency: f.value(currency) ?? 'USD',
          amount: amountOf(f.value(amount)),
          note: ?_text(f.value(note)),
          CashBranch.key: ?branch.idOf(f),
        };
        return _repo.addAdvance(body, idempotencyKey: keeper.keyFor(body));
      },
    );
    if (done == null || !context.mounted) return false;
    unawaited(context.read<UnreadCountCubit>().refresh());
    return true;
  }

  static String? _positive(String? v) => amountOf(v) <= 0 ? 'اكتب مبلغاً أكبر من صفر.' : null;

  static String? _text(Object? v) {
    final s = '${v ?? ''}'.trim();
    return s.isEmpty ? null : s;
  }
}
