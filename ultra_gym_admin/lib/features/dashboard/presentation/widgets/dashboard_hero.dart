import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../auth/domain/models/auth_models.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/models/dashboard_models.dart';

/// بانر الترحيب (المكان المزخرف الوحيد بالرئيسية): يوم العمل، التحية، النادي وأرقام اليوم.
/// يظهر فوراً من الجلسة، وتكتمل أرقامه حين تصل `data`. الأزرار تحتاج عرضاً (الزخرفة تأخذ 230).
class DashboardHero extends StatelessWidget {
  const DashboardHero({super.key, this.data});

  final DashboardData? data;

  @override
  Widget build(BuildContext context) {
    final s = context.select<AuthBloc, Session?>((b) => b.state.session);
    if (s == null) return const SizedBox.shrink();
    final first = s.user.name.trim().split(RegExp(r'\s+')).first;
    final d = data;
    return LayoutBuilder(
      builder: (context, box) {
        // الضيق: اسم النادي فقط (أرقام اليوم بالبطاقات تحته مباشرة، والبانر ثابت الارتفاع)
        final wide = box.maxWidth >= AppSize.heroActions;
        final subtitle = [
          s.tenant?.name ?? AppConfig.appTitle,
          if (d != null && wide) ...['دخول اليوم: ${d.attendance.today}', 'اشتراكات اليوم: ${d.memberships.soldToday}'],
        ].join(' · ');
        return HeroBanner(
          tag: switch (d?.businessDate) {
            final day? => Formatters.dayTitle(day),
            null => null,
          },
          greeting: '${Formatters.greeting(sl<ServerClock>().now())}، $first',
          subtitle: subtitle,
          action: wide ? const _Actions() : null,
        );
      },
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      UGButton(label: 'بيع اشتراك', icon: Icons.add_rounded, onPressed: () => context.go(Routes.memberships)),
      AppSpace.gap3,
      UGButton(label: 'تسجيل دخول عضو', kind: UButtonKind.onDark, onPressed: () => context.go(Routes.attendance)),
    ],
  );
}
