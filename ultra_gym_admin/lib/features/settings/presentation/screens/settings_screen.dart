import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../bloc/settings_cubits.dart';
import '../widgets/branches_tab.dart';
import '../widgets/club_tab.dart';

/// الإعدادات والفروع (للمالك): تبويب "النادي" (`ClubSettings.html`) و "الفروع" (`BranchSettings.html`).
/// الرابط `?tab=branches` (`Routes.settingsBranches`) يفتح الفروع. ملف النادي مشترك بين التبويبين (حد الفروع).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const branchesTab = 'branches';

  @override
  Widget build(BuildContext context) {
    final tab = GoRouterState.of(context).uri.queryParameters['tab'];
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ClubCubit>()..load()),
        BlocProvider(create: (_) => sl<NotificationCatalogCubit>()..load()),
        BlocProvider(create: (_) => sl<SettingsBranchesCubit>()..load()),
        BlocProvider(key: ValueKey(tab), create: (_) => ValueCubit<int>(tab == branchesTab ? 1 : 0)),
      ],
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  static const _tabs = [(label: 'النادي', count: null), (label: 'الفروع', count: null)];

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<ValueCubit<int>>().state;
    return AppPage(
      children: [
        AppTabs(tabs: _tabs, selected: tab, onSelect: context.read<ValueCubit<int>>().set),
        if (tab == 1) const BranchesTab() else const ClubTab(),
      ],
    );
  }
}
