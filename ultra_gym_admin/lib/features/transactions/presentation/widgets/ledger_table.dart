import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../domain/models/transaction_models.dart';
import '../bloc/transactions_cubit.dart';
import 'ledger_cells.dart';

/// جدول الدفتر (`Transactions.html`): الإيصال، النوع، المبلغ بعملته، بالدولار، التصنيف، مرتبطة بـ، يوم العمل،
/// المنفّذ، والإجراءات. الصف يفتح التفاصيل.
class LedgerTable extends StatelessWidget {
  const LedgerTable({super.key, required this.onOpen, required this.onReceipt, required this.onReverse});

  final void Function(LedgerEntry e) onOpen, onReceipt, onReverse;

  @override
  Widget build(BuildContext context) {
    final list = context.read<LedgerCubit>();
    final state = context.watch<LedgerCubit>().state;
    final owner = context.select<AuthBloc, bool>((b) => b.state.session?.isClubOwner ?? false);
    Widget muted(BuildContext c, String v) => Text(
      v,
      style: UType.label(color: c.colors.inkMuted),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    return PagedTable<LedgerEntry>(
      state: state,
      noun: 'حركة',
      minWidth: AppSize.ledgerTableMin,
      onPage: list.goTo,
      onRetry: list.load,
      onRowTap: onOpen,
      onClearFilters: list.clearFilters,
      header: _Filters(query: state.query),
      empty: const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'لا حركات بهذه الفترة',
        message: 'كل دفعة ومصروف وإيراد يظهر هنا. سجّل مصروفاً أو إيراداً من زر «تسجيل إيراد أو مصروف».',
      ),
      mobileItem: (context, e) => _MobileCard(e, owner: owner, onReceipt: onReceipt, onReverse: onReverse),
      columns: [
        TableCol('الإيصال', width: AppSize.receiptNumberCol, cell: (c, e) => ReceiptNumber(e)),
        TableCol('النوع', flex: 3, cell: (c, e) => TransactionTypeBadge(e)),
        TableCol('المبلغ', flex: 3, cell: (c, e) => LedgerAmount(e)),
        TableCol(
          'بالدولار',
          flex: 2,
          cell: (c, e) => LtrText(Formatters.usd(e.amountUsd), style: UType.label(color: c.colors.inkMuted)),
        ),
        TableCol('التصنيف', flex: 2, cell: (c, e) => muted(c, e.categoryName ?? '—')),
        TableCol('مرتبطة بـ', flex: 3, cell: (c, e) => LedgerLink(e)),
        TableCol(
          'يوم العمل',
          width: AppSize.ledgerDateCol,
          cell: (c, e) => LtrText(Formatters.date(e.businessDate), style: UType.label(color: c.colors.inkMuted)),
        ),
        TableCol('المنفّذ', flex: 3, cell: (c, e) => muted(c, e.createdBy ?? '—')),
        TableCol(
          'إجراءات',
          width: AppSize.ledgerActionsCol,
          cell: (c, e) =>
              LedgerRowActions(e, owner: owner, onReceipt: () => onReceipt(e), onReverse: () => onReverse(e)),
        ),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.query});

  final ListQuery query;

  @override
  Widget build(BuildContext context) {
    final list = context.read<LedgerCubit>();
    final finance = context.select<AuthBloc, bool>((b) => b.state.session?.canViewFinance ?? false);
    // فلتر الفرع داخل الجدول فقط حين يكون الشريط العلوي على "كل الفروع".
    final branches = context.select<BranchScopeCubit, List<FormOption<int>>>(
      (c) => c.state.branchId != null || !c.state.canChoose
          ? const []
          : [for (final b in c.state.active) (value: b.id, label: b.name)],
    );
    return FilterBar(
      search: query.search,
      hint: 'رقم الإيصال أو الوصف',
      onSearch: list.search,
      onClear: query.hasFilters ? list.clearFilters : null,
      filters: [
        FilterDateRange(
          from: query.filter(TransactionFilters.from) as DateTime?,
          to: query.filter(TransactionFilters.to) as DateTime?,
          emptyLabel: 'آخر 31 يوماً',
          onChanged: (from, to) =>
              list.query(query.withFilter(TransactionFilters.from, from).withFilter(TransactionFilters.to, to)),
        ),
        FilterMenu<String>(
          label: 'النوع',
          options: TransactionFilters.types(finance: finance),
          value: query.filter(TransactionFilters.type) as String?,
          onChanged: (v) => list.filter(TransactionFilters.type, v),
        ),
        FilterMenu<String>(
          label: 'العملة',
          options: TransactionFilters.currencies,
          value: query.filter(TransactionFilters.currency) as String?,
          onChanged: (v) => list.filter(TransactionFilters.currency, v),
        ),
        if (branches.isNotEmpty)
          FilterMenu<int>(
            label: 'الفرع',
            options: branches,
            value: query.filter(TransactionFilters.branchId) as int?,
            onChanged: (v) => list.filter(TransactionFilters.branchId, v),
          ),
        FilterToggle(
          label: 'بلا المعكوسة',
          value: query.filter(TransactionFilters.includeReversed) == false,
          onChanged: (on) => list.filter(TransactionFilters.includeReversed, on ? false : null),
        ),
      ],
    );
  }
}

class _MobileCard extends StatelessWidget {
  const _MobileCard(this.e, {required this.owner, required this.onReceipt, required this.onReverse});

  final LedgerEntry e;
  final bool owner;
  final void Function(LedgerEntry e) onReceipt, onReverse;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final muted = UType.caption(color: c.inkMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s2,
      children: [
        Row(children: [TransactionTypeBadge(e), const Spacer(), LedgerAmount(e)]),
        Row(
          children: [
            Expanded(child: ReceiptNumber(e, strong: false)),
            LtrText(Formatters.date(e.businessDate), style: muted),
          ],
        ),
        Text(
          [e.categoryName, e.playerName ?? e.staffName, e.createdBy].nonNulls.join(' · '),
          style: muted,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: LedgerRowActions(e, owner: owner, onReceipt: () => onReceipt(e), onReverse: () => onReverse(e)),
        ),
      ],
    );
  }
}
