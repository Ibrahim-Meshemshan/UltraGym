import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../data/repo/staff_repository.dart';
import '../../domain/models/staff_models.dart';
import '../../domain/models/staff_texts.dart';
import '../bloc/staff_cubits.dart';
import 'staff_cells.dart';
import 'staff_member_fields.dart';

/// تبويب "المدربون والعمال": سجلات للرواتب والعمولات بلا دخول للنظام، ولا تُحسب ضمن حد الموظفين.
class StaffMembersTab extends StatelessWidget {
  const StaffMembersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final list = context.read<StaffMembersCubit>();
    final state = context.watch<StaffMembersCubit>().state;
    final branches = context.select<BranchScopeCubit, List<FormOption<int>>>(
      (c) => [for (final b in c.state.active) (value: b.id, label: b.name)],
    );
    final archive = state.query.filter('archived') == 'only';
    void changed() => list.refresh(keepPage: true);
    Future<void> save([StaffMember? s]) async {
      if (await StaffMemberActions.save(context, branches, member: s)) changed();
    }

    Widget menu(StaffMember s) => _RowMenu(s, onEdit: () => save(s), onDone: changed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s4,
      children: [
        TabIntro(
          text: 'سجلات للرواتب والعمولات فقط. المدربون والعمال لا يدخلون النظام.',
          actions: [UGButton(label: 'موظف', icon: Icons.add_rounded, onPressed: save)],
        ),
        PagedTable<StaffMember>(
          state: state,
          noun: 'موظفاً',
          minWidth: AppSize.staffTableMin,
          onPage: list.goTo,
          onRetry: list.load,
          onClearFilters: list.clearFilters,
          onRowTap: archive ? null : save,
          header: FilterBar(
            search: state.query.search,
            hint: 'الاسم أو الموبايل أو المسمى',
            onSearch: list.search,
            onClear: state.query.hasFilters ? list.clearFilters : null,
            filters: [
              FilterMenu<String>(
                label: 'الحالة',
                options: StaffTexts.staffStatuses,
                value: state.query.filter('status') as String?,
                onChanged: (v) => list.filter('status', v),
              ),
              if (branches.length > 1)
                FilterMenu<int>(
                  label: 'الفرع',
                  options: branches,
                  value: state.query.filter('branch_id') as int?,
                  onChanged: (v) => list.filter('branch_id', v),
                ),
              FilterToggle(
                label: 'الأرشيف',
                value: archive,
                onChanged: (v) => list.filter('archived', v ? 'only' : null),
              ),
            ],
            chips: FilterChoiceChips<String>(
              semanticsLabel: 'النوع',
              options: StaffTexts.types,
              value: state.query.filter('type') as String?,
              onChanged: (v) => list.filter('type', v),
            ),
          ),
          empty: EmptyState(
            icon: Icons.fitness_center_rounded,
            title: 'أضف أول مدرب أو عامل',
            message: 'سجّل راتبه الأساسي وعمولته، فتُحسب له بالرواتب الشهرية.',
            actionLabel: 'موظف',
            onAction: save,
          ),
          mobileItem: (context, s) => StaffMobileCard(
            person: PersonCell(s.name, sub: s.jobTitle ?? StaffTexts.type(s.type)),
            badge: StaffTexts.staffStatus(s),
            menu: menu(s),
            lines: [
              (label: 'الراتب', value: StaffTexts.salary(s), ltr: true),
              if (s.isTrainer) (label: 'العمولة', value: StaffTexts.commission(s), ltr: false),
              (label: 'الفرع', value: s.branch?.name ?? '—', ltr: false),
            ],
          ),
          columns: [
            TableCol('الاسم', flex: 3, cell: (context, s) => PersonCell(s.name, sub: s.jobTitle)),
            TableCol(
              'النوع',
              cell: (context, s) => BadgeCell((label: StaffTexts.type(s.type), tone: StaffTexts.typeTone(s.type))),
            ),
            TableCol('الفرع', flex: 2, cell: (context, s) => MutedCell(s.branch?.name ?? '—')),
            TableCol('الراتب الأساسي', flex: 2, cell: (context, s) => MutedCell(StaffTexts.salary(s), ltr: true)),
            TableCol('العمولة', flex: 2, cell: (context, s) => MutedCell(StaffTexts.commission(s))),
            TableCol('منذ', flex: 2, cell: (context, s) => MutedCell(s.hiredOn ?? '—', ltr: s.hiredOn != null)),
            TableCol('الحالة', cell: (context, s) => BadgeCell(StaffTexts.staffStatus(s))),
            TableCol('إجراءات', width: AppSize.actionsCol, cell: (context, s) => menu(s)),
          ],
        ),
      ],
    );
  }
}

