import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../auth/domain/models/auth_models.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// رئيسية مؤقتة بعد الدخول حتى يُبنى الهيكل (Shell): تعرض الجلسة وتتيح الخروج.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.select<AuthBloc, Session?>((b) => b.state.session);
    if (s == null) return const SizedBox.shrink();
    final now = sl<ServerClock>().now();
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: context.pagePadding, children: [
          if (s.isImpersonated) ...[
            Container(
              padding: const EdgeInsets.all(AppSpace.s3),
              decoration: BoxDecoration(color: c.warningSoft, borderRadius: AppRadius.smAll),
              child: Text('جلسة دعم من فريق UltraGym', style: UType.label(color: c.warningInk).weight(600)),
            ),
            AppSpace.gap4,
          ],
          PageHeader(
            title: '${Formatters.greeting(now)}، ${s.user.name}',
            subtitle: s.tenant?.name ?? AppConfig.appTitle,
            actions: [
              UGButton(
                label: 'تسجيل الخروج',
                icon: Icons.logout_rounded,
                kind: UButtonKind.secondary,
                onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
              ),
            ],
          ),
          AppSpace.gap5,
          SectionCard(
            title: 'جلستك',
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: AppSpace.s2, runSpacing: AppSpace.s2, children: [
                for (final r in s.roles) StatusBadge(Labels.role(r).text, tone: Labels.role(r).tone),
                if (s.canViewFinance) const StatusBadge('المالية', tone: UTone.info),
                if (s.canManageStaff) const StatusBadge('الموظفون', tone: UTone.info),
              ]),
              if (s.memberCode != null) ...[
                AppSpace.gap3,
                LtrText(s.memberCode!, style: UType.h3(color: c.ink)),
              ],
              AppSpace.gap3,
              Text('الواجهة الرئيسية قيد البناء.', style: UType.body(color: c.inkMuted)),
            ]),
          ),
        ]),
      ),
    );
  }
}
