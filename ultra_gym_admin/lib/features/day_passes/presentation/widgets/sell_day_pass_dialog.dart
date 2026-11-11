import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../../memberships/presentation/widgets/cash_fields.dart';
import '../../data/repo/day_passes_repository.dart';
import '../../domain/models/day_pass_models.dart';
import '../bloc/day_passes_cubit.dart';
import 'day_pass_sale_fields.dart';
import 'day_pass_sold.dart';

/// بيع دخول يومي (`POST day-passes` + `Idempotency-Key`): زائر أو عضو بلا اشتراك، فرع الدخول حين يكون الشريط
/// على "كل الفروع" (السعر يُطلب مع كل تغيير)، والدفع كاملاً بالعملتين. بعد البيع: الإيصالات و "بيع آخر".
/// ترجع true إن بيع شيء لتحديث السجل.
abstract final class SellDayPassDialog {
  static Future<bool> show(BuildContext context, {int? fallbackBranch}) async {
    final branch = CashBranch.of(context, fallback: fallbackBranch);
    final scope = context.read<BranchScopeCubit>();
    final sold = await showDialog<bool>(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          // النافذة فوق الهيكل: البحث عن عضو يحتاج فرع الشريط العلوي.
          BlocProvider.value(value: scope),
          BlocProvider(create: (_) => AppFormCubit(initial: branch.initial)),
          BlocProvider(create: (ctx) => DayPassSaleCubit(sl())..loadPrice(branch.idOf(ctx.read<AppFormCubit>()))),
        ],
        child: _Body(branch: branch),
      ),
    );
    return sold ?? false;
  }

  static const _noMember = ApiFailure<Never>(
    Failure(type: FailureType.validation, message: 'اختر العضو بالبحث بالاسم أو الموبايل.'),
  );

  static num? _num(Object? v) => num.tryParse('${v ?? ''}'.replaceAll(',', '').trim());

  static String? _text(Object? v) => switch ('${v ?? ''}'.trim()) {
    '' => null,
    final s => s,
  };
}

class _Body extends StatelessWidget {
  const _Body({required this.branch});

  final CashBranch branch;

  Future<void> _submit(BuildContext context) async {
    final form = context.read<AppFormCubit>();
    final cubit = context.read<DayPassSaleCubit>();
    final s = cubit.state;
    final price = s.price.data;
    final member = s.buyer == DayPassBuyer.member;
    // السعر المكتوب يُرسل فقط إن غيّره المالك (أو لا سعر محدد).
    final typed = price?.canChangePrice == true ? SellDayPassDialog._num(form.value(DayPassFields.price)) : null;
    final custom = typed != null && typed != price?.priceUsd;
    final due = custom ? typed : price?.priceUsd;
    final lines = PaymentFields.linesOf(form);
    final body = <String, Object?>{
      CashBranch.key: ?branch.idOf(form),
      if (member) 'player_id': s.player?.id,
      if (!member) ...{
        DayPassFields.name: SellDayPassDialog._text(form.value(DayPassFields.name)),
        DayPassFields.phone: ?SellDayPassDialog._text(form.value(DayPassFields.phone)),
        if (price?.genderRequired ?? false) DayPassFields.gender: ?form.value(DayPassFields.gender),
      },
      if (custom) DayPassFields.price: typed,
      if (lines.isNotEmpty) 'payments': lines,
      DayPassFields.notes: ?SellDayPassDialog._text(form.value(DayPassFields.notes)),
    };
    final r = await form.submit<DayPass>((_) async {
      if (member && s.player == null) return SellDayPassDialog._noMember;
      if (lines.isEmpty && (due ?? 0) > 0) return PaymentFields.noAmount;
      return sl<DayPassesRepository>().sell(body, idempotencyKey: cubit.keyFor(body));
    });
    if (r case ApiSuccess(:final data)) cubit.done(data);
  }

  /// سعر جديد (أول تحميل أو تغيير الفرع): يملأ حقل السعر للمالك ومبلغ الدولار.
  void _prefill(BuildContext context, DayPassPrice p) {
    final form = context.read<AppFormCubit>();
    final v = p.priceUsd == null ? '' : _plain(p.priceUsd!);
    if (p.canChangePrice) form.text(DayPassFields.price).text = v;
    form.text(PaymentFields.usd).text = (p.priceUsd ?? 0) > 0 ? v : '';
    form.text(PaymentFields.syp).clear();
  }

  static String _plain(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  void _again(BuildContext context) {
    final form = context.read<AppFormCubit>();
    for (final k in const [DayPassFields.name, DayPassFields.phone, DayPassFields.notes]) {
      form.text(k).clear();
    }
    final cubit = context.read<DayPassSaleCubit>();
    if (cubit.state.price.data case final p?) _prefill(context, p);
    cubit.again();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<DayPassSaleCubit>();
    final s = context.watch<DayPassSaleCubit>().state;
    final result = s.result;
    final canSell = s.price.data?.canSell ?? false;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(s.sold);
      },
      child: MultiBlocListener(
        listeners: [
          BlocListener<AppFormCubit, AppFormState>(
            listenWhen: (a, b) => a.values[CashBranch.key] != b.values[CashBranch.key],
            listener: (context, f) => cubit.loadPrice(f.values[CashBranch.key] as int?),
          ),
          BlocListener<DayPassSaleCubit, DayPassSaleState>(
            listenWhen: (a, b) => a.price.data != b.price.data && b.price.data != null,
            listener: (context, st) => _prefill(context, st.price.data!),
          ),
        ],
        child: Dialog(
          insetPadding: const EdgeInsets.all(AppSpace.s4),
          backgroundColor: c.surface,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.hero))),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSize.dialog),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpace.s6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpace.s4,
                children: [
                  Row(
                    children: [
                      const IconSlab(Icons.confirmation_number_rounded, size: AppSize.control),
                      AppSpace.gap3,
                      Expanded(
                        child: Text('بيع دخول يومي', style: UType.h2(color: c.ink)),
                      ),
                    ],
                  ),
                  if (result != null)
                    DayPassSold(
                      pass: result,
                      onAgain: () => _again(context),
                      onClose: () => Navigator.of(context).pop(true),
                    )
                  else ...[
                    const FormErrorBanner(),
                    const DayPassBuyerFields(),
                    if (branch.needsField) branch.field(label: 'فرع الدخول'),
                    const DayPassPriceBox(),
                    if (canSell) ...[
                      const PaymentFields(usdLabel: 'المدفوع بالدولار', sypLabel: 'المدفوع بالليرة'),
                      const FormText(DayPassFields.notes, label: 'ملاحظات', maxLines: 2),
                    ],
                    _Actions(enabled: canSell, onSubmit: () => _submit(context), sold: s.sold),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.enabled, required this.onSubmit, required this.sold});

  final bool enabled, sold;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final busy = context.select<AppFormCubit, bool>((f) => f.state.submitting);
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpace.s2,
      runSpacing: AppSpace.s2,
      children: [
        UGButton(
          label: 'إغلاق',
          kind: UButtonKind.ghost,
          onPressed: busy ? null : () => Navigator.of(context).pop(sold),
        ),
        UGButton(
          label: busy ? 'جارٍ البيع…' : 'تأكيد البيع',
          icon: Icons.check_rounded,
          onPressed: enabled && !busy ? onSubmit : null,
        ),
      ],
    );
  }
}
