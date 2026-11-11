import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../../transactions/presentation/widgets/finance_tabs.dart';
import '../bloc/cash_sessions_cubit.dart';
import '../widgets/cash_box_section.dart';
import '../widgets/cash_history_table.dart';

/// الصندوق (`CashSessions.html`): وردية فرع الشريط العلوي بأرصدتها الحية وأفعالها (أو كل فرع حين يكون على
/// "كل الفروع")، ثم "الورديات السابقة" المغلقة بفلاترها. الصف يفتح `/cash-sessions/{id}`.
class CashSessionsScreen extends StatelessWidget {
  const CashSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final (ready, branchId, ids) = context.select<BranchScopeCubit, (bool, int?, String)>(
      (c) => (
        !c.state.branches.isFirstLoad,
        c.state.branchId,
        c.state.branchId != null ? '${c.state.branchId}' : c.state.active.map((b) => b.id).join(','),
      ),
    );
    if (!ready) return const AppPage(children: [StatsShimmer(), TableShimmer(columns: 8)]);
    final boxes = [for (final v in ids.split(',')) ?int.tryParse(v)];
    final query = cashHistoryQueryFrom(GoRouterState.of(context).uri.queryParameters);
    return BlocProvider(
      key: ValueKey((branchId, query)),
      create: (_) => sl<CashHistoryCubit>(param1: (branchId: branchId, query: query))..load(),
      child: _Body(boxes: boxes),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.boxes});

  final List<int> boxes;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final history = context.read<CashHistoryCubit>();
    return AppPage(
      children: [
        const FinanceTabs(selected: 0),
        for (final id in boxes)
          CashBoxSection(
            key: ValueKey(id),
            branchId: id,
            showBranch: boxes.length > 1,
            onChanged: () => history.refresh(keepPage: true),
          ),
        Semantics(
          header: true,
          child: Text('الورديات السابقة', style: UType.h3(color: c.ink)),
        ),
        CashHistoryTable(onOpen: (s) => context.go(Routes.child(Routes.cashSessions, s.id))),
      ],
    );
  }
}
