import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../domain/models/dashboard_models.dart';
import '../bloc/dashboard_cubit.dart';
import 'dashboard_body.dart';

/// "تنتهي خلال 7 أيام": أقرب 5 اشتراكات انتهاءً، بحالة مستقلة عن أرقام الصفحة.
/// الضغط على الصف أو "تجديد" يفتح الاشتراك (التجديد من صفحته).
class ExpiringCard extends StatelessWidget {
  const ExpiringCard({super.key});

  @override
  Widget build(BuildContext context) {
    final slice = context.select<DashboardCubit, Slice<List<ExpiringMembership>>>((c) => c.state.expiring);
    return SectionCard(
      title: 'تنتهي خلال 7 أيام',
      action: 'كل القريبة',
      onAction: () => context.go(DashboardLinks.expiring),
      child: SliceView(
        slice: slice,
        loading: const ListShimmer(count: 3),
        onRetry: context.read<DashboardCubit>().retryExpiring,
        isEmpty: (list) => list.isEmpty,
        empty: Text('لا اشتراكات تنتهي خلال 7 أيام.', style: UType.body(color: context.colors.inkMuted)),
        builder: (context, list) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final m in list) _Row(item: m)],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item});

  final ExpiringMembership item;

  @override
  Widget build(BuildContext context) {
    final m = item;
    void open() => context.go(Routes.child(Routes.memberships, m.id));
    final tile = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: open,
        hoverColor: Colors.transparent,
        borderRadius: AppRadius.smAll,
        child: MemberTile(
          name: m.playerName,
          plan: [m.planName, m.branchName].where((s) => s.isNotEmpty).join(' · '),
          status: m.statusLabel,
          tone: Labels.membershipStatus(m.status).tone,
          trailing: _when(m),
        ),
      ),
    );
    if (context.isMobile) return tile;
    return Row(
      children: [
        Expanded(child: tile),
        AppSpace.gap2,
        TextButton(onPressed: open, child: const Text('تجديد')),
      ],
    );
  }

  /// من `days_remaining` الجاهز: "اليوم" / "بعد يومين" / "بعد 3 أيام".
  static String _when(ExpiringMembership m) => switch (m.daysRemaining) {
    null => Formatters.date(m.endsOn),
    <= 0 => 'ينتهي اليوم',
    final n => 'بعد ${Formatters.days(n)}',
  };
}
