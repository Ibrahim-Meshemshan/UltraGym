import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../bloc/reception_devices_cubit.dart';
import '../widgets/device_setup_card.dart';
import '../widgets/devices_table.dart';

/// أجهزة الاستقبال (`ReceptionDevices.html`، للمالك، ميزة `offline_reception`): خطوات تجهيز جهاز جديد،
/// ثم الأجهزة المسجلة لفرع الشريط العلوي (أو كل الفروع بفلتر). الميزة خارج الباقة: القسم مخفي ورابطه
/// يعرض `PlanFeatureLocked` من الهيكل.
class ReceptionDevicesScreen extends StatelessWidget {
  const ReceptionDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final (ready, branchId) = context.select<BranchScopeCubit, (bool, int?)>(
      (c) => (!c.state.branches.isFirstLoad, c.state.branchId),
    );
    if (!ready) return const AppPage(children: [DeviceSetupCard(), TableShimmer(columns: 6)]);
    return BlocProvider(
      key: ValueKey(branchId),
      create: (_) => sl<ReceptionDevicesCubit>(param1: branchId)..load(),
      child: AppPage(
        children: [
          const DeviceSetupCard(),
          const DevicesTable(),
          Text(
            'الجهاز الذي لم يزامن منذ مدة طويلة قد يحمل عمليات دون اتصال لم تصل بعد.',
            style: UType.caption(color: context.colors.inkMuted),
          ),
        ],
      ),
    );
  }
}
