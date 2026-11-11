import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../../notifications/presentation/bloc/unread_count_cubit.dart';
import '../../domain/models/transaction_models.dart';
import '../bloc/transactions_cubit.dart';
import '../widgets/finance_tabs.dart';
import '../widgets/ledger_stats.dart';
import '../widgets/ledger_table.dart';
import '../widgets/transaction_actions.dart';
import '../widgets/transaction_detail_dialog.dart';

/// دفتر الحركات (`Transactions.html`): تبويبات المالية و "تسجيل إيراد أو مصروف"، مجاميع الفلتر الحالي، ثم الدفتر
/// بفلاتره. الصف يفتح التفاصيل، والعكس للمالك بسبب إلزامي. الحركات لا تُحذف ولا تُعدّل.
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final (ready, branchId) = context.select<BranchScopeCubit, (bool, int?)>(
      (c) => (!c.state.branches.isFirstLoad, c.state.branchId),
    );
    if (!ready) return const AppPage(children: [StatsShimmer(), TableShimmer(columns: 8)]);
    final query = ledgerQueryFrom(GoRouterState.of(context).uri.queryParameters);
    return BlocProvider(
      key: ValueKey((branchId, query)),
      create: (_) => sl<LedgerCubit>(param1: (branchId: branchId, query: query))..load(),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  Future<void> _changed(BuildContext context) async {
    final list = context.read<LedgerCubit>();
    unawaited(context.read<UnreadCountCubit?>()?.refresh());
    await list.refresh(keepPage: true);
  }

  Future<void> _record(BuildContext context) async {
    final main = context.read<BranchScopeCubit>().state.mainId;
    if (await TransactionActions.record(context, fallbackBranch: main) != null && context.mounted) {
      await _changed(context);
    }
  }

  Future<void> _open(BuildContext context, LedgerEntry e) async {
    if (await TransactionDetailDialog.show(context, e.id) && context.mounted) await _changed(context);
  }

  Future<void> _reverse(BuildContext context, LedgerEntry e) async {
    if (await TransactionActions.reverse(context, e) != null && context.mounted) await _changed(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDefault = context.select<LedgerCubit, bool>(
      (l) => asJson(l.state.slice.data?.meta['period']).flag('is_default'),
    );
    final button = UGButton(label: 'تسجيل إيراد أو مصروف', icon: Icons.add_rounded, onPressed: () => _record(context));
    return AppPage(
      children: [
        LayoutBuilder(
          builder: (context, box) => box.maxWidth >= AppSize.splitMin
              ? Row(
                  children: [
                    const Expanded(child: FinanceTabs(selected: 1)),
                    button,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpace.s3,
                  children: [const FinanceTabs(selected: 1), button],
                ),
        ),
        const LedgerStats(),
        LedgerTable(
          onOpen: (e) => _open(context, e),
          onReceipt: (e) => TransactionActions.receipt(e.id),
          onReverse: (e) => _reverse(context, e),
        ),
        Text(
          isDefault
              ? 'الحركات لا تُحذف ولا تُعدّل؛ الخطأ يُصحَّح بحركة عكس يسجّلها المالك مع سبب. '
                    'بلا فترة محددة يعرض الدفتر آخر 31 يوماً.'
              : 'الحركات لا تُحذف ولا تُعدّل؛ الخطأ يُصحَّح بحركة عكس يسجّلها المالك مع سبب.',
          style: UType.caption(color: c.inkMuted),
        ),
      ],
    );
  }
}
