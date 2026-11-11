import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../domain/models/dashboard_models.dart';
import '../bloc/dashboard_cubit.dart';
import '../widgets/dashboard_body.dart';
import '../widgets/dashboard_hero.dart';

/// الرئيسية (`Dashboard.html`): `GET club-admin/dashboard` بالفرع المختار بالشريط العلوي.
/// تنتظر استقرار الفروع (لا طلب مرتين: "كل الفروع" ثم الفرع الوحيد)، وتغيير الفرع ينشئ Cubit جديداً.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final (ready, branchId) = context.select<BranchScopeCubit, (bool, int?)>(
      (c) => (!c.state.branches.isFirstLoad, c.state.branchId),
    );
    if (!ready) return const AppPage(children: [DashboardHero(), DashboardShimmer()]);
    return BlocProvider(
      key: ValueKey(branchId),
      create: (_) => sl<DashboardCubit>(param1: branchId)..load(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final summary = context.select<DashboardCubit, Slice<DashboardData>>((c) => c.state.summary);
    return AppPage(
      children: [
        DashboardHero(data: summary.data),
        SliceView(
          slice: summary,
          loading: const DashboardShimmer(),
          onRetry: context.read<DashboardCubit>().load,
          builder: (context, data) => DashboardBody(data: data),
        ),
      ],
    );
  }
}
