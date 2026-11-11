import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../../members/presentation/widgets/member_cells.dart';
import '../../domain/models/memberships_models.dart';
import '../bloc/memberships_cubit.dart';

/// جدول الاشتراكات (`Memberships.html`): الفلاتر بتبويب "الكل" فقط، والصف يفتح ملف العضو
/// (حتى تُبنى صفحة تفاصيل الاشتراك).
class MembershipsTable extends StatelessWidget {
  const MembershipsTable({super.key});

  @override
  Widget build(BuildContext context) {
    final list = context.read<MembershipsListCubit>();
    final state = context.watch<MembershipsListCubit>().state;
    void open(MembershipRow m) => context.go(Routes.child(Routes.memberships, m.id));
    return PagedTable<MembershipRow>(
      state: state,
      noun: 'اشتراكاً',
      onPage: list.goTo,
      onRetry: list.load,
      onRowTap: open,
      onClearFilters: list.clearFilters,
      header: list.tab == MembershipsTab.all ? _Filters(query: state.query) : null,
      empty: switch (list.tab) {
        MembershipsTab.all => const AppEmptyState(
          icon: Icons.card_membership_rounded,
          title: 'لا اشتراكات بعد',
          message: 'بيع أول اشتراك من ملف العضو، ويظهر هنا مع فترته ودينه.',
        ),
        MembershipsTab.debts => const AppEmptyState(
          icon: Icons.verified_rounded,
          title: 'لا ديون',
          message: 'كل الاشتراكات مدفوعة بالكامل.',
        ),
        MembershipsTab.expiring => const AppEmptyState(
          icon: Icons.event_available_rounded,
          title: 'لا اشتراك ينتهي قريباً',
          message: 'لا اشتراكات تنتهي خلال ${MembershipFilters.expiringDays} أيام.',
        ),
      },
      mobileItem: (context, m) => _MobileCard(m),
      columns: [
        TableCol('العضو', flex: 3, cell: (context, m) => _Owner(m)),
        TableCol('الخطة', flex: 3, cell: (context, m) => _Plan(m)),
        TableCol('الفترة', flex: 2, cell: (context, m) => MembershipPeriod(m)),
        TableCol('الصافي', cell: (context, m) => _Usd(m.netUsd)),
        TableCol('الدين', cell: (context, m) => DueText(m.dueUsd)),
        TableCol(
          'الحالة',
          flex: 2,
          cell: (context, m) => Align(alignment: AlignmentDirectional.centerStart, child: MembershipBadge(m)),
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
    final list = context.read<MembershipsListCubit>();
    final plans = context.select<PlanOptionsCubit, List<PlanOption>>((c) => c.state.data ?? const []);
    // فلتر الفرع داخل الجدول فقط حين يكون الشريط العلوي على "كل الفروع".
    final branches = context.select<BranchScopeCubit, List<FormOption<int>>>(
      (c) => c.state.branchId != null || !c.state.canChoose
          ? const []
          : [for (final b in c.state.active) (value: b.id, label: b.name)],
    );
    return FilterBar(
      search: query.search,
      hint: 'اسم العضو أو الموبايل أو الخطة',
      onSearch: list.search,
      onClear: query.hasFilters ? list.clearFilters : null,
      filters: [
        if (branches.isNotEmpty)
          FilterMenu<int>(
            label: 'الفرع',
            options: branches,
            value: query.filter(MembershipFilters.branchId) as int?,
            onChanged: (v) => list.filter(MembershipFilters.branchId, v),
          ),
        if (plans.isNotEmpty)
          FilterMenu<int>(
            label: 'الخطة',
            options: plans,
            value: query.filter(MembershipFilters.planId) as int?,
            onChanged: (v) => list.filter(MembershipFilters.planId, v),
          ),
      ],
      chips: FilterChoiceChips<String>(
        semanticsLabel: 'حالة الاشتراك',
        options: MembershipFilters.statuses,
        value: query.filter(MembershipFilters.status) as String?,
        onChanged: (v) => list.filter(MembershipFilters.status, v),
      ),
    );
  }
}

/// صاحب الاشتراك: حروف الاسم + الاسم + الفرع.
class _Owner extends StatelessWidget {
  const _Owner(this.m);

  final MembershipRow m;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        MemberAvatar(m.playerName),
        AppSpace.gap3,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.playerName,
                style: UType.body(color: c.ink).weight(600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (m.branchName case final b?) Text(b, style: UType.caption(color: c.inkMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

/// الخطة + سطر المتبقي من حقول الخادم (`membershipDetail`).
class _Plan extends StatelessWidget {
  const _Plan(this.m);

  final MembershipRow m;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          m.planName,
          style: UType.body(color: c.ink),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(membershipDetail(m), style: UType.caption(color: c.inkMuted)),
      ],
    );
  }
}

class _Usd extends StatelessWidget {
  const _Usd(this.value);

  final double value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: LtrText(Formatters.usd(value), style: UType.body(color: c.ink)),
    );
  }
}

/// بطاقة الموبايل: العضو والحالة بسطر، والخطة والدين تحته، والفترة.
class _MobileCard extends StatelessWidget {
  const _MobileCard(this.m);

  final MembershipRow m;

  @override
  Widget build(BuildContext context) {
    const indent = EdgeInsetsDirectional.only(start: AppSize.avatar + AppSpace.s3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s2,
      children: [
        Row(
          children: [
            Expanded(child: _Owner(m)),
            MembershipBadge(m),
          ],
        ),
        Padding(
          padding: indent,
          child: Row(
            children: [
              Expanded(child: _Plan(m)),
              if (m.dueUsd > 0) ...[AppSpace.gap2, DueText(m.dueUsd)],
            ],
          ),
        ),
      ],
    );
  }
}
