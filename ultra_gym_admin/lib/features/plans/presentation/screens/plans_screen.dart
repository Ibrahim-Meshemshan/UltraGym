import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../widgets/coupons_section.dart';
import '../widgets/plans_section.dart';

/// الخطط والكوبونات (`Plans.html`). المالك: تبويبات خطط الاشتراك / الأرشيف / الكوبونات مع الإضافة والتعديل.
/// الاستقبال: بطاقات الخطط للقراءة فقط (الكوبونات والأرشيف للمالك).
class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(create: (_) => ValueCubit<int>(0), child: const _Body());
}

class _Body extends StatelessWidget {
  const _Body();

  static const _tabs = [
    (label: 'خطط الاشتراك', count: null),
    (label: 'الأرشيف', count: null),
    (label: 'الكوبونات', count: null),
  ];

  @override
  Widget build(BuildContext context) {
    final owner = context.select<AuthBloc, bool>((b) => b.state.session?.isClubOwner ?? false);
    final tab = owner ? context.watch<ValueCubit<int>>().state : 0;
    return AppPage(
      children: [
        if (owner)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: AppTabs(tabs: _tabs, selected: tab, onSelect: context.read<ValueCubit<int>>().set),
            ),
          ),
        switch (tab) {
          1 => PlansSection(key: const ValueKey('archived'), owner: owner, archived: true),
          2 => const CouponsSection(),
          _ => PlansSection(key: const ValueKey('plans'), owner: owner),
        },
      ],
    );
  }
}