/// الإضافة والتعديل والأرشفة والاسترجاع (`club-admin/staff-members`). كل فعل يرجع true إن تمّ.
abstract final class StaffMemberActions {
  static StaffRepository get _repo => sl<StaffRepository>();

  static Future<bool> save(BuildContext context, List<FormOption<int>> branches, {StaffMember? member}) async {
    final keys = IdempotencyKeeper();
    final s = member;
    final options = [
      ...branches,
      if (s?.branch case final b? when !branches.any((o) => o.value == b.id)) (value: b.id, label: b.name),
    ];
    final done = await FormDialog.show<StaffMember>(
      context,
      title: s == null ? 'موظف جديد' : 'تعديل ${s.name}',
      icon: s == null ? Icons.person_add_alt_1_rounded : Icons.edit_rounded,
      submitLabel: s == null ? 'إضافة' : 'حفظ',
      initial: StaffMemberFields.initial(s),
      fields: (_) => StaffMemberFields(branches: options, editing: s != null),
      onSubmit: (form) {
        final body = StaffMemberFields.body(form);
        return s == null
            ? _repo.saveStaffMember(body, idempotencyKey: keys.keyFor(body))
            : _repo.saveStaffMember(body, id: s.id);
      },
    );
    return done != null;
  }

  /// الخادم يرفض (409) أرشفة من عليه سلف غير مسددة، والرسالة تظهر بالنافذة.
  static Future<bool> archive(BuildContext context, StaffMember s) async => await FormDialog.confirm<void>(
    context,
    title: 'أرشفة ${s.name}؟',
    message: 'يختفي من القوائم ومن الرواتب الشهرية، وتبقى رواتبه وسلفه بالسجل. يمكنك استرجاعه من الأرشيف.',
    confirmLabel: 'أرشفة',
    icon: Icons.inventory_2_outlined,
    onConfirm: () => _repo.archiveStaffMember(s.id),
  ) != null;

  static Future<bool> restore(BuildContext context, StaffMember s) async => await FormDialog.confirm<void>(
    context,
    title: 'استرجاع ${s.name}؟',
    message: 'يعود للقوائم بنفس بياناته وراتبه.',
    confirmLabel: 'استرجاع',
    icon: Icons.restore_rounded,
    danger: false,
    onConfirm: () => _repo.restoreStaffMember(s.id),
  ) != null;
}

class _RowMenu extends StatelessWidget {
  const _RowMenu(this.s, {required this.onEdit, required this.onDone});

  final StaffMember s;
  final VoidCallback onEdit, onDone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Future<void> run(Future<bool> Function() action) async {
      if (await action()) onDone();
    }

    return MenuAnchor(
      menuChildren: s.archived
          ? [
              MenuItemButton(
                leadingIcon: const Icon(Icons.restore_rounded, size: AppSize.iconSm),
                onPressed: () => run(() => StaffMemberActions.restore(context, s)),
                child: const Text('استرجاع'),
              ),
            ]
          : [
              MenuItemButton(
                leadingIcon: const Icon(Icons.edit_rounded, size: AppSize.iconSm),
                onPressed: onEdit,
                child: const Text('تعديل'),
              ),
              MenuItemButton(
                leadingIcon: Icon(Icons.inventory_2_outlined, size: AppSize.iconSm, color: c.dangerInk),
                onPressed: () => run(() => StaffMemberActions.archive(context, s)),
                child: Text('أرشفة', style: UType.body(color: c.dangerInk)),
              ),
            ],
      builder: (context, menu, _) => IconButton(
        tooltip: 'إجراءات ${s.name}',
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
        icon: Icon(Icons.more_horiz_rounded, color: c.inkMuted),
      ),
    );
  }
}
