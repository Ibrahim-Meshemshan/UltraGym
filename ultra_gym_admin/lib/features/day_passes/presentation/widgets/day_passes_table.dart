import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../../members/presentation/widgets/member_cells.dart';
import '../../domain/models/day_pass_models.dart';
import '../bloc/day_passes_cubit.dart';

/// سجل الدخول اليومي: الوقت، الاسم (زائر أو عضو)، الفرع، السعر، الحالة، سجّله. الصف يفتح التفاصيل.
class DayPassesTable extends StatelessWidget {
  const DayPassesTable({super.key, required this.onOpen});

  final void Function(DayPass p) onOpen;

  @override
  Widget build(BuildContext context) {
    final list = context.read<DayPassesListCubit>();
    final state = context.watch<DayPassesListCubit>().state;
    return PagedTable<DayPass>(
      state: state,
      noun: 'دخولاً',
      onPage: list.goTo,
      onRetry: list.load,
      onRowTap: onOpen,
      onClearFilters: list.clearFilters,
      header: _Filters(query: state.query),
      empty: const EmptyState(
        icon: Icons.confirmation_number_outlined,
        title: 'لا دخول يومي بهذه الفترة',
        message: 'بِع دخولاً يومياً لزائر أو لعضو بلا اشتراك من زر «بيع دخول يومي».',
      ),
      mobileItem: (context, p) => _MobileCard(p),
      columns: [
        TableCol('الوقت', flex: 2, cell: (c, p) => _Time(p)),
        TableCol('الاسم', flex: 3, cell: (c, p) => DayPassBuyerCell(p)),
        TableCol('الفرع', flex: 3, cell: (c, p) => _muted(c, p.branchName ?? '—')),
        TableCol('السعر', flex: 2, cell: (c, p) => DayPassPriceText(p)),
        TableCol(
          'الحالة',
          flex: 2,
          cell: (c, p) => Align(alignment: AlignmentDirectional.centerStart, child: DayPassBadge(p)),
        ),
        TableCol('سجّله', flex: 2, cell: (c, p) => _muted(c, p.createdBy ?? '—')),
      ],
    );
  }

  static Widget _muted(BuildContext c, String v) => Text(v, style: UType.label(color: c.colors.inkMuted));
}

class _Filters extends StatelessWidget {
  const _Filters({required this.query});

  final ListQuery query;

  @override
  Widget build(BuildContext context) {
    final list = context.read<DayPassesListCubit>();
    // فلتر الفرع داخل الجدول فقط حين يكون الشريط العلوي على "كل الفروع".
    final branches = context.select<BranchScopeCubit, List<FormOption<int>>>(
      (c) => c.state.branchId != null || !c.state.canChoose
          ? const []
          : [for (final b in c.state.active) (value: b.id, label: b.name)],
    );
    return FilterBar(
      search: query.search,
      hint: 'الاسم أو الموبايل',
      onSearch: list.search,
      onClear: query.hasFilters ? list.clearFilters : null,
      filters: [
        FilterDateRange(
          from: query.filter(DayPassFilters.from) as DateTime?,
          to: query.filter(DayPassFilters.to) as DateTime?,
          emptyLabel: 'آخر 31 يوماً',
          onChanged: (from, to) =>
              list.query(query.withFilter(DayPassFilters.from, from).withFilter(DayPassFilters.to, to)),
        ),
        FilterMenu<String>(
          label: 'النوع',
          options: DayPassFilters.kinds,
          value: query.filter(DayPassFilters.kind) as String?,
          onChanged: (v) => list.filter(DayPassFilters.kind, v),
        ),
        if (branches.isNotEmpty)
          FilterMenu<int>(
            label: 'الفرع',
            options: branches,
            value: query.filter(DayPassFilters.branchId) as int?,
            onChanged: (v) => list.filter(DayPassFilters.branchId, v),
          ),
      ],
      chips: FilterChoiceChips<String>(
        semanticsLabel: 'حالة الدخول اليومي',
        options: DayPassFilters.statuses,
        value: query.filter(DayPassFilters.status) as String?,
        onChanged: (v) => list.filter(DayPassFilters.status, v),
      ),
    );
  }
}

class _Time extends StatelessWidget {
  const _Time(this.p);

  final DayPass p;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LtrText(Formatters.time(p.checkedInAt), style: UType.body(color: c.ink).weight(600)),
        LtrText(Formatters.date(p.businessDate), style: UType.caption(color: c.inkMuted)),
      ],
    );
  }
}

/// الاسم والنوع (زائر / عضو) والموبايل.
class DayPassBuyerCell extends StatelessWidget {
  const DayPassBuyerCell(this.p, {super.key});

  final DayPass p;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final muted = UType.caption(color: c.inkMuted);
    return Row(
      children: [
        MemberAvatar(p.name),
        AppSpace.gap3,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                p.name,
                style: UType.body(color: c.ink).weight(600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Wrap(
                spacing: AppSpace.s2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(DayPassLabels.kind(p.kind), style: muted),
                  if (p.phone case final phone?) LtrText(phone, style: muted),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// السعر ("مجاني" ليوم التجربة)، مشطوب للملغى.
class DayPassPriceText extends StatelessWidget {
  const DayPassPriceText(this.p, {super.key});

  final DayPass p;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = UType.body(color: p.isCancelled ? c.inkMuted : c.ink).weight(600);
    if (p.isFree) return Text('مجاني', style: style);
    return LtrText(
      Formatters.usd(p.priceUsd),
      style: p.isCancelled ? style.copyWith(decoration: TextDecoration.lineThrough) : style,
    );
  }
}

/// الحالة (فعّال / ملغى) و "دون اتصال" لما باعته محطة الاستقبال.
class DayPassBadge extends StatelessWidget {
  const DayPassBadge(this.p, {super.key});

  final DayPass p;

  @override
  Widget build(BuildContext context) {
    final l = DayPassLabels.status(p.status);
    return Wrap(
      spacing: AppSpace.s2,
      runSpacing: AppSpace.s1,
      children: [
        StatusBadge(l.text, tone: l.tone),
        if (p.isOffline) const StatusBadge('دون اتصال', tone: UTone.info),
      ],
    );
  }
}

class _MobileCard extends StatelessWidget {
  const _MobileCard(this.p);

  final DayPass p;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s2,
      children: [
        Row(
          children: [
            Expanded(child: DayPassBuyerCell(p)),
            AppSpace.gap2,
            DayPassPriceText(p),
          ],
        ),
        Row(
          children: [
            DayPassBadge(p),
            const Spacer(),
            LtrText(Formatters.dateTime(p.checkedInAt), style: UType.caption(color: c.inkMuted)),
          ],
        ),
        Text([p.branchName, p.createdBy].nonNulls.join(' · '), style: UType.caption(color: c.inkMuted)),
      ],
    );
  }
}
