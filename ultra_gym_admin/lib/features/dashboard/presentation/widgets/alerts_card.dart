import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/models/dashboard_models.dart';
import 'dashboard_body.dart';

/// تنبيهات الخادم كما هي (`message`)، ولونها ورابطها حسب `type`. نوع جديد غير معروف يظهر كمعلومة بلا رابط.
class AlertsCard extends StatelessWidget {
  const AlertsCard({super.key, required this.alerts});

  final List<DashboardAlert> alerts;

  @override
  Widget build(BuildContext context) {
    final owner = context.select<AuthBloc, bool>((b) => b.state.session?.isClubOwner ?? false);
    return SectionCard(
      title: 'تنبيهات',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < alerts.length; i++) ...[
            if (i > 0) AppSpace.gap2,
            _AlertRow(
              alert: alerts[i],
              look: dashboardAlertLook(alerts[i].type, owner: owner),
            ),
          ],
        ],
      ),
    );
  }
}

/// شكل التنبيه ورابطه. `exchange_rate_missing` يحدده المالك من صفحة سعر الصرف، فلا رابط للاستقبال.
typedef DashboardAlertLook = ({IconData icon, UTone tone, String? link, String? linkLabel});

DashboardAlertLook dashboardAlertLook(String type, {required bool owner}) => switch (type) {
  'exchange_rate_missing' => (
    icon: Icons.currency_exchange_rounded,
    tone: UTone.warning,
    link: owner ? Routes.exchangeRate : null,
    linkLabel: owner ? 'تحديد السعر' : null,
  ),
  'cash_session_closed' => (
    icon: Icons.point_of_sale_rounded,
    tone: UTone.info,
    link: Routes.cashSessions,
    linkLabel: 'الصندوق',
  ),
  'memberships_expiring' => (
    icon: Icons.event_busy_rounded,
    tone: UTone.warning,
    link: DashboardLinks.expiring,
    linkLabel: 'عرض',
  ),
  _ => (icon: Icons.info_outline_rounded, tone: UTone.info, link: null, linkLabel: null),
};

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert, required this.look});

  final DashboardAlert alert;
  final DashboardAlertLook look;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = look.tone.colors(context.colors);
    final link = look.link;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s3),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.fieldAll),
      child: Row(
        children: [
          Icon(look.icon, size: AppSize.iconSm, color: fg),
          AppSpace.gap3,
          Expanded(
            child: Text(alert.message, style: UType.body(color: fg)),
          ),
          if (link != null)
            TextButton(
              onPressed: () => context.go(link),
              style: TextButton.styleFrom(foregroundColor: fg),
              child: Text(look.linkLabel ?? 'عرض'),
            ),
        ],
      ),
    );
  }
}
