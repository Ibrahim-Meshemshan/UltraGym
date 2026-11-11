import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../staff/presentation/widgets/staff_cells.dart';
import '../../domain/models/activity_models.dart';
import '../bloc/billing_cubits.dart';
import 'activity_dialog.dart';

/// تبويب "سجل النشاط" (`ClubBilling.html`): من فعل ماذا ومتى. الفلاتر: البحث، المستخدم، القسم (`meta.modules`)،
/// والفترة (بلا فترة = كل السجل). ما فعله فريق UltraGym بجلسة دعم معلّم. الصف يفتح التفاصيل (القيم قبل وبعد).
class ActivityTab extends StatelessWidget {
  const ActivityTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final list = context.read<ActivityLogCubit>();
    final state = context.watch<ActivityLogCubit>().state;
    final users = context.select<ActivityUsersCubit, List<ActivityUser>>((u) => u.state.data ?? const []);
    final modules = [
      for (final m in asList(state.slice.data?.meta['modules'], (j) => (value: j.str('key'), label: j.str('label'))))
        m,
    ];
    final q = state.query;

    Widget actor(ActivityEntry e) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.s1,
      children: [
        Text(e.actor, style: UType.body(color: c.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
        if (e.byPlatformSupport) const StatusBadge('دعم UltraGym', tone: UTone.accent, dot: false),
      ],
    );

    return PagedTable<ActivityEntry>(
      state: state,
      noun: 'عملية',
      minWidth: AppSize.activityTableMin,
      onPage: list.goTo,
      onRetry: list.load,
      onClearFilters: list.clearFilters,
      onRowTap: (e) => ActivityDialog.show(context, e.id),
      header: FilterBar(
        search: q.search,
        hint: 'العملية أو المستخدم أو العنصر',
        onSearch: list.search,
        onClear: q.hasFilters ? list.clearFilters : null,
        filters: [
          if (users.isNotEmpty)
            FilterMenu<int>(
              label: 'المستخدم',
              options: [for (final u in users) (value: u.id, label: u.name)],
              value: q.filter('user_id') as int?,
              onChanged: (v) => list.filter('user_id', v),
            ),
          if (modules.isNotEmpty)
            FilterMenu<String>(
              label: 'القسم',
              options: modules,
              value: q.filter('module') as String?,
              onChanged: (v) => list.filter('module', v),
            ),
          FilterDateRange(
            from: q.filter('from') as DateTime?,
            to: q.filter('to') as DateTime?,
            emptyLabel: 'كل السجل',
            onChanged: (from, to) => list.query(q.withFilter('from', from).withFilter('to', to)),
          ),
        ],
      ),
      empty: const EmptyState(
        icon: Icons.history_rounded,
        title: 'لا نشاط مسجّل بعد',
        message: 'كل عملية بالنادي (بيع، قبض، تعديل، دخول) تظهر هنا بمن نفّذها ومتى.',
      ),
      mobileItem: (context, e) => StaffMobileCard(
        person: actor(e),
        badge: (label: e.moduleLabel, tone: UTone.neutral),
        lines: [
          (label: 'العملية', value: e.description, ltr: false),
          if (e.subject case final s?) (label: 'على', value: s, ltr: false),
          (label: 'الوقت', value: Formatters.dateTime(e.createdAt), ltr: true),
        ],
      ),
      columns: [
        TableCol(
          'الوقت',
          width: AppSize.activityTimeCol,
          cell: (context, e) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              LtrText(Formatters.time(e.createdAt), style: UType.body(color: c.ink)),
              LtrText(Formatters.date(e.createdAt, fromUtc: true), style: UType.caption(color: c.inkMuted)),
            ],
          ),
        ),
        TableCol('المستخدم', flex: 2, cell: (context, e) => actor(e)),
        TableCol('القسم', flex: 2, cell: (context, e) => MutedCell(e.moduleLabel)),
        TableCol(
          'العملية',
          flex: 4,
          cell: (context, e) => Text(e.description, style: UType.body(color: c.ink), maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        TableCol('على', flex: 2, cell: (context, e) => MutedCell(e.subject ?? '—')),
      ],
    );
  }
}
