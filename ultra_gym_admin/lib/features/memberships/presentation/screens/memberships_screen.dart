import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../domain/models/memberships_models.dart';
import '../bloc/memberships_cubit.dart';
import '../widgets/membership_stats.dart';
import '../widgets/memberships_table.dart';

/// الاشتراكات والديون (`Memberships.html`): أرقام الرأس، ثلاثة تبويبات (الكل، عليها ديون، تنتهي قريباً)،
/// وجدول بفرع الشريط العلوي. التبويب والفلتر الأولي من رابط الصفحة (`membershipsArgsFrom`).
class MembershipsScreen extends StatelessWidget {
  const MembershipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final (ready, branchId) = context.select<BranchScopeCubit, (bool, int?)>(
      (c) => (!c.state.branches.isFirstLoad, c.state.branchId),
    );
    if (!ready) return const AppPage(children: [StatsShimmer(), TableShimmer(columns: 6)]);
    final initial = membershipsArgsFrom(GoRouterState.of(context).uri.queryParameters);
    return MultiBlocProvider(
      // رابط جديد بفلتر (من الرئيسية أو إشعار) وأنت بالصفحة = حالة جديدة بتبويبه.
      key: ValueKey((branchId, initial)),
      providers: [
        BlocProvider(create: (_) => ValueCubit<MembershipsTab>(initial.tab)),
        BlocProvider(create: (_) => sl<MembershipStatsCubit>(param1: branchId)..load()),
        BlocProvider(create: (_) => sl<PlanOptionsCubit>()..load()),
      ],
      child: BlocBuilder<ValueCubit<MembershipsTab>, MembershipsTab>(
        builder: (context, tab) => BlocProvider(
          key: ValueKey(tab),
          create: (_) => sl<MembershipsListCubit>(
            param1: (
              tab: tab,
              branchId: branchId,
              // الفلاتر لتبويب "الكل" فقط؛ الآخران ترتيبهما ثابت من الخادم.
              query: tab == MembershipsTab.all ? initial.query : const ListQuery(),
            ),
          )..load(),
          child: const AppPage(children: [MembershipStatsRow(), _Tabs(), MembershipsTable()]),
        ),
      ),
    );
  }
}

/// التبويبات: عدّادا الديون والقريبة من أرقام الرأس (تختفي إن فشلت).
class _Tabs extends StatelessWidget {
  const _Tabs();

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<ValueCubit<MembershipsTab>>();
    final stats = context.select<MembershipStatsCubit, MembershipStats?>((c) => c.state.data);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: AppSpace.s4,
      runSpacing: AppSpace.s3,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: AppTabs(
            tabs: [
              (label: 'كل الاشتراكات', count: null),
              (label: 'عليها ديون', count: stats?.debtCount),
              (label: 'تنتهي خلال ${MembershipFilters.expiringDays} أيام', count: stats?.expiring),
            ],
            selected: tab.state.index,
            onSelect: (i) => tab.set(MembershipsTab.values[i]),
          ),
        ),
        UGButton(
          label: 'بيع اشتراك',
          icon: Icons.add_card_rounded,
          onPressed: () => context.go(Routes.sellMembership),
        ),
      ],
    );
  }
}
