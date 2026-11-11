import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../domain/models/cash_session_models.dart';
import '../bloc/cash_sessions_cubit.dart';
import 'cash_session_dialogs.dart';
import 'cash_session_panels.dart';

/// "الورديات السابقة" (`CashSessions.html`): المغلقة بالمتوقع والجرد وفرق كل عملة ومن أغلقها وتقريرها.
/// الصف يفتح تفاصيل الوردية.
class CashHistoryTable extends StatelessWidget {
  const CashHistoryTable({super.key, required this.onOpen});

  final void Function(CashSession s) onOpen;

  @override
  Widget build(BuildContext context) {
    final list = context.read<CashHistoryCubit>();
    final state = context.watch<CashHistoryCubit>().state;
    final showBranch = context.select<BranchScopeCubit, bool>((c) => c.state.branchId == null && c.state.canChoose);
    return PagedTable<CashSession>(
      state: state,
      noun: 'وردية',
      onPage: list.goTo,
      onRetry: list.load,
      onRowTap: onOpen,
      onClearFilters: list.clearFilters,
      header: _Filters(query: state.query),
      empty: const AppEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'لا ورديات مغلقة بعد',
        message: 'كل وردية تُغلق بالجرد تظهر هنا بفرقها وتقريرها.',
      ),
      mobileItem: (context, s) => _MobileCard(s, showBranch: showBranch),
      columns: [
        TableCol('الوردية', flex: 2, cell: (c, s) => _Number(s, showBranch: showBranch)),
        TableCol('يوم العمل', flex: 2, cell: (c, s) => _ltr(c, Formatters.date(s.businessDate))),
        TableCol('فتح · إغلاق', flex: 2, cell: (c, s) => _ltr(c, _span(s))),
        TableCol('المتوقع \$', flex: 2, cell: (c, s) => _ltr(c, Formatters.usd(s.expectedUsd), strong: true)),
        TableCol('الجرد \$', flex: 2, cell: (c, s) => _ltr(c, Formatters.usd(s.closingUsd), strong: true)),
        TableCol(
          'فرق الدولار',
          flex: 2,
          cell: (c, s) => _badge(CashDifferenceBadge(s.differenceUsd, usd: true, compact: true)),
        ),
        TableCol(
          'فرق الليرة',
          flex: 3,
          cell: (c, s) => _badge(CashDifferenceBadge(s.differenceSyp, usd: false, compact: true)),
        ),
        TableCol(
          'أغلقها',
          flex: 2,
          cell: (c, s) => Text(s.closedBy ?? '—', style: UType.label(color: c.colors.inkMuted)),
        ),
        TableCol('تقرير', width: AppSize.controlLg * 2, cell: (c, s) => _ReportButton(s.id)),
      ],
    );
  }

  /// "08:02 · 23:40" بتوقيت النادي.
  static String _span(CashSession s) => '${Formatters.time(s.openedAt)} · ${Formatters.time(s.closedAt)}';

  static Widget _ltr(BuildContext c, String v, {bool strong = false}) => LtrText(
    v,
    style: strong ? UType.body(color: c.colors.ink).weight(600) : UType.label(color: c.colors.inkMuted),
  );

  static Widget _badge(Widget b) => Align(alignment: AlignmentDirectional.centerStart, child: b);
}

class _Filters extends StatelessWidget {
  const _Filters({required this.query});

  final ListQuery query;

  @override
  Widget build(BuildContext context) {
    final list = context.read<CashHistoryCubit>();
    // فلتر الفرع داخل الجدول فقط حين يكون الشريط العلوي على "كل الفروع".
    final branches = context.select<BranchScopeCubit, List<FormOption<int>>>(
      (c) => c.state.branchId != null || !c.state.canChoose
          ? const []
          : [for (final b in c.state.active) (value: b.id, label: b.name)],
    );
    return FilterBar(
      search: '',
      onSearch: null,
      onClear: query.hasFilters ? list.clearFilters : null,
      filters: [
        FilterDateRange(
          from: query.filter(CashSessionFilters.from) as DateTime?,
          to: query.filter(CashSessionFilters.to) as DateTime?,
          emptyLabel: 'كل الأيام',
          onChanged: (from, to) =>
              list.query(query.withFilter(CashSessionFilters.from, from).withFilter(CashSessionFilters.to, to)),
        ),
        if (branches.isNotEmpty)
          FilterMenu<int>(
            label: 'الفرع',
            options: branches,
            value: query.filter(CashSessionFilters.branchId) as int?,
            onChanged: (v) => list.filter(CashSessionFilters.branchId, v),
          ),
        FilterToggle(
          label: 'بفرق فقط',
          value: query.filter(CashSessionFilters.withDifference) == true,
          onChanged: (v) => list.filter(CashSessionFilters.withDifference, v ? true : null),
        ),
      ],
    );
  }
}

class _Number extends StatelessWidget {
  const _Number(this.s, {required this.showBranch});

  final CashSession s;
  final bool showBranch;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LtrText('#${s.id}', style: UType.body(color: c.ink).weight(600)),
        if (showBranch && s.branchName != null)
          Text(
            s.branchName!,
            style: UType.caption(color: c.inkMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

class _ReportButton extends StatelessWidget {
  const _ReportButton(this.id);

  final int id;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: TextButton.icon(
      onPressed: () => CashSessionActions.report(id),
      icon: const Icon(Icons.download_rounded, size: AppSize.iconSm),
      label: const Text('PDF'),
    ),
  );
}

class _MobileCard extends StatelessWidget {
  const _MobileCard(this.s, {required this.showBranch});

  final CashSession s;
  final bool showBranch;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final muted = UType.caption(color: c.inkMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s2,
      children: [
        Row(
          children: [
            Expanded(child: _Number(s, showBranch: showBranch)),
            LtrText(Formatters.date(s.businessDate), style: muted),
          ],
        ),
        Wrap(
          spacing: AppSpace.s2,
          runSpacing: AppSpace.s1,
          children: [CashDifferenceBadge(s.differenceUsd, usd: true), CashDifferenceBadge(s.differenceSyp, usd: false)],
        ),
        Row(
          children: [
            Expanded(
              child: Text('الجرد ${Formatters.ltr(Formatters.usd(s.closingUsd))} · ${s.closedBy ?? '—'}', style: muted),
            ),
            _ReportButton(s.id),
          ],
        ),
      ],
    );
  }
}
