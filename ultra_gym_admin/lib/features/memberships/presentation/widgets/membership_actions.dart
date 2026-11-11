import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../data/repo/membership_detail_repository.dart';
import '../../domain/models/membership_detail_models.dart';
import '../bloc/membership_detail_cubit.dart';
import 'cash_fields.dart';

/// عمليات صفحة الاشتراك: كل واحدة بنافذة (`FormDialog`) ثم رسالة الخادم وتحديث صامت.
/// المال بـ `IdempotencyKeeper` (نفس الجسم = نفس المفتاح عند إعادة المحاولة).

MembershipDetailRepository get _repo => sl<MembershipDetailRepository>();

String _usd(double v) => Formatters.ltr(Formatters.usd(v));

/// سداد الدين `POST memberships/{id}/payments`: بأي مبلغ ≤ الدين، بالعملتين أو إحداهما.
Future<void> payDebt(BuildContext context, MembershipDetail d) async {
  final cubit = context.read<MembershipDetailCubit>();
  final branch = CashBranch.of(context, fallback: d.branchId);
  final keeper = IdempotencyKeeper();
  final m = d.membership;
  final done = await FormDialog.show<void>(
    context,
    title: 'سداد دين ${m.playerName}',
    icon: Icons.payments_rounded,
    message: 'الدين ${_usd(m.dueUsd)} (${Formatters.ltr(Formatters.syp(d.dueSyp))}). سجّل المبلغ المقبوض بعملته.',
    initial: branch.initial,
    submitLabel: 'تسجيل الدفعة',
    fields: (form) => FormColumn(children: [const PaymentFields(), if (branch.needsField) branch.field()]),
    onSubmit: (form) async {
      final payments = PaymentFields.linesOf(form);
      if (payments.isEmpty) return PaymentFields.noAmount;
      final body = {'payments': payments, CashBranch.key: ?branch.idOf(form)};
      return _repo.pay(d.id, body, idempotencyKey: keeper.keyFor(body));
    },
  );
  if (done != null) await cubit.refresh();
}

/// تجميد `POST …/freeze {days, reason}`: يبدأ اليوم (أو يوم البداية) ويمدد النهاية بعدد الأيام.
Future<void> freezeMembership(BuildContext context, MembershipDetail d) async {
  final cubit = context.read<MembershipDetailCubit>();
  final f = d.freezes;
  final done = await FormDialog.show<void>(
    context,
    title: 'تجميد الاشتراك',
    icon: Icons.ac_unit_rounded,
    message:
        'استُخدم ${f.used} من ${f.maxFreezes} مرات و ${f.daysUsed} من ${f.maxDays} يوماً. '
        'يبدأ التجميد اليوم وتمتد نهاية الاشتراك بعدد أيامه.',
    submitLabel: 'تجميد',
    fields: (form) => FormColumn(
      children: [
        FormText(
          'days',
          label: 'عدد أيام التجميد',
          required: true,
          ltr: true,
          keyboardType: TextInputType.number,
          validator: (v) => (int.tryParse(v?.trim() ?? '') ?? 0) < 1 ? 'اكتب عدد الأيام (1 أو أكثر).' : null,
        ),
        const FormText('reason', label: 'السبب', hint: 'سفر، إصابة...'),
      ],
    ),
    onSubmit: (form) =>
        _repo.freeze(d.id, {'days': int.parse('${form.value('days')}'.trim()), 'reason': ?_text(form.value('reason'))}),
  );
  if (done != null) await cubit.refresh();
}

/// فك التجميد: الأيام غير المستخدمة ترجع للرصيد.
Future<void> unfreezeMembership(BuildContext context, MembershipDetail d) async {
  final cubit = context.read<MembershipDetailCubit>();
  final done = await FormDialog.confirm<void>(
    context,
    title: 'فك التجميد',
    message: 'يعود الاشتراك فعّالاً اليوم، والأيام غير المستخدمة ترجع لرصيد التجميد وتُقدَّم نهايته بقدرها.',
    confirmLabel: 'فك التجميد',
    icon: Icons.wb_sunny_outlined,
    danger: false,
    onConfirm: () => _repo.unfreeze(d.id),
  );
  if (done != null) await cubit.refresh();
}

