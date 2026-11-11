import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../bloc/staff_cubits.dart';
import '../widgets/accounts_tab.dart';
import '../widgets/reception_tab.dart';
import '../widgets/staff_limit_card.dart';
import '../widgets/staff_members_tab.dart';

/// الموظفون والحسابات (`Staff.html`، للمالك بصلاحية `can_manage_staff`): حد الباقة، ثم تبويبات
/// حسابات الاستقبال / المدربون والعمال (`?tab=staff`) / كل الحسابات (`?tab=accounts`). كل قائمة تُحمَّل عند فتح تبويبها.
class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  static const tabKeys = [null, 'staff', 'accounts'];

  @override
  Widget build(BuildContext context) {
    final tab = GoRouterState.of(context).uri.queryParameters['tab'];
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<StaffUsageCubit>()..load()),
        BlocProvider(create: (_) => sl<ReceptionistsCubit>()..load()),
        BlocProvider(create: (_) => sl<StaffMembersCubit>()..load()),
        BlocProvider(create: (_) => sl<AccountsCubit>()..load()),
        BlocProvider(key: ValueKey(tab), create: (_) => ValueCubit<int>(tabKeys.indexOf(tab).clamp(0, 2))),
      ],
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  static const _tabs = [
    (label: 'حسابات الاستقبال', count: null),
    (label: 'المدربون والعمال', count: null),
    (label: 'كل الحسابات', count: null),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<ValueCubit<int>>().state;
    return AppPage(
      children: [
        const StaffLimitCard(),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            // آخر تبويب: يبدأ التمرير من النهاية فيبقى المحدد ظاهراً على الموبايل.
            reverse: tab == 2,
            child: AppTabs(tabs: _tabs, selected: tab, onSelect: context.read<ValueCubit<int>>().set),
          ),
        ),
        switch (tab) {
          1 => const StaffMembersTab(),
          2 => const AccountsTab(),
          _ => const ReceptionTab(),
        },
      ],
    );
  }
}
