import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/staff_models.dart';
import '../../domain/models/staff_texts.dart';
import '../bloc/staff_cubits.dart';
import 'account_actions.dart';
import 'staff_cells.dart';

/// تبويب "كل الحسابات": المالك والاستقبال والأعضاء بحالة تفعيلهم، وإعادة كلمات السر فردياً أو لمجموعة
/// مع بطاقات الدخول PDF. عدّادات الحالات من `meta.summary`.
class AccountsTab extends StatelessWidget {
  const AccountsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final list = context.read<AccountsCubit>();
    final state = context.watch<AccountsCubit>().state;
    final summary = state.slice.data?.summary ?? const {};
    void changed() => list.refresh(keepPage: true);
    Widget menu(ClubAccount a) => _RowMenu(a, onDone: changed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s4,
      children: [
        TabIntro(
          text:
              'كل من يدخل باسم النادي. كلمة السر الجديدة مؤقتة: تنهي جلسات الحساب ويغيّرها صاحبها عند أول دخول.',
          actions: [
            UGButton(
              label: 'كلمات سر جديدة لمجموعة',
              icon: Icons.print_rounded,
              kind: UButtonKind.secondary,
              onPressed: () async {
                if (await AccountActions.bulkReset(context, role: state.query.filter('role') as String?)) changed();
              },
            ),
          ],
        ),
        PagedTable<ClubAccount>(
          state: state,
          noun: 'حساباً',
          minWidth: AppSize.accountsTableMin,
          onPage: list.goTo,
          onRetry: list.load,
          onClearFilters: list.clearFilters,
          header: FilterBar(
            search: state.query.search,
            hint: 'الاسم أو الموبايل أو المعرّف',
            onSearch: list.search,
            onClear: state.query.hasFilters ? list.clearFilters : null,
            filters: [
              FilterMenu<String>(
                label: 'الدور',
                options: StaffTexts.roles,
                value: state.query.filter('role') as String?,
                onChanged: (v) => list.filter('role', v),
              ),
            ],
            chips: FilterChoiceChips<String>(
              semanticsLabel: 'حالة الحساب',
              allLabel: _count('الكل', summary['total']),
              options: [for (final s in StaffTexts.states) (value: s.value, label: _count(s.label, summary[s.value]))],
              value: state.query.filter('state') as String?,
              onChanged: (v) => list.filter('state', v),
            ),
          ),
          empty: const AppEmptyState(
            icon: Icons.manage_accounts_outlined,
            title: 'لا حسابات بعد',
            message: 'الحسابات تظهر هنا عند إضافة أعضاء أو موظفي استقبال.',
          ),
          mobileItem: (context, a) => StaffMobileCard(
            person: PersonCell(a.name, sub: a.memberCode, subLtr: true, tag: a.isSelf ? 'حسابك' : null),
            badge: _badge(a),
            menu: menu(a),
            lines: [
              (label: 'الدور', value: a.roleLabel, ltr: false),
              (label: 'الموبايل', value: a.phone, ltr: true),
              (label: 'آخر دخول', value: StaffTexts.lastLogin(a.lastLoginAt), ltr: false),
            ],
          ),
          columns: [
            TableCol(
              'الحساب',
              flex: 3,
              cell: (context, a) => PersonCell(a.name, sub: a.memberCode, subLtr: true, tag: a.isSelf ? 'حسابك' : null),
            ),
            TableCol('الدور', flex: 2, cell: (context, a) => MutedCell(a.roleLabel)),
            TableCol('الموبايل', flex: 2, cell: (context, a) => MutedCell(a.phone, ltr: true)),
            TableCol('آخر دخول', flex: 2, cell: (context, a) => MutedCell(StaffTexts.lastLogin(a.lastLoginAt))),
            TableCol('الحالة', flex: 2, cell: (context, a) => BadgeCell(_badge(a))),
            TableCol('إجراءات', width: AppSize.actionsCol, cell: (context, a) => menu(a)),
          ],
        ),
      ],
    );
  }

  static ({String label, UTone tone}) _badge(ClubAccount a) =>
      (label: a.stateLabel.isEmpty ? a.state : a.stateLabel, tone: StaffTexts.stateTone(a.state));

  static String _count(String label, Object? n) => n is num ? '$label (${n.toInt()})' : label;
}

/// قائمة الحساب: سبب المنع من الخادم (حساب المالك، حسابك) يعطّل كل شيء ويظهر بأعلاها،
/// والحساب المرتبط بنادٍ آخر بلا كلمة سر ولا معرّف.
class _RowMenu extends StatelessWidget {
  const _RowMenu(this.a, {required this.onDone});

  final ClubAccount a;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final blocked = a.blockedReason;
    return MenuAnchor(
      menuChildren: [
        if (blocked != null)
          MenuItemButton(
            leadingIcon: Icon(Icons.lock_outline_rounded, size: AppSize.iconSm, color: c.inkMuted),
            child: Text(blocked, style: UType.caption(color: c.inkMuted)),
          )
        else ...[
          if (a.sharedAccount)
            MenuItemButton(
              leadingIcon: Icon(Icons.link_rounded, size: AppSize.iconSm, color: c.inkMuted),
              child: Text('مرتبط بنادٍ آخر: كلمة السر من حسابه', style: UType.caption(color: c.inkMuted)),
            ),
          ...accountMenuItems(context, userId: a.id, name: a.name, onDone: onDone, canReset: a.canResetPassword),
        ],
      ],
      builder: (context, menu, _) => IconButton(
        tooltip: 'إجراءات ${a.name}',
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
        icon: Icon(Icons.more_horiz_rounded, color: c.inkMuted),
      ),
    );
  }
}
