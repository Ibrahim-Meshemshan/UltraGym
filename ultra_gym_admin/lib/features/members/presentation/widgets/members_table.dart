import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../domain/models/member_models.dart';
import '../bloc/members_cubit.dart';
import 'member_actions.dart';
import 'member_cells.dart';

/// جدول الأعضاء (`Members.html`): بحث + الفرع + الجنس + عليه دين، ورقائق حالة الاشتراك، ثم الصفوف والصفحات.
class MembersTable extends StatelessWidget {
  const MembersTable({super.key, required this.isOwner, this.onAdd});

  final bool isOwner;

  /// زر الحالة الفارغة (null بالأرشيف).
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final list = context.read<MembersListCubit>();
    final state = context.watch<MembersListCubit>().state;
    final archive = list.tab == MembersTab.archive;
    void open(MemberRow m) => context.go(Routes.child(Routes.members, m.id));
    return PagedTable<MemberRow>(
      state: state,
      noun: 'عضوًا',
      onPage: list.goTo,
      onRetry: list.load,
      onRowTap: open,
      onClearFilters: list.clearFilters,
      header: _Filters(query: state.query, showStatus: !archive),
      empty: archive
          ? const AppEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'الأرشيف فارغ',
              message: 'الأعضاء المؤرشفون يظهرون هنا، ويمكن استرجاعهم بسجلهم كاملاً.',
            )
          : AppEmptyState(
              icon: Icons.person_add_alt_1_rounded,
              title: 'أضف أول عضو',
              message: 'سجّل بيانات العضو، ويصله رقم دخول وكلمة سر مؤقتة على واتساب.',
              actionLabel: onAdd == null ? null : 'إضافة عضو',
              onAction: onAdd,
            ),
      mobileItem: (context, m) => MemberMobileCard(m, menu: MemberRowMenu(m, isOwner: isOwner)),
      columns: [
        TableCol('العضو', flex: 3, cell: (context, m) => MemberIdentity(m)),
        TableCol('الموبايل', flex: 2, cell: (context, m) => _Muted(m.phone, ltr: true)),
        TableCol('الفرع', flex: 2, cell: (context, m) => _Muted(m.branchName ?? '—')),
        TableCol('الاشتراك الحالي', flex: 3, cell: (context, m) => MembershipCell(m.membership)),
        TableCol(
          'الحالة',
          flex: 2,
          cell: (context, m) =>
              Align(alignment: AlignmentDirectional.centerStart, child: MembershipBadge(m.membership)),
        ),
        TableCol('الدين', cell: (context, m) => DueText(m.dueUsd)),
        TableCol(
          'إجراءات',
          width: AppSize.actionsCol,
          cell: (context, m) => MemberRowMenu(m, isOwner: isOwner),
        ),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.query, required this.showStatus});

  final ListQuery query;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final list = context.read<MembersListCubit>();
    // فلتر الفرع داخل الجدول فقط حين يكون الشريط العلوي على "كل الفروع".
    final branches = context.select<BranchScopeCubit, List<FormOption<int>>>(
      (c) => c.state.branchId != null || !c.state.canChoose
          ? const []
          : [for (final b in c.state.active) (value: b.id, label: b.name)],
    );
    return FilterBar(
      search: query.search,
      hint: 'الاسم أو الموبايل أو المعرّف',
      onSearch: list.search,
      onClear: query.hasFilters ? list.clearFilters : null,
      filters: [
        if (branches.isNotEmpty)
          FilterMenu<int>(
            label: 'الفرع',
            options: branches,
            value: query.filter(MemberFilters.branchId) as int?,
            onChanged: (v) => list.filter(MemberFilters.branchId, v),
          ),
        FilterMenu<String>(
          label: 'الجنس',
          options: MemberFilters.genders,
          value: query.filter(MemberFilters.gender) as String?,
          onChanged: (v) => list.filter(MemberFilters.gender, v),
        ),
        FilterToggle(
          label: 'عليه دين',
          value: query.filter(MemberFilters.hasDebt) == true,
          onChanged: (v) => list.filter(MemberFilters.hasDebt, v ? true : null),
        ),
      ],
      chips: showStatus
          ? FilterChoiceChips<String>(
              semanticsLabel: 'حالة الاشتراك',
              options: MemberFilters.statuses,
              value: query.filter(MemberFilters.membershipStatus) as String?,
              onChanged: (v) => list.filter(MemberFilters.membershipStatus, v),
            )
          : null,
    );
  }
}

class _Muted extends StatelessWidget {
  const _Muted(this.text, {this.ltr = false});

  final String text;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = UType.body(color: ltr ? c.ink : c.inkMuted);
    return ltr
        ? Align(
            alignment: AlignmentDirectional.centerStart,
            child: LtrText(text, style: style),
          )
        : Text(text, style: style, maxLines: 2, overflow: TextOverflow.ellipsis);
  }
}
