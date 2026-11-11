import 'package:flutter/widgets.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/features/billing/presentation/screens/billing_screen.dart';
import 'package:ultra_gym_admin/features/reception_devices/presentation/screens/reception_devices_screen.dart';

import '../../features/billing/fake_billing_repository.dart';
import '../../features/reception_devices/fake_reception_devices_repository.dart';

/// مستودعات أقسام الإدارة الأخيرة (أجهزة الاستقبال، اشتراك النادي والدعم والسجل) بالهارنس.
class ShellAdminFakes {
  final devices = FakeReceptionDevicesRepository();
  final billing = FakeBillingRepository();
  final support = FakeSupportRepository();
  final log = FakeActivityLogRepository();

  void register() {
    registerDevicesFakes(devices);
    registerBillingFakes(billing, support, log);
  }

  /// شاشة القسم الحقيقية، أو null لغير هذه الأقسام.
  static Widget? page(String route) => switch (route) {
    Routes.receptionDevices => const ReceptionDevicesScreen(),
    Routes.billing => const BillingScreen(),
    _ => null,
  };
}
