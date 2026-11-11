import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../memberships/presentation/widgets/membership_actions.dart' show openReceipt;
import '../../domain/models/payroll_models.dart';
import '../bloc/payroll_cubits.dart';

/// جدول السلف: الموظف، التاريخ، المبلغ، المخصوم بشريط، المتبقي، الملاحظة، الحالة، والإيصال.
/// الفلاتر: الحالة برقائق ("الكل" مبدئياً) والموظف.
class AdvancesTable extends StatelessWidget {
  const AdvancesTable({super.key, required this.staff, required this.onAdd});

  final List<PayrollStaff> staff;
  final VoidCallback onAdd;

  static const statuses = <FormOption<String>>[
    (value: 'open', label: 'مفتوحة'),
    (value: 'settled', label: 'مسددة'),
    (value: 'cancelled', label: 'ملغاة'),
  ];

  @override
  Widget build(BuildContext context) {
    final list = context.read<AdvancesCubit>();
    final state = context.watch<AdvancesCubit>().state;
    final q = state.query;
    return PagedTable<StaffAdvance>(
      state: state,
      noun: 'سلفة',
      minWidth: AppSize.advancesTableMin,
      onPage: list.goTo,
      onRetry: list.load,
      onClearFilters: list.clearFilters,
      header: FilterBar(
        search: '',
        onSearch: null,
        filters: [
          if (staff.length > 1)
            FilterMenu<int>(
              label: 'الموظف',
              value: q.filter(AdvanceFilters.staff) as int?,
              options: [for (final s in staff) (value: s.id, label: s.name)],
              onChanged: (v) => list.filter(AdvanceFilters.staff, v),
            ),
        ],
        chips: FilterChoiceChips<String>(
          semanticsLabel: 'حالة السلفة',
          options: statuses,
          value: q.filter(AdvanceFilters.status) as String?,
          onChanged: (v) => list.filter(AdvanceFilters.status, v),
        ),
        onClear: q.hasFilters ? list.clearFilters : null,
      ),
      empty: EmptyState(
        icon: Icons.request_quote_rounded,
        title: 'لا سلف بعد',
        message: 'اصرف سلفة لموظف من الصندوق، وتُخصم من راتبه عند صرفه.',
        actionLabel: 'صرف سلفة',
        onAction: onAdd,
      ),
      mobileItem: (context, x) => _MobileAdvance(x),
      columns: [
        TableCol(
          'الموظف',
          flex: 3,
          cell: (c, x) => Text(x.staffName, style: UType.body(color: c.colors.ink).weight(600)),
        ),
        TableCol(
          'التاريخ',
          width: AppSize.ledgerDateCol,
          cell: (c, x) => LtrText(Formatters.date(x.createdAt, fromUtc: true), style: UType.label(color: c.colors.ink)),
        ),
        TableCol(
          'المبلغ',
          flex: 2,
          cell: (c, x) => LtrText(Formatters.usd(x.amountUsd), style: UType.body(color: c.colors.ink)),
        ),
        TableCol('المخصوم', flex: 3, cell: (c, x) => _Deducted(x)),
        TableCol('المتبقي', flex: 2, cell: (c, x) => _Remaining(x)),
        TableCol(
          'ملاحظة',
          flex: 3,
          cell: (c, x) => Text(
            x.note ?? '—',
            style: UType.label(color: c.colors.inkMuted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TableCol('الحالة', flex: 2, cell: (c, x) => _Status(x)),
        TableCol('', width: AppSize.receiptCol, cell: (c, x) => _Receipt(x)),
      ],
    );
  }
}

class _Deducted extends StatelessWidget {
  const _Deducted(this.x);

  final StaffAdvance x;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.s1,
      children: [
        Text(
          '${Formatters.ltr(Formatters.usd(x.deductedUsd))} من ${Formatters.ltr(Formatters.usd(x.amountUsd))}',
          style: UType.label(color: c.ink),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSize.usageBar),
          child: ClipRRect(
            borderRadius: AppRadius.fullAll,
            child: LinearProgressIndicator(
              value: x.deductedShare,
              minHeight: AppSpace.s1,
              color: c.success,
              backgroundColor: c.surfaceAlt,
            ),
          ),
        ),
      ],
    );
  }
}

class _Remaining extends StatelessWidget {
  const _Remaining(this.x);

  final StaffAdvance x;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LtrText(
      Formatters.usd(x.remainingUsd),
      style: UType.body(color: x.remainingUsd > 0 && x.status == 'open' ? c.warningInk : c.inkMuted).weight(600),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status(this.x);

  final StaffAdvance x;

  @override
  Widget build(BuildContext context) {
    final s = PayrollTexts.advanceStatus(x.status);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: FittedBox(fit: BoxFit.scaleDown, child: StatusBadge(s.label, tone: s.tone)),
    );
  }
}

class _Receipt extends StatelessWidget {
  const _Receipt(this.x);

  final StaffAdvance x;

  @override
  Widget build(BuildContext context) {
    final tx = x.transactionId;
    return tx == null
        ? const SizedBox.shrink()
        : TextButton(onPressed: () => openReceipt(tx), child: const Text('الإيصال'));
  }
}

class _MobileAdvance extends StatelessWidget {
  const _MobileAdvance(this.x);

  final StaffAdvance x;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s2,
      children: [
        Row(
          spacing: AppSpace.s2,
          children: [
            Expanded(
              child: Text(
                x.staffName,
                style: UType.body(color: c.ink).weight(600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _Status(x),
          ],
        ),
        Row(
          spacing: AppSpace.s3,
          children: [
            LtrText(Formatters.date(x.createdAt, fromUtc: true), style: UType.caption(color: c.inkMuted)),
            const Spacer(),
            Text('المتبقي', style: UType.caption(color: c.inkMuted)),
            _Remaining(x),
          ],
        ),
        _Deducted(x),
        if (x.note != null) Text(x.note!, style: UType.caption(color: c.inkMuted)),
        Align(alignment: AlignmentDirectional.centerEnd, child: _Receipt(x)),
      ],
    );
  }
}
