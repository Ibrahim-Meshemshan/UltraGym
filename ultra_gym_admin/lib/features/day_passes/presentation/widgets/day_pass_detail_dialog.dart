import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../members/domain/models/member_models.dart';
import '../../data/repo/day_passes_repository.dart';
import '../../domain/models/day_pass_models.dart';
import '../bloc/day_passes_cubit.dart';
import 'day_pass_sold.dart';
import 'day_passes_table.dart';

/// تفاصيل دخول يومي (`GET day-passes/{id}`): البيانات والدفعات بإيصالاتها، و "إلغاء الدخول" للمالك
/// (`POST …/cancel {reason}` يعكس الدفعات بالوردية المفتوحة). ترجع true إن أُلغي لتحديث السجل.
abstract final class DayPassDetailDialog {
  static Future<bool> show(BuildContext context, int id) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider(create: (_) => DayPassDetailCubit(sl(), id)..load(), child: const _Body()),
    );
    return changed ?? false;
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cubit = context.watch<DayPassDetailCubit>();
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpace.s4),
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.hero))),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSize.dialog),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.s6),
          child: SliceView<DayPass>(
            slice: cubit.state,
            loading: const DetailsShimmer(),
            onRetry: cubit.load,
            builder: (context, p) => _Content(p),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content(this.p);

  final DayPass p;

  Future<void> _cancel(BuildContext context) async {
    final cubit = context.read<DayPassDetailCubit>();
    final keeper = IdempotencyKeeper();
    final done = await FormDialog.show<DayPass>(
      context,
      title: 'إلغاء الدخول اليومي',
      icon: Icons.block_rounded,
      danger: true,
      message: p.transactions.isEmpty
          ? 'يُلغى دخول ${p.name}.'
          : 'يُلغى دخول ${p.name} وتُعكس دفعاته بإيصالات عكسية بالوردية المفتوحة.',
      submitLabel: 'إلغاء الدخول',
      successMessage: 'تم إلغاء الدخول اليومي.',
      fields: (_) => FormColumn(
        children: [
          FormText('reason', label: 'السبب', required: true, validator: Validators.required('اكتب سبب الإلغاء.')),
        ],
      ),
      onSubmit: (form) {
        final reason = '${form.value('reason') ?? ''}'.trim();
        return sl<DayPassesRepository>().cancel(p.id, reason, idempotencyKey: keeper.keyFor({'reason': reason}));
      },
    );
    if (done == null || !context.mounted) return;
    cubit.patch((_) => done.data);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final owner = context.select<AuthBloc, bool>((b) => b.state.session?.isClubOwner ?? false);
    final gender = MemberFilters.genders.where((g) => g.value == p.gender).firstOrNull?.label;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s4,
      children: [
        Row(
          children: [
            Expanded(child: DayPassBuyerCell(p)),
            AppSpace.gap2,
            DayPassBadge(p),
          ],
        ),
        if (p.isCancelled)
          Container(
            padding: const EdgeInsets.all(AppSpace.s3),
            decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: AppRadius.fieldAll),
            child: Text(
              [
                'أُلغي',
                if (p.cancelledAt != null) Formatters.ltr(Formatters.dateTime(p.cancelledAt)),
                if (p.cancellationReason != null) 'السبب: ${p.cancellationReason}',
              ].join(' · '),
              style: UType.label(color: c.inkMuted),
            ),
          ),
        Wrap(
          spacing: AppSpace.s6,
          runSpacing: AppSpace.s3,
          children: [
            _Fact('السعر', p.isFree ? 'مجاني' : Formatters.usd(p.priceUsd), ltr: !p.isFree),
            _Fact('المدفوع', Formatters.usd(p.paidUsd), ltr: true),
            _Fact('الفرع', p.branchName ?? '—'),
            _Fact('يوم العمل', Formatters.date(p.businessDate), ltr: true),
            _Fact('الوقت', Formatters.time(p.checkedInAt), ltr: true),
            if (gender != null) _Fact('الجنس', gender),
            _Fact('سجّله', p.createdBy ?? '—'),
          ],
        ),
        if (p.notes case final n?) Text('ملاحظات: $n', style: UType.label(color: c.inkMuted)),
        if (p.transactions.isNotEmpty) DayPassReceipts(p.transactions),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: AppSpace.s2,
          runSpacing: AppSpace.s2,
          children: [
            if (owner && !p.isCancelled)
              UGButton(
                label: 'إلغاء الدخول',
                icon: Icons.block_rounded,
                kind: UButtonKind.danger,
                onPressed: () => _cancel(context),
              ),
            UGButton(label: 'إغلاق', kind: UButtonKind.secondary, onPressed: () => Navigator.of(context).pop(false)),
          ],
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value, {this.ltr = false});

  final String label, value;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = UType.body(color: c.ink).weight(600);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: UType.caption(color: c.inkMuted)),
        if (ltr) LtrText(value, style: style) else Text(value, style: style),
      ],
    );
  }
}
