import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';

/// قسم ميزته غير مشمولة بباقة النادي (`SystemStates.html` · ميزة غير متاحة): يظهر حين يُفتح رابطه مباشرة،
/// لأن القائمة تخفيه أصلاً. للمالك زر "عرض الباقة الحالية".
class PlanFeatureLocked extends StatelessWidget {
  const PlanFeatureLocked({super.key, required this.owner});

  final bool owner;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: context.pagePadding,
      child: AppEmptyState(
        icon: Icons.workspace_premium_rounded,
        title: 'هذه الميزة ليست ضمن باقتك',
        message: 'الميزات تختلف حسب باقة النادي، ويمكن لفريق UltraGym إضافتها لناديك كاستثناء.',
        actionLabel: owner ? 'عرض الباقة الحالية' : null,
        onAction: owner ? () => context.go(Routes.billing) : null,
      ),
    ),
  );
}
