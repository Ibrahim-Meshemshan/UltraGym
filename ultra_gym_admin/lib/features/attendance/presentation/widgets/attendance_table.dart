import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../../members/presentation/widgets/history_columns.dart';
import '../../../members/presentation/widgets/member_cells.dart';
import '../../domain/models/attendance_models.dart';
import '../bloc/attendance_cubit.dart';

/// سجل الحضور (`Attendance.html`): الفترة والنتيجة والطريقة والبحث، والصف يفتح ملف العضو.
/// الرد بلا معرّف العضو والخطة والجهاز، فالأعمدة: الوقت، العضو، الفرع، الطريقة، النتيجة، سجّله.
class AttendanceTable extends StatelessWidget {
  const AttendanceTable({super.key});

  @override
  Widget build(BuildContext context) {
    final list = context.read<AttendanceListCubit>();
    final state = context.watch<AttendanceListCubit>().state;
    return PagedTable<AttendanceRow>(
      state: state,
      noun: 'سجلاً',
      onPage: list.goTo,
      onRetry: list.load,
      onRowTap: (a) => context.go(Routes.child(Routes.members, a.playerId)),
      onClearFilters: list.clearFilters,
      header: _Filters(query: state.query),
      empty: const EmptyState(
        icon: Icons.login_rounded,
        title: 'لا دخول بهذه الفترة',
        message: 'سجّل الدخول يدوياً من هنا، أو من شاشة الاستقبال.',
      ),
      mobileItem: (context, a) => _MobileCard(a),
      columns: [
        TableCol('الوقت', flex: 2, cell: (c, a) => _Time(a)),
        TableCol('العضو', flex: 3, cell: (c, a) => _Member(a.playerName)),
        TableCol('الفرع', flex: 3, cell: (c, a) => _muted(c, a.entry.branchName ?? '—')),
        TableCol('الطريقة', flex: 2, cell: (c, a) => _Method(a)),
        TableCol(
          'النتيجة',
          flex: 3,
          cell: (c, a) => Align(alignment: AlignmentDirectional.centerStart, child: AttendanceResult(a.entry)),
        ),
        TableCol('سجّله', flex: 2, cell: (c, a) => _muted(c, a.recordedBy ?? '—')),
      ],
    );
  }

  static Widget _muted(BuildContext c, String v) => Text(v, style: UType.label(color: c.colors.inkMuted));
}

class _Filters extends StatelessWidget {
  const _Filters({required this.query});

  final ListQuery query;

  @override
  Widget build(BuildContext context) {
    final list = context.read<AttendanceListCubit>();
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
        FilterDateRange(
          from: query.filter(AttendanceFilters.from) as DateTime?,
          to: query.filter(AttendanceFilters.to) as DateTime?,
          emptyLabel: 'آخر ${AttendanceFilters.defaultDays} يوماً',
          onChanged: (from, to) =>
              list.query(query.withFilter(AttendanceFilters.from, from).withFilter(AttendanceFilters.to, to)),
        ),
        FilterMenu<String>(
          label: 'الطريقة',
          options: AttendanceFilters.methods,
          value: query.filter(AttendanceFilters.method) as String?,
          onChanged: (v) => list.filter(AttendanceFilters.method, v),
        ),
        if (branches.isNotEmpty)
          FilterMenu<int>(
            label: 'الفرع',
            options: branches,
            value: query.filter(AttendanceFilters.branchId) as int?,
            onChanged: (v) => list.filter(AttendanceFilters.branchId, v),
          ),
      ],
      chips: FilterChoiceChips<String>(
        semanticsLabel: 'نتيجة الدخول',
        options: AttendanceFilters.statuses,
        value: query.filter(AttendanceFilters.status) as String?,
        onChanged: (v) => list.filter(AttendanceFilters.status, v),
      ),
    );
  }
}

/// الوقت بتوقيت النادي فوق التاريخ.
class _Time extends StatelessWidget {
  const _Time(this.a);

  final AttendanceRow a;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LtrText(Formatters.time(a.entry.checkedInAt), style: UType.body(color: c.ink).weight(600)),
        LtrText(Formatters.date(a.entry.checkedInAt, fromUtc: true), style: UType.caption(color: c.inkMuted)),
      ],
    );
  }
}

class _Member extends StatelessWidget {
  const _Member(this.name);

  final String name;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      MemberAvatar(name),
      AppSpace.gap3,
      Expanded(
        child: Text(
          name,
          style: UType.body(color: context.colors.ink).weight(600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

/// الطريقة + "دون اتصال" لما سجّلته محطة الاستقبال وزامنته لاحقاً.
class _Method extends StatelessWidget {
  const _Method(this.a);

  final AttendanceRow a;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpace.s2,
    runSpacing: AppSpace.s1,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(a.entry.methodLabel, style: UType.label(color: context.colors.ink)),
      if (a.isOffline) const StatusBadge('دون اتصال', tone: UTone.info),
    ],
  );
}

class _MobileCard extends StatelessWidget {
  const _MobileCard(this.a);

  final AttendanceRow a;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s2,
      children: [
        Row(
          children: [
            Expanded(child: _Member(a.playerName)),
            AppSpace.gap2,
            LtrText(Formatters.dateTime(a.entry.checkedInAt), style: UType.caption(color: c.inkMuted)),
          ],
        ),
        AttendanceResult(a.entry),
        Text(
          [a.entry.branchName, a.entry.methodLabel, if (a.isOffline) 'دون اتصال', a.recordedBy].nonNulls.join(' · '),
          style: UType.caption(color: c.inkMuted),
        ),
      ],
    );
  }
}
