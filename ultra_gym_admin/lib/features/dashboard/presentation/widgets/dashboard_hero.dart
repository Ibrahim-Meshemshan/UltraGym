import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../auth/domain/models/auth_models.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/models/dashboard_models.dart';
import '../demo/demo_card.dart';

/// رأس الرئيسية بأسلوب التجربة (بدل `HeroBanner`): يوم العمل صغيراً بالبرتقالي، التحية عنواناً كبيراً،
/// ثم النادي وأرقام اليوم، والزران على الطرف (الأساسي بالتدرج والثاني زجاجي) حين يتسع العرض.
/// يظهر فوراً من الجلسة، وتكتمل أرقامه حين تصل `data`.
class DashboardHero extends StatelessWidget {
  const DashboardHero({super.key, this.data});

  final DashboardData? data;

  @override
  Widget build(BuildContext context) {
    final s = context.select<AuthBloc, Session?>((b) => b.state.session);
    if (s == null) return const SizedBox.shrink();
    final p = AppPalette.of(context);
    final first = s.user.name.trim().split(RegExp(r'\s+')).first;
    final d = data;
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= AppSize.heroActions;
        final subtitle = [
          s.tenant?.name ?? AppConfig.appTitle,
          if (d != null && wide) ...['دخول اليوم: ${d.attendance.today}', 'اشتراكات اليوم: ${d.memberships.soldToday}'],
        ].join(' · ');
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpace.s1,
          children: [
            if (d?.businessDate case final day?)
              Text(Formatters.dayTitle(day), style: UType.label(color: p.accentText).weight(600)),
            Text(
              '${Formatters.greeting(sl<ServerClock>().now())}، $first',
              style: (wide ? UType.displayMd(color: p.ink) : UType.h2(color: p.ink)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: UType.body(color: p.muted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.s2),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: text),
                    AppSpace.gap4,
                    const _Actions(),
                  ],
                )
              : text,
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
    spacing: AppSpace.s3,
    children: [
      DemoButton(
        label: 'تسجيل دخول عضو',
        icon: Icons.login_rounded,
        kind: DemoButtonKind.ghost,
        onPressed: () => context.go(Routes.attendance),
      ),
      DemoButton(label: 'بيع اشتراك', icon: Icons.add_rounded, onPressed: () => context.go(Routes.memberships)),
    ],
  );
}
