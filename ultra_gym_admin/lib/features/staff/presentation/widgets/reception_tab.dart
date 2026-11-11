import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../domain/models/staff_models.dart';
import '../../domain/models/staff_texts.dart';
import '../bloc/staff_cubits.dart';
import 'account_actions.dart';
import 'reception_actions.dart';
import 'staff_cells.dart';

/// تبويب "حسابات الاستقبال" (`Staff.html`): حسابات تدخل اللوحة وشاشة الاستقبال محصورة بفروعها.
class ReceptionTab extends StatelessWidget {
  const ReceptionTab({super.key});

  @override
  Widget build(BuildContext context) {
    final list = context.read<ReceptionistsCubit>();
    final state = context.watch<ReceptionistsCubit>().state;
    final branches = context.select<BranchScopeCubit, BranchOptions>(
      (c) => [for (final b in c.state.active) (value: b.id, label: b.name)],
    );
    final archive = state.query.filter('archived') == 'only';
    void changed() {
      list.refresh(keepPage: true);
      context.read<StaffUsageCubit>().refresh();
    }

    Future<void> add() async {
      if (await ReceptionActions.add(context, branches)) changed();
    }

    Widget menu(Receptionist r) => ReceptionRowMenu(r, branches: branches, onDone: changed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s4,
      children: [
        TabIntro(
          text: 'حسابات تدخل لوحة النادي وشاشة الاستقبال، محصورة بالفروع المحددة.',
          actions: [
            UGButton(
              label: 'طباعة بطاقات الدخول PDF',
              icon: Icons.print_rounded,
              kind: UButtonKind.secondary,
              onPressed: () async {
                if (await AccountActions.bulkReset(context, role: 'receptionist')) changed();
              },
            ),
            UGButton(label: 'حساب استقبال', icon: Icons.add_rounded, onPressed: add),
          ],
        ),
        PagedTable<Receptionist>(
          state: state,
          noun: 'حساباً',
          minWidth: AppSize.receptionTableMin,
          onPage: list.goTo,
          onRetry: list.load,
          onClearFilters: list.clearFilters,
          header: FilterBar(
            search: state.query.search,
            hint: 'الاسم أو الموبايل',
            onSearch: list.search,
            onClear: state.query.hasFilters ? list.clearFilters : null,
            filters: [
              FilterToggle(
                label: 'الأرشيف',
                value: archive,
                onChanged: (v) => list.filter('archived', v ? 'only' : null),
              ),
            ],
            chips: archive
                ? null
                : FilterChoiceChips<String>(
                    semanticsLabel: 'حالة الحساب',
                    options: StaffTexts.receptionStatuses,
                    value: state.query.filter('status') as String?,
                    onChanged: (v) => list.filter('status', v),
                  ),
          ),
          empty: EmptyState(
            icon: Icons.support_agent_rounded,
            title: 'أضف أول موظف استقبال',
            message: 'يدخل بموبايله وكلمة سر مؤقتة، ويعمل بالفروع التي تحددها فقط.',
            actionLabel: 'حساب استقبال',
            onAction: add,
          ),
          mobileItem: (context, r) => StaffMobileCard(
            person: PersonCell(r.name, sub: r.memberCode, subLtr: true),
            badge: StaffTexts.reception(r),
            menu: menu(r),
            lines: [
              (label: 'الموبايل', value: r.phone, ltr: true),
              (label: 'الفروع', value: StaffTexts.branches(r.branches), ltr: false),
              (label: 'آخر دخول', value: StaffTexts.lastLogin(r.lastLoginAt), ltr: false),
            ],
          ),
          columns: [
            TableCol('الاسم', flex: 3, cell: (context, r) => PersonCell(r.name, sub: r.email, subLtr: true)),
            TableCol('الموبايل', flex: 2, cell: (context, r) => MutedCell(r.phone, ltr: true)),
            TableCol('المعرّف', flex: 2, cell: (context, r) => MutedCell(r.memberCode, ltr: true)),
            TableCol('الفروع', flex: 2, cell: (context, r) => MutedCell(StaffTexts.branches(r.branches))),
            TableCol('آخر دخول', flex: 2, cell: (context, r) => MutedCell(StaffTexts.lastLogin(r.lastLoginAt))),
            TableCol('الحالة', flex: 2, cell: (context, r) => BadgeCell(StaffTexts.reception(r))),
            TableCol('إجراءات', width: AppSize.actionsCol, cell: (context, r) => menu(r)),
          ],
        ),
      ],
    );
  }
}
