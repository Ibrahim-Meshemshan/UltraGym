import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../domain/models/day_pass_models.dart';
import '../bloc/day_passes_cubit.dart';
import '../widgets/day_pass_detail_dialog.dart';
import '../widgets/day_passes_header.dart';
import '../widgets/day_passes_table.dart';
import '../widgets/sell_day_pass_dialog.dart';

/// الدخول اليومي (لا صفحة بالنموذج؛ على نمط `SellMembership.html`): سعر الفرع و "بيع دخول يومي"، مجاميع السجل
/// للفلتر الحالي، ثم السجل بفلاتره. الصف يفتح التفاصيل (الدفعات، الإيصالات، والإلغاء للمالك).
class DayPassesScreen extends StatelessWidget {
  const DayPassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final (ready, branchId, priceBranch) = context.select<BranchScopeCubit, (bool, int?, int?)>(
      (c) => (!c.state.branches.isFirstLoad, c.state.branchId, c.state.branchId ?? c.state.mainId),
    );
    if (!ready) return const AppPage(children: [StatsShimmer(), TableShimmer(columns: 6)]);
    final query = dayPassesQueryFrom(GoRouterState.of(context).uri.queryParameters);
    return MultiBlocProvider(
      key: ValueKey((branchId, query)),
      providers: [
        BlocProvider(create: (_) => sl<DayPassPriceCubit>(param1: priceBranch)..load()),
        BlocProvider(create: (_) => sl<DayPassesListCubit>(param1: (branchId: branchId, query: query))..load()),
      ],
      child: _Body(priceBranch: priceBranch),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.priceBranch});

  final int? priceBranch;

  Future<void> _sell(BuildContext context) async {
    final list = context.read<DayPassesListCubit>();
    if (await SellDayPassDialog.show(context, fallbackBranch: priceBranch)) await list.refresh(keepPage: true);
  }

  Future<void> _open(BuildContext context, DayPass p) async {
    final list = context.read<DayPassesListCubit>();
    if (await DayPassDetailDialog.show(context, p.id)) await list.refresh(keepPage: true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDefault = context.select<DayPassesListCubit, bool>(
      (l) => asJson(l.state.slice.data?.meta['period']).flag('is_default'),
    );
    return AppPage(
      children: [
        DayPassesHeader(onSell: () => _sell(context)),
        const DayPassesStats(),
        DayPassesTable(onOpen: (p) => _open(context, p)),
        Text(
          isDefault
              ? 'الدخول اليومي يُدفع كاملاً ويسجّل دخول العضو تلقائياً. بلا فترة محددة يعرض السجل آخر 31 يوماً.'
              : 'الدخول اليومي يُدفع كاملاً ويسجّل دخول العضو تلقائياً.',
          style: UType.caption(color: c.inkMuted),
        ),
      ],
    );
  }
}