/// إلغاء (للمالك) بسبب إلزامي واسترجاع اختياري ≤ المدفوع من صندوق الفرع.
Future<void> cancelMembership(BuildContext context, MembershipDetail d) async {
  final cubit = context.read<MembershipDetailCubit>();
  final branch = CashBranch.of(context, fallback: d.branchId);
  final keeper = IdempotencyKeeper();
  final paid = d.membership.paidUsd;
  final done = await FormDialog.show<void>(
    context,
    title: 'إلغاء الاشتراك',
    icon: Icons.cancel_outlined,
    danger: true,
    message: 'يبقى الاشتراك بالسجل بحالة "ملغى" مع السبب والتاريخ، ولا يمكن التراجع عن الإلغاء.',
    initial: branch.initial,
    submitLabel: 'إلغاء الاشتراك',
    fields: (form) => FormColumn(
      children: [
        FormText(
          'reason',
          label: 'سبب الإلغاء',
          required: true,
          maxLines: 3,
          validator: Validators.required('اكتب سبب الإلغاء.'),
        ),
        if (paid > 0) ...[
          const PaymentFields(usdLabel: 'استرجاع بالدولار (اختياري)', sypLabel: 'استرجاع بالليرة (اختياري)'),
          Text(
            'الحد الأقصى ${_usd(paid)} = المدفوع. الاسترجاع حركة خارجة من صندوق الفرع وتنقص المدفوع.',
            style: UType.caption(color: context.colors.inkMuted),
          ),
          if (branch.needsField) branch.field(label: 'صندوق الاسترجاع'),
        ],
      ],
    ),
    onSubmit: (form) {
      final refunds = paid > 0 ? PaymentFields.linesOf(form) : const <Json>[];
      final body = {
        'reason': '${form.value('reason')}'.trim(),
        if (refunds.isNotEmpty) ...{'refunds': refunds, CashBranch.key: ?branch.idOf(form)},
      };
      return _repo.cancel(d.id, body, idempotencyKey: keeper.keyFor(body));
    },
  );
  if (done != null) await cubit.refresh();
}

/// استهلاك جلسة يدوياً (حصة خاصة مثلاً) لاشتراك جلسات فعّال.
Future<void> consumeSession(BuildContext context, MembershipDetail d) async {
  final cubit = context.read<MembershipDetailCubit>();
  final branch = CashBranch.of(context, fallback: d.branchId);
  final keeper = IdempotencyKeeper();
  final left = d.membership.sessionsRemaining ?? 0;
  final done = await FormDialog.show<void>(
    context,
    title: 'تسجيل جلسة',
    icon: Icons.fitness_center_rounded,
    message: 'تُخصم جلسة واحدة. المتبقي الآن ${Formatters.count(left, 'جلسة', 'جلستان', 'جلسات', many: 'جلسة')}.',
    initial: branch.initial,
    submitLabel: 'تسجيل الجلسة',
    fields: (form) => FormColumn(
      children: [
        const FormText('note', label: 'ملاحظة', hint: 'حصة إضافية...'),
        if (branch.needsField) branch.field(label: 'الفرع'),
      ],
    ),
    onSubmit: (form) {
      final body = {'note': ?_text(form.value('note')), CashBranch.key: ?branch.idOf(form)};
      return _repo.consumeSession(d.id, body, idempotencyKey: keeper.keyFor(body));
    },
  );
  if (done != null) await cubit.refresh();
}

/// فاتورة الاشتراك PDF (أو صفحة HTML للطباعة إن لم يتوفر محرك PDF بالخادم).
Future<void> openInvoice(int id) => _open(_repo.invoice(id));

/// إيصال دفعة.
Future<void> openReceipt(int transactionId) => _open(_repo.receipt(transactionId));

Future<void> _open(Future<ApiResult<FileBlob>> request) async {
  switch (await request) {
    case ApiSuccess(:final data):
      await BlobOpener.open(data);
    case ApiFailure(:final failure):
      AppSnackbar.show(failure.message);
  }
}

String? _text(Object? v) {
  final s = '${v ?? ''}'.trim();
  return s.isEmpty ? null : s;
}
